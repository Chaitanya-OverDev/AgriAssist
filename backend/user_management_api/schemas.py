from pydantic import BaseModel, field_validator
from typing import Optional
import re

# --- Schema for Phone Input (Send OTP) ---
class PhoneSchema(BaseModel):
    phone_number: str

    @field_validator('phone_number')
    def validate_phone(cls, v):
        # 1. Trim whitespace
        v = v.strip()
        
        # 2. Check if blank
        if not v:
            raise ValueError("Phone number cannot be blank")
        
        # 3. Check if numeric
        if not v.isdigit():
            raise ValueError("Phone number must contain only digits")
        
        # 4. Check length (Must be 10)
        if len(v) != 10:
            raise ValueError("Phone number must be exactly 10 digits")
            
        # 5. Check prefix (Indian format 6-9)
        if v[0] not in ('6', '7', '8', '9'):
            raise ValueError("Phone number must start with 6, 7, 8, or 9")
            
        return v

# --- Schema for Verify OTP ---
class VerifyOTPSchema(BaseModel):
    phone_number: str
    otp: str

# --- Schema for Update Profile ---
class UpdateProfileSchema(BaseModel):
    full_name: Optional[str] = None
    profile_photo: Optional[str] = None

    @field_validator('full_name')
    def validate_name(cls, v):
        if v is None:
            return v
        
        # Check max length
        if len(v) > 100:
            raise ValueError("Name cannot exceed 100 characters")
        
        # Check for special symbols/numbers using Regex
        # ^[a-zA-Z\s]+$ allows only alphabets and spaces
        if not re.match(r"^[a-zA-Z\s]+$", v):
            raise ValueError("Name must not contain numbers or special symbols")
            
        return v

# --- Schema for Reading User Data (Response) ---
class UserResponse(BaseModel):
    id: int
    phone_number: str
    full_name: str
    profile_photo: str

    class Config:
        from_attributes = True