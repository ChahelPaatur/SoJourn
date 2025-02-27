from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, EmailStr, Field, field_validator
import uuid

class UserBase(BaseModel):
    """Base User model with common fields"""
    email: EmailStr
    username: str
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    
class UserCreate(UserBase):
    """User creation model with password"""
    password: str
    
    @field_validator('password')
    @classmethod
    def password_strength(cls, v):
        if len(v) < 8:
            raise ValueError('Password must be at least 8 characters')
        return v

class UserProfile(BaseModel):
    """User profile information"""
    user_id: str
    dark_mode_enabled: bool = False
    gender: Optional[str] = None
    age: Optional[int] = None
    weather_preference: Optional[str] = None
    notifications_enabled: bool = True
    email_notifications_enabled: bool = True
    pinterest_connected: bool = False
    pinterest_username: Optional[str] = None
    profile_image_url: Optional[str] = None
    preferred_climate: Optional[str] = None
    preferred_trip_type: Optional[str] = None
    budget: Optional[str] = None
    preferred_activities: List[str] = Field(default_factory=list)
    language_preference: str = "en"
    
class UserProfileUpdate(BaseModel):
    """Model for updating user profile - all fields optional"""
    dark_mode_enabled: Optional[bool] = None
    gender: Optional[str] = None
    age: Optional[int] = None
    weather_preference: Optional[str] = None
    notifications_enabled: Optional[bool] = None
    email_notifications_enabled: Optional[bool] = None
    pinterest_connected: Optional[bool] = None
    pinterest_username: Optional[str] = None
    profile_image_url: Optional[str] = None
    preferred_climate: Optional[str] = None
    preferred_trip_type: Optional[str] = None
    budget: Optional[str] = None
    preferred_activities: Optional[List[str]] = None
    language_preference: Optional[str] = None

class UserResponse(UserBase):
    """Response model for user info"""
    id: str
    created_at: datetime
    is_active: bool = True
    
    class Config:
        from_attributes = True

class UserWithProfile(UserResponse):
    """User model with profile info included"""
    profile: Optional[UserProfile] = None
    
    class Config:
        from_attributes = True

class UserFriend(BaseModel):
    """Model representing a friend relationship"""
    user_id: str
    friend_id: str
    created_at: datetime = Field(default_factory=datetime.utcnow)
    status: str = "pending"  # pending, accepted, declined
    
class FriendResponse(BaseModel):
    """Response model for friend info"""
    id: str
    username: str
    first_name: Optional[str]
    last_name: Optional[str]
    profile_image_url: Optional[str]
    status: str
    
    class Config:
        from_attributes = True 