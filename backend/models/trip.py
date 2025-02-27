from datetime import datetime
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field, model_validator
from enum import Enum
import uuid

class TripStatus(str, Enum):
    """Enum for trip status"""
    DRAFT = "draft"
    UPCOMING = "upcoming"
    ACTIVE = "active"
    COMPLETED = "completed"
    CANCELLED = "cancelled"

class ActivityType(str, Enum):
    """Enum for activity types"""
    SIGHTSEEING = "sightseeing"
    DINING = "dining"
    ACCOMMODATION = "accommodation"
    TRANSPORTATION = "transportation"
    ENTERTAINMENT = "entertainment"
    SHOPPING = "shopping"
    RECREATION = "recreation"
    RELAXATION = "relaxation"
    OTHER = "other"

class WeatherData(BaseModel):
    """Model for weather data"""
    temperature: Optional[float] = None
    temperature_min: Optional[float] = None
    temperature_max: Optional[float] = None
    condition: Optional[str] = None
    precipitation_probability: Optional[float] = None
    humidity: Optional[float] = None
    wind_speed: Optional[float] = None
    wind_direction: Optional[str] = None
    cloud_cover: Optional[float] = None
    sunrise: Optional[datetime] = None
    sunset: Optional[datetime] = None
    forecast_timestamp: Optional[datetime] = None

class Location(BaseModel):
    """Model for location information"""
    id: Optional[str] = Field(default_factory=lambda: str(uuid.uuid4()))
    name: str
    address: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    place_id: Optional[str] = None  # Reference to external mapping service
    
class Activity(BaseModel):
    """Model for activities within a trip"""
    id: Optional[str] = Field(default_factory=lambda: str(uuid.uuid4()))
    title: str
    description: Optional[str] = None
    start_datetime: datetime
    end_datetime: Optional[datetime] = None
    all_day: bool = False
    location: Optional[Location] = None
    notes: Optional[str] = None
    activity_type: ActivityType = ActivityType.OTHER
    cost: Optional[float] = None
    currency: str = "USD"
    reservation_info: Optional[Dict[str, Any]] = None
    weather_data: Optional[WeatherData] = None
    images: List[str] = Field(default_factory=list)  # List of image URLs
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    @model_validator(mode='after')
    def check_end_after_start(self) -> 'Activity':
        start = self.start_datetime
        end = self.end_datetime
        
        if start and end and end < start:
            raise ValueError("end_datetime must be after start_datetime")
        return self

class TripBase(BaseModel):
    """Base Trip model with common fields"""
    title: str
    destination: str
    start_date: datetime
    end_date: datetime
    notes: Optional[str] = None
    
    @model_validator(mode='after')
    def check_dates(self) -> 'TripBase':
        start = self.start_date
        end = self.end_date
        
        if start and end and end < start:
            raise ValueError("end_date must be after start_date")
        return self

class TripCreate(TripBase):
    """Trip creation model"""
    activities: Optional[List[Activity]] = Field(default_factory=list)
    status: TripStatus = TripStatus.DRAFT
    is_archived: bool = False
    is_shared: bool = False

class TripUpdate(BaseModel):
    """Model for updating trip - all fields optional"""
    title: Optional[str] = None
    destination: Optional[str] = None
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    notes: Optional[str] = None
    status: Optional[TripStatus] = None
    is_archived: Optional[bool] = None
    is_shared: Optional[bool] = None
    
    @model_validator(mode='after')
    def check_dates(self) -> 'TripUpdate':
        start = self.start_date
        end = self.end_date
        
        if start and end and end < start:
            raise ValueError("end_date must be after start_date")
        return self

class Trip(TripBase):
    """Complete Trip model with all fields"""
    id: str
    activities: List[Activity] = Field(default_factory=list)
    status: TripStatus
    is_archived: bool = False
    is_draft: bool = False
    is_shared: bool = False
    owner_id: str
    created_at: datetime
    updated_at: datetime
    published_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

class TripSummary(BaseModel):
    """Summary model for listing trips"""
    id: str
    title: str
    destination: str
    start_date: datetime
    end_date: datetime
    status: TripStatus
    is_archived: bool
    is_draft: bool
    is_shared: bool
    activity_count: int
    cover_image_url: Optional[str] = None
    
    class Config:
        from_attributes = True

class TripShare(BaseModel):
    """Model for trip sharing information"""
    trip_id: str
    user_id: str
    permission: str = "view"  # view, edit, admin
    created_at: datetime = Field(default_factory=datetime.utcnow)
    
class TripShareCreate(BaseModel):
    """Model for creating a trip share"""
    trip_id: str
    user_id: str
    permission: str = "view"  # view, edit, admin
    
class ChatMessage(BaseModel):
    """Model for chat messages in trip discussions"""
    id: Optional[str] = Field(default_factory=lambda: str(uuid.uuid4()))
    trip_id: str
    user_id: str
    message: str
    is_ai: bool = False
    created_at: datetime = Field(default_factory=datetime.utcnow)
    
class TripImage(BaseModel):
    """Model for images associated with a trip"""
    id: Optional[str] = Field(default_factory=lambda: str(uuid.uuid4()))
    trip_id: str
    activity_id: Optional[str] = None
    url: str
    thumbnail_url: Optional[str] = None
    caption: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
    metadata: Optional[Dict[str, Any]] = None 