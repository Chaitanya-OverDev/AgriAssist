from sqlalchemy import Column, Integer, String, DateTime, Boolean
from sqlalchemy.sql import func
import datetime
import pytz
from db.database import Base

def get_ist_time():
    return datetime.datetime.now(pytz.timezone('Asia/Kolkata'))

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    phone_number = Column(String, unique=True, index=True, nullable=False)
    full_name = Column(String, default="GuestUser")
    
    # Farmer Questions
    has_farm = Column(String, nullable=True)      # 'yes' or 'no'
    water_supply = Column(String, nullable=True)  # 'rain', 'well', 'river', 'channel'
    farm_type = Column(String, nullable=True)     # 'Koradvahu', 'bagayati'

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