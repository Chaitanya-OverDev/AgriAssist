from sqlalchemy import Column, Integer, String, DateTime, Boolean
from sqlalchemy.sql import func
import datetime
import pytz

# --- Corrected Import ---
from db.database import Base

# Helper to calculate IST time (UTC+5:30)
def get_ist_time():
    return datetime.datetime.now(pytz.timezone('Asia/Kolkata'))

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    phone_number = Column(String, unique=True, index=True, nullable=False)
    full_name = Column(String, default="GuestUser")
    
    profil_pic_url = Column(String, default="default_avatar.png") 
    is_verified = Column(Boolean, default=False)                  
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now()) 

class OTP(Base):
    __tablename__ = "otp_codes"

    id = Column(Integer, primary_key=True, index=True)
    phone_number = Column(String, index=True, nullable=False)
    otp_code = Column(String, nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)
    is_used = Column(Boolean, default=False)