from fastapi import APIRouter, Depends, HTTPException, status
from typing import Any

from models.user import UserResponse
from models.ai import (
    TripGenerationRequest,
    TripGenerationResponse,
    ActivityRecommendationRequest,
    ActivityRecommendationResponse,
    ChatRequest,
    ChatResponse,
    BudgetOptimizationRequest,
    BudgetOptimizationResponse,
    TripAnalysisRequest,
    TripAnalysisResponse
)
from services.auth import get_current_user
from services.ai import (
    generate_trip,
    recommend_activities,
    chat_with_ai,
    optimize_budget,
    analyze_trip
)

router = APIRouter()

@router.post("/trips/generate", response_model=TripGenerationResponse)
async def generate_trip_itinerary(
    request: TripGenerationRequest,
    current_user: UserResponse = Depends(get_current_user)
) -> Any:
    """
    Generate a trip itinerary using AI.
    """
    return await generate_trip(request, current_user.id)

@router.post("/activities/recommend", response_model=ActivityRecommendationResponse)
async def recommend_trip_activities(
    request: ActivityRecommendationRequest,
    current_user: UserResponse = Depends(get_current_user)
) -> Any:
    """
    Get AI-generated activity recommendations for a trip.
    """
    return await recommend_activities(request, current_user.id)

@router.post("/chat", response_model=ChatResponse)
async def chat_with_travel_ai(
    request: ChatRequest,
    current_user: UserResponse = Depends(get_current_user)
) -> Any:
    """
    Chat with an AI assistant about a trip.
    """
    return await chat_with_ai(request, current_user.id)

@router.post("/budget/optimize", response_model=BudgetOptimizationResponse)
async def optimize_trip_budget(
    request: BudgetOptimizationRequest,
    current_user: UserResponse = Depends(get_current_user)
) -> Any:
    """
    Get AI-generated budget optimization suggestions for a trip.
    """
    return await optimize_budget(request, current_user.id)

@router.post("/trips/analyze", response_model=TripAnalysisResponse)
async def analyze_trip_details(
    request: TripAnalysisRequest,
    current_user: UserResponse = Depends(get_current_user)
) -> Any:
    """
    Get AI-powered analysis of a trip.
    """
    return await analyze_trip(request, current_user.id) 