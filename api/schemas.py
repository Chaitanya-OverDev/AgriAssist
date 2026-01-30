from pydantic import BaseModel, field_validator
from typing import Optional
from datetime import datetime
import re

# --- Schema for Phone Input (Send OTP) ---
class PhoneSchema(BaseModel):
    phone_number: str

    @field_validator('phone_number')
    def validate_phone(cls, v):
        v = v.strip()
        if not v: raise ValueError("Phone number cannot be blank")
        if not v.isdigit(): raise ValueError("Phone number must contain only digits")
        if len(v) != 10: raise ValueError("Phone number must be exactly 10 digits")
        if v[0] not in ('6', '7', '8', '9'): raise ValueError("Phone number must start with 6, 7, 8, or 9")
        return v

# --- Schema for Verify OTP ---
class VerifyOTPSchema(BaseModel):
    phone_number: str
    otp: str

# --- Schema for Reading User Data (Response) ---
class UserResponse(BaseModel):
    id: int
    phone_number: str
    full_name: Optional[str] = "GuestUser"
    # Removed profile_pic_url
    
    # Farmer Fields
    has_farm: Optional[str] = None
    water_supply: Optional[str] = None
    farm_type: Optional[str] = None
    
    is_verified: bool   
    created_at: datetime
    updated_at: Optional[datetime]

    class Config:
        from_attributes = True