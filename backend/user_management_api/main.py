from fastapi import FastAPI, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import timedelta
import random
import pytz

# Import from our other files
import models
import schemas
from database import engine, get_db
from models import User, OTP, get_ist_time

# Initialize Database Tables
models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="User Management API")

# --- 1. Send OTP Endpoint ---
@app.post("/auth/send-otp")
def send_otp(request: schemas.PhoneSchema, db: Session = Depends(get_db)):
    phone = request.phone_number
    
    # This ensures the user cannot use a previous OTP if they requested a new one.
    db.query(OTP).filter(OTP.phone_number == phone).delete()
    db.commit() 
    # ------------------------------------
    
    # Generate 6-digit OTP
    otp_code = f"{random.randint(100000, 999999)}"
    
    # Calculate Expiration (IST Time + 5 mins)
    expiration_time = get_ist_time() + timedelta(minutes=5)
    
    # Save to DB
    new_otp = OTP(
        phone_number=phone,
        otp_code=otp_code,
        expires_at=expiration_time,
        is_used=False
    )
    db.add(new_otp)
    db.commit()
    
    return {"message": "OTP sent successfully", "otp": otp_code}


# --- 2. Verify OTP Endpoint ---
@app.post("/auth/verify-otp")
def verify_otp(request: schemas.VerifyOTPSchema, db: Session = Depends(get_db)):
    # Fetch the latest valid OTP for this phone
    otp_record = db.query(OTP).filter(
        OTP.phone_number == request.phone_number,
        OTP.otp_code == request.otp,
        OTP.is_used == False
    ).first()
    
    # Validation: Check existence and expiration
    if not otp_record:
        raise HTTPException(status_code=400, detail="Invalid OTP")
    
    current_time = get_ist_time()
    # Note: Ensure both times are timezone-aware for comparison
    if otp_record.expires_at < current_time:
        raise HTTPException(status_code=400, detail="OTP has expired")
        
    # Mark OTP as used
    otp_record.is_used = True
    db.commit()
    
    # Check if user exists
    user = db.query(User).filter(User.phone_number == request.phone_number).first()
    
    if not user:
        # Create new user
        new_user = User(phone_number=request.phone_number)
        db.add(new_user)
        db.commit()
        db.refresh(new_user)
        return {"message": "User created and logged in", "user_id": new_user.id, "status": "New User"}
    
    return {"message": "Login successful", "user_id": user.id, "status": "Existing User"}

# --- 3. Read All Users ---
@app.get("/users", response_model=list[schemas.UserResponse])
def read_all_users(db: Session = Depends(get_db)):
    users = db.query(User).all()
    return users

# --- 4. Update User ---
# needs verificaiton whether user logged in or not before
@app.put("/users/update/{user_id}")
def update_user(user_id: int, request: schemas.UpdateProfileSchema, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    if request.full_name:
        user.full_name = request.full_name
    
    if request.profile_photo:
        user.profile_photo = request.profile_photo
        
    db.commit()
    return {"message": "Profile updated successfully"}

# --- 5. Delete User ---
# now deletes which is requested but in reality only logged in user should be able to delete their own account
@app.delete("/users/{user_id}")
def delete_user(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    db.delete(user)
    db.commit()
    return {"message": "User deleted successfully"}


# --- Read Single User ---
@app.get("/users/{user_id}", response_model=schemas.UserResponse)
def read_single_user(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user