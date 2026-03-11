from sqlalchemy import Column, Integer, String, DateTime, Boolean, ForeignKey, Text, Float, LargeBinary, JSON
from sqlalchemy.orm import relationship
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
    created_at = Column(DateTime(timezone=True), default=get_ist_time)
    updated_at = Column(DateTime(timezone=True), onupdate=get_ist_time)

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
    title = Column(String, default="New Chat") 

    created_at = Column(DateTime(timezone=True), default=get_ist_time)

    user = relationship("User", back_populates="chat_sessions")
    messages = relationship("ChatMessage", back_populates="session", cascade="all, delete-orphan")

class ChatMessage(Base):
    __tablename__ = "chat_messages"

    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(Integer, ForeignKey("chat_sessions.id"), nullable=False)
    role = Column(String, nullable=False) 
    content = Column(Text, nullable=False)
    
    audio_data = Column(LargeBinary, nullable=True) 
    
    # Using our custom IST function
    created_at = Column(DateTime(timezone=True), default=get_ist_time)
    session = relationship("ChatSession", back_populates="messages")

    @property
    def has_audio(self) -> bool:
        return self.audio_data is not None

class WeatherCache(Base):
    __tablename__ = "weather_cache"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), index=True, nullable=False)
    forecast_data = Column(Text, nullable=False) 
    
    # Using our custom IST function
    fetched_at = Column(DateTime(timezone=True), default=get_ist_time)


class RawScheme(Base):
    __tablename__ = "raw_schemes"

    id = Column(Integer, primary_key=True, index=True)
    slug = Column(String, unique=True, index=True, nullable=False) 
    scheme_name = Column(String, nullable=False)
    short_title = Column(String)
    level = Column(String)
    scheme_for = Column(String)
    states = Column(JSON) 
    categories = Column(JSON)
    close_date = Column(String, nullable=True)
    priority = Column(Integer)
    description = Column(String)
    tags = Column(JSON)
    created_at = Column(DateTime(timezone=True), default=get_ist_time)

class CleanedScheme(Base):
    __tablename__ = "cleaned_schemes"

    id = Column(Integer, primary_key=True, index=True)
    slug = Column(String, unique=True, index=True, nullable=False)
    scheme_name = Column(String, nullable=False)
    description = Column(String)
    
    states = Column(JSON)          
    level = Column(String)         
    scheme_for = Column(String)    
    close_date = Column(String, nullable=True) 
    
    tags = Column(JSON)
    
    created_at = Column(DateTime(timezone=True), default=get_ist_time)