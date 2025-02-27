from fastapi import APIRouter, Depends, Query
from datetime import datetime, timedelta
from typing import Any

from models.user import UserResponse
from services.auth import get_current_user
from services.weather import get_weather_forecast, get_weather_data_for_activity

router = APIRouter()

@router.get("/forecast")
async def get_forecast(
    latitude: float = Query(..., description="Location latitude"),
    longitude: float = Query(..., description="Location longitude"),
    start_date: str = Query(None, description="Start date in ISO format (YYYY-MM-DD)"),
    end_date: str = Query(None, description="End date in ISO format (YYYY-MM-DD)"),
    current_user: UserResponse = Depends(get_current_user)
) -> Any:
    """
    Get weather forecast for a location and date range.
    """
    # Parse dates or use defaults
    try:
        start = datetime.fromisoformat(start_date) if start_date else datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
        end = datetime.fromisoformat(end_date) if end_date else start + timedelta(days=7)
    except ValueError:
        start = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
        end = start + timedelta(days=7)
    
    # Get forecast
    forecast = await get_weather_forecast(latitude, longitude, start, end)
    
    return forecast

@router.get("/activity")
async def get_weather_for_activity(
    latitude: float = Query(..., description="Activity location latitude"),
    longitude: float = Query(..., description="Activity location longitude"),
    date: str = Query(..., description="Activity date in ISO format (YYYY-MM-DD)"),
    current_user: UserResponse = Depends(get_current_user)
) -> Any:
    """
    Get weather data for a specific activity date and location.
    """
    try:
        activity_date = datetime.fromisoformat(date)
    except ValueError:
        activity_date = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
    
    # Get weather data
    weather_data = await get_weather_data_for_activity(latitude, longitude, activity_date)
    
    if weather_data:
        return weather_data.model_dump()
    else:
        return {"error": "No weather data available for this location and date"} 