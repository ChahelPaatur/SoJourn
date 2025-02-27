from datetime import datetime
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field, ConfigDict
from enum import Enum
import uuid
from .trip import TripStatus, Activity, Location

class AiModel(str, Enum):
    """Enum for AI model types"""
    CHATGPT = "chatgpt"
    GPT4 = "gpt4"

# Base model configuration to disable protected namespace checks
class BaseAIModel(BaseModel):
    model_config = ConfigDict(protected_namespaces=())

class TripGenerationRequest(BaseAIModel):
    """Request model for AI trip generation"""
    destination: str
    start_date: datetime
    end_date: datetime
    preferences: Dict[str, Any] = Field(default_factory=dict)
    budget_level: Optional[str] = None  # budget, moderate, luxury
    accommodation_type: Optional[str] = None  # hotel, hostel, apartment, etc.
    activity_preferences: List[str] = Field(default_factory=list)
    dietary_restrictions: List[str] = Field(default_factory=list)
    accessibility_needs: List[str] = Field(default_factory=list)
    pace_preference: Optional[str] = None  # relaxed, moderate, busy
    model: AiModel = AiModel.GPT4

class TripGenerationResponse(BaseAIModel):
    """Response model for AI trip generation"""
    trip_id: str  # If saved as a draft
    title: str
    destination: str
    start_date: datetime
    end_date: datetime
    activities: List[Activity]
    suggestions: List[str] = Field(default_factory=list)
    estimated_costs: Dict[str, float] = Field(default_factory=dict)
    generated_at: datetime = Field(default_factory=datetime.utcnow)
    model_used: AiModel

class ActivityRecommendationRequest(BaseAIModel):
    """Request model for activity recommendations"""
    trip_id: str
    date: Optional[datetime] = None  # If None, recommend for entire trip
    activity_type: Optional[str] = None  # Filter by type
    count: int = 5  # Number of recommendations to generate
    model: AiModel = AiModel.GPT4

class ActivityRecommendation(BaseAIModel):
    """Model for a single activity recommendation"""
    title: str
    description: str
    activity_type: str
    location: Optional[Location] = None
    estimated_duration: Optional[float] = None  # In hours
    estimated_cost: Optional[float] = None
    currency: str = "USD"
    reasoning: str  # Why this activity was recommended

class ActivityRecommendationResponse(BaseAIModel):
    """Response model for activity recommendations"""
    trip_id: str
    recommendations: List[ActivityRecommendation]
    generated_at: datetime = Field(default_factory=datetime.utcnow)
    model_used: AiModel

class ChatRequest(BaseAIModel):
    """Request model for AI chat interactions"""
    trip_id: str
    message: str
    chat_history_id: Optional[str] = None  # To continue existing conversation
    model: AiModel = AiModel.GPT4

class ChatResponse(BaseAIModel):
    """Response model for AI chat interactions"""
    trip_id: str
    message_id: str
    response: str
    model_used: AiModel
    generated_at: datetime = Field(default_factory=datetime.utcnow)
    
class BudgetOptimizationRequest(BaseAIModel):
    """Request model for budget optimization"""
    trip_id: str
    budget_total: float
    currency: str = "USD"
    priorities: Optional[Dict[str, float]] = None  # Weights for different categories
    must_keep_activities: List[str] = Field(default_factory=list)  # Activity IDs to keep
    model: AiModel = AiModel.GPT4
    
class BudgetOptimizationResponse(BaseAIModel):
    """Response model for budget optimization"""
    trip_id: str
    original_total: float
    optimized_total: float
    currency: str
    recommendations: Dict[str, Any]  # Detailed recommendations
    activity_changes: Dict[str, Any]  # Suggested changes to activities
    generated_at: datetime = Field(default_factory=datetime.utcnow)
    model_used: AiModel

class TripAnalysisRequest(BaseAIModel):
    """Request model for trip analysis"""
    trip_id: str
    analysis_type: str  # balance, variety, pacing, etc.
    model: AiModel = AiModel.GPT4
    
class TripAnalysisResponse(BaseAIModel):
    """Response model for trip analysis"""
    trip_id: str
    analysis_type: str
    insights: List[Dict[str, Any]]
    recommendations: List[Dict[str, Any]]
    generated_at: datetime = Field(default_factory=datetime.utcnow)
    model_used: AiModel

class VisualInspirationRequest(BaseAIModel):
    """Request model for visual inspiration collection"""
    trip_id: Optional[str] = None
    destination: Optional[str] = None
    themes: List[str] = Field(default_factory=list)
    pinterest_board_url: Optional[str] = None
    count: int = 10  # Number of inspirations to find
    
class VisualInspiration(BaseModel):
    """Model for a single visual inspiration item"""
    image_url: str
    source_url: Optional[str] = None
    title: Optional[str] = None
    description: Optional[str] = None
    tags: List[str] = Field(default_factory=list)
    
class VisualInspirationResponse(BaseModel):
    """Response model for visual inspiration collection"""
    trip_id: Optional[str] = None
    inspirations: List[VisualInspiration]
    generated_at: datetime = Field(default_factory=datetime.utcnow) 