from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import Dict, Any, List, Optional
from datetime import datetime, timedelta

from services.weather import get_weather_forecast
from models.user import UserResponse
from dependencies.auth import get_current_user
from config.settings import settings

router = APIRouter(
    prefix="/weather",
    tags=["Weather"]
)

@router.get(
    "/forecast",
    summary="Get weather forecast for a location and date range",
    response_description="Weather forecast data"
)
async def get_forecast(
    latitude: float = Query(..., description="Latitude of the location"),
    longitude: float = Query(..., description="Longitude of the location"),
    start_date: str = Query(..., description="Start date (YYYY-MM-DD)"),
    end_date: str = Query(..., description="End date (YYYY-MM-DD)"),
    current_user: UserResponse = Depends(get_current_user)
) -> Dict[str, Any]:
    """
    Get weather forecast for a specific location and date range.
    
    If WeatherAPI.com is not configured, returns placeholder data with a note.
    """
    # Check if WeatherAPI.com is properly configured
    if not settings.WEATHER_API_KEY or settings.WEATHER_API_KEY == "your-weather-api-key":
        # API is not properly configured, but we'll still provide placeholder data
        pass  # The weather service itself will handle this case with placeholders
        
    try:
        # Parse dates
        try:
            start = datetime.strptime(start_date, "%Y-%m-%d")
            end = datetime.strptime(end_date, "%Y-%m-%d")
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid date format. Use YYYY-MM-DD."
            )
        
        # Limit forecast range to 14 days (WeatherAPI.com's max)
        if (end - start).days > 14:
            end = start + timedelta(days=14)
        
        # Get forecast from service
        forecast = await get_weather_forecast(latitude, longitude, start, end)
        
        return forecast
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error getting weather forecast: {str(e)}"
        ) 