from sqlalchemy import Column, Integer, String, DateTime, Boolean, ForeignKey, Text,Float
from sqlalchemy.orm import relationship
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

    # Farmer Profile
    has_farm = Column(String, nullable=True)
    water_supply = Column(String, nullable=True)
    farm_type = Column(String, nullable=True)

    # Location Data
    state = Column(String, nullable=True)
    district = Column(String, nullable=True)
    latitude = Column(Float, nullable=True) 
    longitude = Column(Float, nullable=True) 

    is_verified = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    chat_sessions = relationship("ChatSession", back_populates="user", cascade="all, delete-orphan")

class OTP(Base):
    __tablename__ = "otp_codes"

    id = Column(Integer, primary_key=True, index=True)
    phone_number = Column(String, index=True, nullable=False)
    otp_code = Column(String, nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)
    is_used = Column(Boolean, default=False)

class ChatSession(Base):
    __tablename__ = "chat_sessions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    title = Column(String, default="New Chat") # E.g., "Cotton Disease Info"
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="chat_sessions")
    messages = relationship("ChatMessage", back_populates="session", cascade="all, delete-orphan")

class ChatMessage(Base):
    __tablename__ = "chat_messages"

    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(Integer, ForeignKey("chat_sessions.id"), nullable=False)
    role = Column(String, nullable=False) # 'user' or 'model'
    content = Column(Text, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    session = relationship("ChatSession", back_populates="messages")

class CommodityCache(Base):
    __tablename__ = "commodity_cache"

    id = Column(Integer, primary_key=True, index=True)
    state = Column(String, index=True, nullable=False)
    district = Column(String, index=True, nullable=True) 
    commodity = Column(String, index=True, nullable=False)
    commodity_group = Column(String, nullable=True)
    
  
    msp = Column(String, nullable=True)
    price_latest = Column(String, nullable=True) 
    price_mid = Column(String, nullable=True)    
    price_old = Column(String, nullable=True)    
    
    scraped_at = Column(DateTime(timezone=True), server_default=func.now())

class WeatherCache(Base):
    __tablename__ = "weather_cache"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), index=True, nullable=False)
    forecast_data = Column(Text, nullable=False) 
    fetched_at = Column(DateTime(timezone=True), server_default=func.now())