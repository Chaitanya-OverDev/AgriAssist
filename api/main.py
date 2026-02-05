from fastapi import FastAPI, Depends, HTTPException, status, Form
from sqlalchemy.orm import Session
from datetime import timedelta
import random
import os
from dotenv import load_dotenv
import re

# Google GenAI Imports
from google import genai
from google.genai import types

# Local Imports
from db import models
from db.database import engine, get_db
from db.models import User, OTP, ChatSession, ChatMessage, get_ist_time
from api import schemas

# Create DB Tables
models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="Farmer Chatbot API")

load_dotenv()
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
client = genai.Client(api_key=GEMINI_API_KEY)

# --- 1. Send OTP Endpoint (No Code in Response) ---
@app.post("/auth/send-otp")
def send_otp(request: schemas.PhoneSchema, db: Session = Depends(get_db)):
    phone = request.phone_number

    # Delete old OTPs
    db.query(OTP).filter(OTP.phone_number == phone).delete()
    db.commit()

    # Generate OTP (Stored in DB but NOT returned in response)
    otp_code = f"{random.randint(100000, 999999)}"
    expiration_time = get_ist_time() + timedelta(minutes=5)

    new_otp = OTP(
        phone_number=phone,
        otp_code=otp_code,
        expires_at=expiration_time,
        is_used=False
    )
    db.add(new_otp)
    db.commit()

    return {"message": "OTP sent successfully"}


# --- 2. Verify OTP Endpoint (BYPASS MODE) ---
@app.post("/auth/verify-otp")
def verify_otp(request: schemas.VerifyOTPSchema, db: Session = Depends(get_db)):
    otp = request.otp.strip()

    # --- VALIDATION RULES ---
    if not otp:
        raise HTTPException(status_code=400, detail="OTP cannot be blank")

    if not otp.isdigit():
        raise HTTPException(status_code=400, detail="OTP must contain only numbers")

    if len(otp) != 6:
        raise HTTPException(status_code=400, detail="OTP must be 6 digits")

    if otp == "000000":
        raise HTTPException(status_code=400, detail="Invalid OTP")

    # bypass below

    # Check if user exists
    user = db.query(User).filter(User.phone_number == request.phone_number).first()

    if not user:
        # Create new user -> Set verified to TRUE
        new_user = User(
            phone_number=request.phone_number,
            is_verified=True
        )
        db.add(new_user)
        db.commit()
        db.refresh(new_user)
        return {"message": "User created and logged in", "user_id": new_user.id, "status": "New User"}

    return {"message": "Login successful", "user_id": user.id, "status": "Existing User"}


# --- 3. Update User Profile (Form Data - No Image) ---
@app.put("/users/update/{user_id}")
def update_user(
        user_id: int,
        full_name: str = Form(None),
        has_farm: str = Form(None),      # yes/no
        water_supply: str = Form(None),  # rain, well, river, channel
        farm_type: str = Form(None),     # Koradvahu, bagayati
        db: Session = Depends(get_db)
):
    user = db.query(User).filter(User.id == user_id).first()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Update Info
    if full_name:
        user.full_name = full_name

    if has_farm:
        user.has_farm = has_farm

    if water_supply:
        user.water_supply = water_supply

    if farm_type:
        user.farm_type = farm_type

    db.commit()
    return {"message": "Profile updated successfully"}


# --- 4. Read Single User ---
@app.get("/users/{user_id}", response_model=schemas.UserResponse)
def read_single_user(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

# --- 5. Read All Users ---
@app.get("/users", response_model=list[schemas.UserResponse])
def read_all_users(db: Session = Depends(get_db)):
    users = db.query(User).all()
    return users

# --- 6. Delete User ---
@app.delete("/users/{user_id}")
def delete_user(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    db.delete(user)
    db.commit()
    return {"message": "User deleted successfully"}


# --- HELPER: SYSTEM INSTRUCTIONS  ---
def build_system_instruction(user: User):
    """
    Creates a tailored persona for the AI based on the specific farmer's profile.
    """
    profile_context = f"""
    FARMER PROFILE:
    - Name: {user.full_name}
    - Has Farm: {user.has_farm}
    - Water Supply: {user.water_supply}
    - Farm Type: {user.farm_type}
    """

    return f"""
    You are an expert Indian Agricultural AI Advisor (Kisan Mitra). 
    
    YOUR GOAL: Provide specific, actionable, and region-aware farming advice.
    
    CONTEXT:
    {profile_context if user.has_farm == 'yes' else "User is interested in farming but details are incomplete."}
    
    GUIDELINES:
    1. STRICTLY AVOID GENERIC DATES. If asked about sowing/harvesting, DO NOT say "June to July". 
       Instead, ask for the user's District/State if you don't know it, then give specific windows like "First 2 weeks of June for [Region Name]".
    2. USE FARMER'S CONTEXT: If they have 'well' water, suggest irrigation methods suitable for wells.
    3. LANGUAGE: Answer in the same language the user asks (mostly Hinglish or English).
    4. TONE: Professional, respectful, yet simple (like an experienced agronomist).
    5. FORMATTING: Use bullet points for steps.
    """

# --- 7. Create New Chat Session ---
@app.post("/chat/sessions", response_model=schemas.SessionResponse)
def create_chat_session(
        request: schemas.CreateSessionSchema,
        user_id: int,
        db: Session = Depends(get_db)
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    new_session = ChatSession(
        user_id=user.id,
        title=request.title
    )
    db.add(new_session)
    db.commit()
    db.refresh(new_session)
    return new_session

# --- 8. Get All Sessions for User ---
@app.get("/chat/sessions/{user_id}", response_model=list[schemas.SessionResponse])
def get_user_sessions(user_id: int, db: Session = Depends(get_db)):
    sessions = db.query(ChatSession).filter(ChatSession.user_id == user_id).order_by(ChatSession.created_at.desc()).all()
    return sessions


# --- 9. Send Message & Get Response ---
@app.post("/chat/{session_id}/message", response_model=schemas.MessageResponse)
def chat_with_gemini(
        session_id: int,
        request: schemas.MessageCreateSchema,
        user_id: int,
        db: Session = Depends(get_db)
):
    # 1. Validate Session
    session = db.query(ChatSession).filter(ChatSession.id == session_id, ChatSession.user_id == user_id).first()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found or access denied")

    # 2. Save User Message
    user_msg = ChatMessage(session_id=session.id, role="user", content=request.content)
    db.add(user_msg)
    db.commit()

    # 3. Retrieve History
    history_objs = db.query(ChatMessage) \
        .filter(ChatMessage.session_id == session.id) \
        .order_by(ChatMessage.created_at.asc()) \
        .all()

    chat_history = []
    for msg in history_objs:
        chat_history.append(types.Content(
            role=msg.role,
            parts=[types.Part.from_text(text=msg.content)]
        ))

    # 4. Prepare Context
    user = session.user
    system_instruction = build_system_instruction(user)

    # 5. Call Gemini API (Main Chat)
    try:
        generate_config = types.GenerateContentConfig(
            system_instruction=system_instruction,
            temperature=0.7,
            thinking_config={
                "thinking_level": "LOW"
            }
        )

        response = client.models.generate_content(
            model="gemini-3-flash-preview",
            contents=chat_history,
            config=generate_config
        )

        ai_text = response.text

    except Exception as e:
        print(f"Gemini API Error: {e}")
        raise HTTPException(status_code=500, detail="AI Service Unavailable")

    # 6. Save AI Response
    ai_msg = ChatMessage(session_id=session.id, role="model", content=ai_text)
    db.add(ai_msg)
    db.commit()
    db.refresh(ai_msg)



    current_title = session.title
    defaults = ["New Consultation", "New Chat", "string"]

    if not current_title or current_title.strip() == "" or current_title in defaults:
        try:

            title_prompt = f"""
            Summarize this into a 3-5 word title. 
            RULES:
            1. Do NOT use numbering (e.g., no "1.", no "-").
            2. Do NOT use quotes.
            3. Just output the raw words.
            
            Query: {request.content}
            """

            title_response = client.models.generate_content(
                model="gemini-2.5-flash-lite",
                contents=title_prompt,
                config=types.GenerateContentConfig(max_output_tokens=20)
            )

            new_title = ""
            if title_response.text:
                new_title = title_response.text.strip()
            elif title_response.candidates and title_response.candidates[0].content.parts:
                new_title = title_response.candidates[0].content.parts[0].text.strip()

            if new_title:
                # REGEX CLEANUP: Removes "1.", "1)", "- ", "* " from the start
                new_title = re.sub(r'^[\d\.\-\*\s]+', '', new_title)

                # Remove quotes
                new_title = new_title.replace('"', '').replace("'", "").strip()

                session.title = new_title
                db.commit()
                print(f"Auto-updated session title to: {new_title}")

        except Exception as title_error:
            print(f"Title generation failed ({title_error}). Keeping default title.")

    return ai_msg

# --- 10. Get Message History ---
@app.get("/chat/{session_id}/history", response_model=list[schemas.MessageResponse])
def get_chat_history(session_id: int, user_id: int, db: Session = Depends(get_db)):
    session = db.query(ChatSession).filter(ChatSession.id == session_id, ChatSession.user_id == user_id).first()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")

    messages = db.query(ChatMessage).filter(ChatMessage.session_id == session_id).order_by(ChatMessage.created_at.asc()).all()
    return messages