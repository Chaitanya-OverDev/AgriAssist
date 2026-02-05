import os
from fastapi import FastAPI, Depends, HTTPException, status, Form
from sqlalchemy.orm import Session
from datetime import timedelta
import random
from dotenv import load_dotenv 
from pydantic import BaseModel 
from google import genai 
from google.genai import types

# Corrected Imports
from db import models
from db.database import engine, get_db
from db.models import User, OTP, get_ist_time
from api import schemas 

# --- CONFIGURATION: Load API Key & Initialize Gemini ---
load_dotenv() # Load variables from .env file
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

if not GEMINI_API_KEY:
    print("WARNING: GEMINI_API_KEY is missing in .env file")

# Initialize Gemini Client
client = genai.Client(api_key=GEMINI_API_KEY)

# Create DB Tables
models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="Farmer Chatbot API")

# --- Request Model for Chat (Defined here for simplicity) ---
class ChatRequest(BaseModel):
    message: str

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

# --- 7. NEW: Chat with Gemini Endpoint ---
@app.post("/chat/send")
async def chat_with_gemini(request: ChatRequest):
    """
    Receives a message string, sends it to Gemini 3 Flash Preview, 
    and returns the AI response.
    """
    if not GEMINI_API_KEY:
        raise HTTPException(status_code=500, detail="Gemini API Key not configured on server.")

    try:
        response = client.models.generate_content(
            model="gemini-3-flash-preview",
            contents=request.message,
            config=types.GenerateContentConfig(
                temperature=0.7, 
            )
        )
        return {"response": response.text}

    except Exception as e:
        print(f"Error calling Gemini: {e}")
        # Return a generic error to client, log specific error to console
        raise HTTPException(status_code=500, detail=f"AI Service Error: {str(e)}")