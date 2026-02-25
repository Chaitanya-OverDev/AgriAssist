from fastapi import FastAPI, Depends, HTTPException, status, Form, Response,BackgroundTasks
from sqlalchemy.orm import Session
from datetime import timedelta,date,datetime
import random
import os
from dotenv import load_dotenv
import re
import base64
import io
import wave
import requests
import time
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
import json


import tempfile
import edge_tts
from fastapi.responses import FileResponse
from pydantic import BaseModel

# Google GenAI Imports
from google import genai
from google.genai import types
from google.genai.types import HarmCategory, HarmBlockThreshold

# Local Imports
from db import models
from db.database import engine, get_db
from db.models import User, OTP, ChatSession, ChatMessage, get_ist_time, CommodityCache, WeatherCache
from api import schemas
from api.scraper import fetch_agmarknet_prices

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
        state: str = Form(None),
        district: str = Form(None),
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

    if state: user.state = state
    if district: user.district = district

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

# --- HELPER: SYSTEM INSTRUCTIONS ---
def build_system_instruction(user: User, db: Session):
    today = datetime.now().strftime("%d %B %Y")

    # ---------------- LOCATION & WEATHER ----------------
    if user.latitude and user.longitude:
        location_info = (
            f"Lat: {user.latitude}, Lon: {user.longitude} "
            f"(District: {user.district}, State: {user.state})"
        )

        # --- SILENTLY INJECT TODAY'S WEATHER IF CACHED ---
        three_hours_ago = datetime.utcnow() - timedelta(hours=3)

        cached_weather = db.query(WeatherCache).filter(
            WeatherCache.user_id == user.id,
            WeatherCache.fetched_at >= three_hours_ago
        ).first()

        if cached_weather:
            forecast = json.loads(cached_weather.forecast_data)
            today_weather = forecast[0]

            weather_context = (
                f"TODAY'S WEATHER: {today_weather['condition']}, "
                f"Max Temp: {today_weather['temp_max']}°C, "
                f"Min Temp: {today_weather['temp_min']}°C, "
                f"Rainfall Expected: {today_weather['rain_mm']}mm."
            )
        else:
            weather_context = (
                "Weather: Not cached right now. "
                "Use the weather tool if the user asks."
            )
    else:
        location_info = "Unknown Location. Ask the user to enable GPS."
        weather_context = "Weather: Cannot check without GPS."

    # ---------------- FARM DETAILS ----------------
    if user.has_farm == 'yes':
        farm_details = (
            f"Name: {user.full_name}\n"
            f"Water: {user.water_supply}\n"
            f"Type: {user.farm_type}\n"
            f"Location: {location_info}\n"
            f"{weather_context}"
        )
    else:
        farm_details = (
            f"Farmer details pending.\n"
            f"Location: {location_info}\n"
            f"{weather_context}"
        )

    # ---------------- FINAL SYSTEM PROMPT ----------------
    return f"""
You are **Kisan Mitra**, an expert, polite, and welcoming agricultural advisor.
Current Date: {today} (Do NOT mention the date unless asked).

FARMER PROFILE:
{farm_details}

SCOPE OF CAPABILITIES:
1. **General Farming Advice:** You are a fully qualified agronomist. You MUST answer general questions about farming, crop diseases (e.g., tomato blight, pests), soil preparation, and cultivation techniques using your own extensive knowledge.
2. **When to use Tools:** ONLY use the `get_weather_forecast` or `get_baazar_bhav` tools if the user explicitly asks for weather updates or current market prices. For everything else, answer directly without a tool.

CORE BEHAVIOR:
1. **Tone & Style:** Always ask politely, be highly respectful, and use a friendly spoken-style (Hinglish/Hindi/English).
2. **Formatting:** Do NOT remove formatting. You must use markdown formatting (like **bolding** and bullet points) to organize your response. The user is reading this in a chat interface, so it needs to look clean and structured.
3. **Conciseness:** Keep answers relatively short (3-4 sentences) so voice playback is fast and text is easy to read.
4. **Pesticides/Fertilizers:** If the user asks about a disease or pest, provide the Chemical Name + common Brand and Dosage (per 15L pump).

MARKET PRICE TOOL RULES:
Always extract the crop/commodity from the user's message before calling the Baazar Bhav tool.

CRITICAL CROP NAME TRANSLATIONS:
You MUST map the farmer's spoken Hindi/Marathi/English word to these EXACT official government names:
* Pyaaz / Kanda / Onion -> "Onion"
* Aloo / Batata / Potato -> "Potato"
* Tamatar / Tomato -> "Tomato"
* Gajar / Gaajar / Carrot -> "Carrot"
* Baingan / Vangi / Brinjal -> "Brinjal"
* Bhindi / Bhendi / Okra -> "Bhindi(Ladies Finger)"
* Patta Gobi / Kobi / Cabbage -> "Cabbage"
* Phool Gobi / Flower / Cauliflower -> "Cauliflower"
* Lehsun / Lasun / Garlic -> "Garlic"
* Adrak / Ale / Ginger -> "Ginger"
* Hari Mirch / Hirvi Mirchi -> "Green Chilli"
* Karela / Karle -> "Bitter Gourd"
* Lauki / Dudhi -> "Bottle Gourd"
* Kaddu / Lal Bhopla -> "Pumpkin"
* Palak / Spinach -> "Spinach"
* Kapas / Kapus / Cotton -> "Kapas"
* Gehun / Gahu / Wheat -> "Wheat"
* Soyabean -> "Soyabean"
* Chana / Harbara / Chickpeas -> "Bengal Gram(Gram)(Whole)"
* Toor / Tur / Arhar -> "Arhar (Tur/Red Gram)(Whole)"
* Sarson / Mohri / Mustard -> "Mustard"
* Dhan / Bhaat / Paddy -> "Paddy(Dhan)(Common)"
* Bajra / Bajri / Pearl Millet -> "Bajra(Pearl Millet/Cumbu)"
* Jowar / Sorghum -> "Jowar(Sorghum)"
"""
  
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
    if not session: raise HTTPException(status_code=404, detail="Session not found")
    
    # 2. Save User Message
    user_msg = ChatMessage(session_id=session.id, role="user", content=request.content)
    db.add(user_msg)
    db.commit()
    

    history_objs = db.query(ChatMessage).filter(ChatMessage.session_id == session.id).order_by(ChatMessage.created_at.asc()).all()
    
    chat_history = []
    for msg in history_objs:
        chat_history.append(types.Content(
            role=msg.role,
            parts=[types.Part.from_text(text=msg.content)]
        ))

    user = session.user
    system_instruction = build_system_instruction(user, db)
    
    generate_config = types.GenerateContentConfig(
        system_instruction=system_instruction,
        temperature=0.7,
        max_output_tokens=200,
        tools=[weather_tool, bhav_tool], 
        automatic_function_calling=types.AutomaticFunctionCallingConfig(disable=True) 
    )

    try:
        model = "gemini-2.5-flash" 
        response = client.models.generate_content(
            model=model,
            contents=chat_history,
            config=generate_config
        )

        ai_text = ""
        
        if response.function_calls:
            function_call = response.function_calls[0]
            args = function_call.args 
            
            if function_call.name == "get_weather_forecast":
                # We don't actually need args.lat/lon because we use the user's DB location
                if user.latitude and user.longitude:
                    forecast_json = get_cached_weather(user.id, user.latitude, user.longitude, db)
                    
                    if forecast_json:
                        # Convert JSON into a string for Gemini
                        weather_result = "5-Day Forecast:\n"
                        for day in forecast_json:
                            weather_result += f"- {day['date']}: {day['condition']}, High {day['temp_max']}°C, Low {day['temp_min']}°C, Rain: {day['rain_mm']}mm\n"
                    else:
                        weather_result = "Failed to fetch weather data."
                else:
                    weather_result = "Cannot check weather: GPS coordinates are missing from profile."
                
                print(f"--- SENDING WEATHER TO GEMINI: {weather_result} ---")
                # ... append to history and generate response as usual ...
                
                chat_history.append(response.candidates[0].content)

                chat_history.append(types.Content(
                    role="user",
                    parts=[types.Part.from_function_response(
                        name="get_weather_forecast",
                        response={"result": weather_result}
                    )]
                ))

                final_response = client.models.generate_content(
                    model=model,
                    contents=chat_history,
                    config=generate_config
                )
                ai_text = final_response.text

            elif function_call.name == "get_baazar_bhav": 
                state = args.get("state") or user.state
                district = args.get("district") or user.district # Optional now
                commodity = args.get("commodity")
                
                if state and commodity:
                    # PASS THE DB SESSION HERE
                    bhav_result = get_baazar_bhav(state=state, commodity=commodity, district=district, db=db)
                else:
                    bhav_result = "Cannot check prices. Please ensure GPS location is saved and you mentioned a specific crop."

                print(f"--- SENDING THIS DB RESULT TO GEMINI: {bhav_result} ---")

                chat_history.append(response.candidates[0].content)

                chat_history.append(types.Content(
                    role="user",
                    parts=[types.Part.from_function_response(
                        name="get_baazar_bhav",
                        response={"result": bhav_result}
                    )]
                ))

                final_response = client.models.generate_content(
                    model=model,
                    contents=chat_history,
                    config=generate_config
                )
                ai_text = final_response.text

        else:
            ai_text = response.text

    except Exception as e:
        print(f"Gemini API Error: {e}")
        ai_text = "Sorry, I am having trouble connecting to the network right now."

    if not ai_text: 
        ai_text = "I received the data but couldn't generate a response."

    # 6. Save AI Response
    ai_msg = ChatMessage(session_id=session.id, role="model", content=ai_text)
    db.add(ai_msg)
    db.commit()

    # --- TITLE LOGIC ---
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

# --- 11. Delete Session along with messages ---
@app.delete("/chat/sessions/{session_id}", status_code=status.HTTP_200_OK)
def delete_chat_session(
        session_id: int,
        user_id: int,
        db: Session = Depends(get_db)
):
    # 1. Query the session, ensuring it belongs to the requesting user_id
    session = db.query(ChatSession).filter(
        ChatSession.id == session_id,
        ChatSession.user_id == user_id
    ).first()

    # 2. If not found (or belongs to another user), raise 404
    if not session:
        raise HTTPException(
            status_code=404,
            detail="Session not found or you do not have permission to delete it"
        )

    # 3. Delete and Commit
    try:
        db.delete(session)
        db.commit()
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"An error occurred: {str(e)}")

    return {"message": "Chat session and history deleted successfully"}


# ---Helper: Cleaning for text ---
def clean_text_for_tts(text: str) -> str:
    if not text: return ""

    # 1. Replace newlines with periods so the TTS pauses instead of choking
    text = text.replace('\n', '. ')

    # 2. Remove markdown symbols (*, #, _, ~, `)
    text = re.sub(r'[\*#_`~]', '', text)

    # 3. Remove links [text](url) -> text
    text = re.sub(r'\[([^\]]+)\]\([^\)]+\)', r'\1', text)

    # 4. Collapse multiple spaces/dots
    text = re.sub(r'\.+', '.', text)
    text = re.sub(r'\s+', ' ', text)

    return text.strip()

# --- 12. GEMINI TTS Endpoint ---
@app.get("/chat/message/{message_id}/tts")
def generate_speech(
        message_id: int,
        user_id: int,
        db: Session = Depends(get_db)
):
    # Fetch Message
    message = db.query(ChatMessage).join(ChatSession).filter(
        ChatMessage.id == message_id,
        ChatSession.user_id == user_id
    ).first()

    if not message:
        raise HTTPException(status_code=404, detail="Message not found")

    # Clean Text
    clean_text = clean_text_for_tts(message.content)
    # print(f"DEBUG: TTS Input Text: {clean_text}") # Check your terminal

    if not clean_text or len(clean_text) < 2:
        raise HTTPException(status_code=400, detail="Text is empty")

    try:
        response = client.models.generate_content(
            model="gemini-2.5-flash-preview-tts",
            contents=clean_text,
            config=types.GenerateContentConfig(
                response_modalities=["AUDIO"],
                speech_config=types.SpeechConfig(
                    voice_config=types.VoiceConfig(
                        prebuilt_voice_config=types.PrebuiltVoiceConfig(
                            voice_name="Kore"
                        )
                    )
                ),
                safety_settings=[
                    types.SafetySetting(
                        category=HarmCategory.HARM_CATEGORY_HATE_SPEECH,
                        threshold=HarmBlockThreshold.BLOCK_NONE
                    ),
                    types.SafetySetting(
                        category=HarmCategory.HARM_CATEGORY_HARASSMENT,
                        threshold=HarmBlockThreshold.BLOCK_NONE
                    ),
                    types.SafetySetting(
                        category=HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT,
                        threshold=HarmBlockThreshold.BLOCK_NONE
                    ),
                    types.SafetySetting(
                        category=HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT,
                        threshold=HarmBlockThreshold.BLOCK_NONE
                    ),
                ]
            )
        )

        if not response.candidates:
            raise HTTPException(status_code=500, detail="No candidates returned")

        if not response.candidates[0].content:
            finish_reason = response.candidates[0].finish_reason
            print(f"DEBUG: Still Blocked! Reason: {finish_reason}")
            raise HTTPException(status_code=400, detail=f"TTS Blocked. Reason: {finish_reason}")

        audio_content = response.candidates[0].content.parts[0].inline_data.data

        if isinstance(audio_content, str):
            audio_bytes = base64.b64decode(audio_content)
        else:
            audio_bytes = audio_content

        # Convert to WAV
        wav_buffer = io.BytesIO()
        with wave.open(wav_buffer, 'wb') as wav_file:
            wav_file.setnchannels(1)
            wav_file.setsampwidth(2)
            wav_file.setframerate(24000)
            wav_file.writeframes(audio_bytes)

        final_wav_data = wav_buffer.getvalue()

        return Response(content=final_wav_data, media_type="audio/wav")

    except Exception as e:
        print(f"TTS Exception: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# --- Helper to get State and district from Latitude and Longitude ---
def get_location_details(lat: float, lon: float):
    url = f"https://nominatim.openstreetmap.org/reverse?format=json&lat={lat}&lon={lon}&zoom=10"
    
    user_agent = os.getenv("NOMINATIM_USER_AGENT")
    
    #Fallback if forgot to add in env
    if not user_agent:
        user_agent = "KisanMitraApp/1.0 (fallback_email@example.com)"

    headers = {
        'User-Agent': user_agent 
    }
    
    try:
        response = requests.get(url, headers=headers, timeout=10)
        if response.status_code == 200:
            data = response.json()
            address = data.get('address', {})
            
            # Extract district and state
            district = address.get('state_district', address.get('county', ''))
            state = address.get('state', '')
            
            district = district.replace(' District', '').replace(' district', '').strip()
            
            return {"district": district, "state": state}
    except Exception as e:
        print(f"Geocoding error: {e}")
        
    return {"district": None, "state": None}

# --- 13. Post User location (latitude and longitude) ---
@app.post("/users/{user_id}/location")
def update_user_location(
    user_id: int, 
    location_data: schemas.LocationUpdateSchema, 
    db: Session = Depends(get_db)
):

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    loc_details = get_location_details(location_data.latitude, location_data.longitude)
    
    user.latitude = location_data.latitude
    user.longitude = location_data.longitude
    
    # Only overwrite state/district if the geocoding successfully found them
    if loc_details["state"]:
        user.state = loc_details["state"]
    if loc_details["district"]:
        user.district = loc_details["district"]
        
    try:
        db.commit()
        db.refresh(user)
        return {
            "message": "Location updated successfully", 
            "latitude": user.latitude,
            "longitude": user.longitude,
            "district": user.district,
            "state": user.state
        }
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Database update failed")

# Edge TTS
# Define the request body structure
class TTSRequest(BaseModel):
    text: str

# Define the exact voice ID for Manohar
VOICE = "mr-IN-ManoharNeural"

def remove_file(path: str):
    """Cleanup function to remove the temp file after sending."""
    try:
        os.unlink(path)
    except Exception as e:
        print(f"Error removing temporary file: {e}")

# ---14. Edge TTS- Endpoint
@app.post("/generate-audio")
async def generate_audio(request: TTSRequest, background_tasks: BackgroundTasks):
    """
    Takes Marathi text and returns an MP3 audio file using Edge TTS.
    """
    # Create a temporary file to hold the MP3 data
    temp_file = tempfile.NamedTemporaryFile(delete=False, suffix=".mp3")
    temp_file_path = temp_file.name
    temp_file.close()

    # Generate the audio using edge-tts
    communicate = edge_tts.Communicate(request.text, VOICE)
    await communicate.save(temp_file_path)

    # Ensure the file is deleted from the server after the response is sent
    background_tasks.add_task(remove_file, temp_file_path)

    # Return the audio file to the client
    return FileResponse(
        temp_file_path, 
        media_type="audio/mpeg", 
        filename="response.mp3"
    )

# --- Helper Baazar Bhav ---
def get_baazar_bhav(state: str, commodity: str, db: Session, district: str = None):
    """Gemini tool: Reads cached prices strictly within the last 6 hours."""
    
    six_hours_ago = datetime.utcnow() - timedelta(hours=6)
    
    # Check if we have FRESH data for this state
    state_exists = db.query(CommodityCache).filter(
        CommodityCache.state == state.title(),
        CommodityCache.scraped_at >= six_hours_ago
    ).first()
    
    if not state_exists:
        return f"Market data for {state} is not available or is older than 6 hours. Politely ask the user to open the Market tab in their app to refresh the live data."
        
    # Search for the specific crop within the fresh data
    crop_data = db.query(CommodityCache).filter(
        CommodityCache.state == state.title(),
        CommodityCache.commodity.ilike(f"%{commodity}%"),
        CommodityCache.scraped_at >= six_hours_ago
    ).first()
    
    if crop_data:
        return f"""
DATA FOUND FOR {commodity.upper()} IN {state.upper()}:
- MSP: ₹{crop_data.msp}
- Latest Price: ₹{crop_data.price_latest}
- Mid Price: ₹{crop_data.price_mid}
- Old Price: ₹{crop_data.price_old}

INSTRUCTIONS FOR AI:
1. Politely tell the farmer the Latest Price and the MSP.
2. Compare the Latest Price to the Mid/Old prices to tell them if the market trend is going UP, DOWN, or is STABLE.
3. Use bold formatting (**) for key numbers so it looks good in the chat UI.
4. Keep the explanation concise (2-3 sentences max).
"""
    else:
        return f"Politely inform the user that market data is not available for {commodity} in {state} today."

# --- Baazar Bhav Tool for gemini ---
bhav_tool = types.Tool(
    function_declarations=[
        types.FunctionDeclaration(
            name="get_baazar_bhav",
            description="Get the current agricultural market price (Baazar Bhav/Mandi rates) for a specific crop/commodity from the local database.",
            parameters=types.Schema(
                type=types.Type.OBJECT,
                properties={
                    "state": types.Schema(type=types.Type.STRING, description="The Indian state"),
                    "district": types.Schema(type=types.Type.STRING, description="The Indian district (optional)"),
                    "commodity": types.Schema(type=types.Type.STRING, description="The name of the crop or commodity (e.g., Cotton, Wheat, Onion)"),
                },
                required=["state", "commodity"] # District is no longer strictly required
            )
        )
    ]
)

def fetch_gov_price_data(state: str, district: str, commodity: str):
    """Fetches raw JSON price data from data.gov.in for database storage."""
    api_key = os.getenv("DATA_GOV_API_KEY")
    resource_id = "9ef84268-d588-465a-a308-a864a43d0070"
    url = f"https://api.data.gov.in/resource/{resource_id}"
    
    params = {
        "api-key": api_key,
        "format": "json",
        "limit": 5,
        "filters[state]": state.title(),
        "filters[district]": district.title(),
        "filters[commodity]": commodity.title()
    }
    
    try:
        response = requests.get(url, params=params, timeout=15)
        if response.status_code == 200:
            return response.json().get("records", [])
    except Exception as e:
        print(f"Gov API Error: {e}")
    return []

def get_market_data_workflow(state: str, district: str, db: Session):
    """Called when the app starts. Scrapes and caches prices for 6 hours."""
    
    # 1. Check DB for cached data within the last 6 HOURS
    six_hours_ago = datetime.utcnow() - timedelta(hours=6)
    
    query = db.query(CommodityCache).filter(
        CommodityCache.state == state.title(),
        CommodityCache.scraped_at >= six_hours_ago
    )
    if district:
        query = query.filter(CommodityCache.district == district.title())
    else:
        query = query.filter(CommodityCache.district == None)
        
    cached_records = query.all()
    
    # 2. If we have fresh data, just return it directly to the Flutter app
    if cached_records:
        print(f"--- Returning {len(cached_records)} cached prices (under 6 hours old) ---")
        return [
            {
                "commodity": r.commodity, 
                "commodity_group": r.commodity_group,
                "msp": r.msp,
                "price_latest": r.price_latest,
                "price_mid": r.price_mid,
                "price_old": r.price_old
            } for r in cached_records
        ]
        
    # 3. If cache is empty or older than 6 hours, wipe old data and scrape new
    print(f"--- Cache expired. Scraping Agmarknet for {state}... ---")
    db.query(CommodityCache).filter(CommodityCache.state == state.title()).delete()
    db.commit()
    
    scraped_data = fetch_agmarknet_prices(state, district)
    
    # 4. Save the new prices to the database
    for item in scraped_data:
        new_cache = CommodityCache(
            state=state.title(),
            district=district.title() if district else None,
            commodity=item["commodity"],
            commodity_group=item.get("commodity_group"),
            msp=item.get("msp"),
            price_latest=item.get("price_latest"),
            price_mid=item.get("price_mid"),
            price_old=item.get("price_old")
        )
        db.add(new_cache)
    db.commit()

    return scraped_data

# --- 15. Get User's District Bhavs ---
@app.get("/market/my-district/{user_id}")
def get_user_district_bhavs(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user or not user.state or not user.district:
        raise HTTPException(status_code=400, detail="User location incomplete.")
        
    results = get_market_data_workflow(user.state, user.district, db)
    return {"location": f"{user.district}, {user.state}", "data": results}

# --- 16. Get User's State Bhavs (All Districts) ---
@app.get("/market/my-state/{user_id}")
def get_user_state_bhavs(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user or not user.state:
        raise HTTPException(status_code=400, detail="User state incomplete.")
        
    results = get_market_data_workflow(user.state, None, db) 
    return {"location": user.state, "data": results}

# --- 17. Search purely by State ---
@app.get("/market/search/state")
def search_state_bhavs(state: str, db: Session = Depends(get_db)):
    results = get_market_data_workflow(state, None, db)
    return {"location": state, "data": results}

# --- 18. Search by State AND District ---
@app.get("/market/search/district")
def search_district_bhavs(state: str, district: str, db: Session = Depends(get_db)):
    results = get_market_data_workflow(state, district, db)
    return {"location": f"{district}, {state}", "data": results}

   
# ---Helper Weather Tool ---
weather_tool = types.Tool(
    function_declarations=[
        types.FunctionDeclaration(
            name="get_weather_forecast",
            description="Get the 5-day weather forecast using latitude and longitude coordinates.",
            parameters=types.Schema(
                type=types.Type.OBJECT,
                properties={
                    "lat": types.Schema(type=types.Type.NUMBER, description="Latitude of the location"),
                    "lon": types.Schema(type=types.Type.NUMBER, description="Longitude of the location"),
                },
                required=["lat", "lon"]
            )
        )
    ]
)

# --- Weather Forecast 5 days openweather ---
def get_weather_forecast(lat: float, lon: float):
    api_key = os.getenv("OPENWEATHERMAP_API_KEY")
    if not api_key:
        return "Error: Server API Key missing."
        
    url = f"https://api.openweathermap.org/data/2.5/forecast?lat={lat}&lon={lon}&appid={api_key}&units=metric"
    
    try:
        response = requests.get(url)
        data = response.json()
        
        if response.status_code == 200:
            daily_forecast = {}
            
            # Group the 3-hour chunks into daily highs/lows
            for item in data['list']:
                date_str = item['dt_txt'].split(' ')[0] 
                
                if date_str not in daily_forecast:
                    daily_forecast[date_str] = {
                        'temp_max': item['main']['temp_max'],
                        'temp_min': item['main']['temp_min'],
                        'desc': item['weather'][0]['description']
                    }
                else:
                    if item['main']['temp_max'] > daily_forecast[date_str]['temp_max']:
                        daily_forecast[date_str]['temp_max'] = item['main']['temp_max']
                    if item['main']['temp_min'] < daily_forecast[date_str]['temp_min']:
                        daily_forecast[date_str]['temp_min'] = item['main']['temp_min']
            
            # Format the data into a clean, readable string for Gemini
            result_str = "5-Day Weather Forecast:\n"
            for date, info in list(daily_forecast.items())[:5]:
                # Convert YYYY-MM-DD to a more readable format if desired
                result_str += f"- {date}: {info['desc'].title()}, High: {info['temp_max']}°C, Low: {info['temp_min']}°C.\n"
                
            return result_str
        else:
            return f"Weather data unavailable: {data.get('message', 'Unknown error')}"
    except Exception as e:
        return f"Connection error: {str(e)}"
    

def get_cached_weather(user_id: int, lat: float, lon: float, db: Session):
    """Fetches weather from OWM, processes rain/conditions, and caches it for 3 hours."""
    
    # 1. Check 3-hour cache
    three_hours_ago = datetime.utcnow() - timedelta(hours=3)
    cached_weather = db.query(WeatherCache).filter(
        WeatherCache.user_id == user_id,
        WeatherCache.fetched_at >= three_hours_ago
    ).first()

    if cached_weather:
        print("--- Loaded Weather from 3-Hour Database Cache ---")
        return json.loads(cached_weather.forecast_data)

    # 2. Fetch new data from OpenWeatherMap
    print("--- Cache expired. Fetching fresh Weather from OpenWeatherMap ---")
    api_key = os.getenv("OPENWEATHERMAP_API_KEY")
    url = f"https://api.openweathermap.org/data/2.5/forecast?lat={lat}&lon={lon}&appid={api_key}&units=metric"
    
    try:
        response = requests.get(url, timeout=10)
        if response.status_code != 200:
            return None
            
        data = response.json()
        daily_forecast = {}
        
        # Group 3-hour chunks into Daily Summaries
        for item in data['list']:
            date_str = item['dt_txt'].split(' ')[0]
            # Safely extract rain volume in mm (OWM uses 'rain': {'3h': 0.5})
            rain_mm = item.get('rain', {}).get('3h', 0.0)
            condition = item['weather'][0]['main'] # e.g., Rain, Clouds, Clear

            if date_str not in daily_forecast:
                daily_forecast[date_str] = {
                    'temp_max': item['main']['temp_max'],
                    'temp_min': item['main']['temp_min'],
                    'rain_mm': rain_mm,
                    'conditions': [condition]
                }
            else:
                daily_forecast[date_str]['temp_max'] = max(daily_forecast[date_str]['temp_max'], item['main']['temp_max'])
                daily_forecast[date_str]['temp_min'] = min(daily_forecast[date_str]['temp_min'], item['main']['temp_min'])
                daily_forecast[date_str]['rain_mm'] += rain_mm
                daily_forecast[date_str]['conditions'].append(condition)

        # 3. Format cleanly for Flutter UI and Gemini
        final_forecast = []
        for date_str, info in list(daily_forecast.items())[:5]:
            # Determine main condition for the day
            conds = info['conditions']
            if 'Rain' in conds or 'Thunderstorm' in conds or 'Drizzle' in conds:
                main_cond = 'Rainy'
            elif 'Clear' in conds:
                main_cond = 'Sunny'
            else:
                main_cond = 'Cloudy'

            final_forecast.append({
                "date": date_str,
                "temp_max": round(info['temp_max'], 1),
                "temp_min": round(info['temp_min'], 1),
                "rain_mm": round(info['rain_mm'], 1),
                "condition": main_cond
            })

        # 4. Save to Database Cache
        db.query(WeatherCache).filter(WeatherCache.user_id == user_id).delete()
        new_cache = WeatherCache(
            user_id=user_id,
            forecast_data=json.dumps(final_forecast)
        )
        db.add(new_cache)
        db.commit()

        return final_forecast

    except Exception as e:
        print(f"Weather Fetch Error: {e}")
        return None
    
# --- 19. Get User's Weather ---
@app.get("/weather/my-forecast/{user_id}")
def get_user_weather_page(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user or not user.latitude or not user.longitude:
        raise HTTPException(status_code=400, detail="User GPS location not found.")
        
    weather_data = get_cached_weather(user.id, user.latitude, user.longitude, db)
    if not weather_data:
        raise HTTPException(status_code=500, detail="Failed to fetch weather data.")
        
    return {"location": f"{user.district}, {user.state}", "forecast": weather_data}