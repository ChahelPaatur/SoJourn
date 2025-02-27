from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import Dict, Any, List, Optional
from datetime import datetime

from services.maps import (
    search_locations,
    get_place_details,
    get_directions,
    geocode_address,
    reverse_geocode
)
from models.user import UserResponse
from models.trip import Location
from dependencies.auth import get_current_user
from config.settings import settings

router = APIRouter(
    prefix="/maps",
    tags=["Maps"]
)

@router.get(
    "/search",
    summary="Search for locations",
    response_model=List[Location]
)
async def search(
    query: str = Query(..., description="Search query"),
    latitude: Optional[float] = Query(None, description="Current latitude for location biasing"),
    longitude: Optional[float] = Query(None, description="Current longitude for location biasing"),
    locale: str = Query("en-US", description="Locale for results"),
    current_user: UserResponse = Depends(get_current_user)
) -> List[Location]:
    """
    Search for locations using a query string.
    
    If Apple Maps API is not configured, returns placeholder data with a note.
    """
    # Check if Apple Maps API is properly configured
    if not all([
        settings.APPLE_MAPS_TOKEN,
        settings.APPLE_MAPS_TEAM_ID,
        settings.APPLE_MAPS_KEY_ID
    ]) or settings.APPLE_MAPS_TOKEN == "your-apple-maps-token":
        # API is not properly configured, but we'll still provide placeholder data
        pass  # The maps service itself will handle this case with placeholders
        
    try:
        locations = await search_locations(query, latitude, longitude, locale)
        return locations
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error searching locations: {str(e)}"
        )

@router.get(
    "/place/{place_id}",
    summary="Get place details",
    response_description="Place details"
)
async def get_place(
    place_id: str,
    locale: str = Query("en-US", description="Locale for results"),
    current_user: UserResponse = Depends(get_current_user)
) -> Dict[str, Any]:
    """
    Get details about a specific place using its place_id.
    
    If Apple Maps API is not configured, returns placeholder data with a note.
    """
    # Check if Apple Maps API is properly configured
    if not all([
        settings.APPLE_MAPS_TOKEN,
        settings.APPLE_MAPS_TEAM_ID,
        settings.APPLE_MAPS_KEY_ID
    ]) or settings.APPLE_MAPS_TOKEN == "your-apple-maps-token":
        # API is not properly configured, but we'll still provide placeholder data
        pass  # The maps service itself will handle this case with placeholders
        
    try:
        details = await get_place_details(place_id, locale)
        if details is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Place not found"
            )
        return details
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error getting place details: {str(e)}"
        )

@router.get(
    "/directions",
    summary="Get directions between two points",
    response_description="Directions data"
)
async def directions(
    origin_lat: float = Query(..., description="Origin latitude"),
    origin_lng: float = Query(..., description="Origin longitude"),
    destination_lat: float = Query(..., description="Destination latitude"),
    destination_lng: float = Query(..., description="Destination longitude"),
    mode: str = Query("DRIVING", description="Transportation mode (DRIVING, WALKING, TRANSIT)"),
    departure_time: Optional[datetime] = Query(None, description="Departure time (ISO format)"),
    locale: str = Query("en-US", description="Locale for results"),
    current_user: UserResponse = Depends(get_current_user)
) -> Dict[str, Any]:
    """
    Get directions between two points.
    
    If Apple Maps API is not configured, returns placeholder data with a note.
    """
    # Check if Apple Maps API is properly configured
    if not all([
        settings.APPLE_MAPS_TOKEN,
        settings.APPLE_MAPS_TEAM_ID,
        settings.APPLE_MAPS_KEY_ID
    ]) or settings.APPLE_MAPS_TOKEN == "your-apple-maps-token":
        # API is not properly configured, but we'll still provide placeholder data
        pass  # The maps service itself will handle this case with placeholders
        
    try:
        directions_data = await get_directions(
            origin_lat, 
            origin_lng, 
            destination_lat, 
            destination_lng, 
            mode, 
            departure_time, 
            locale
        )
        
        if directions_data is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="No route found"
            )
            
        return directions_data
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error getting directions: {str(e)}"
        )

@router.get(
    "/geocode",
    summary="Geocode an address to coordinates",
    response_model=Location
)
async def geocode(
    address: str = Query(..., description="Address to geocode"),
    locale: str = Query("en-US", description="Locale for results"),
    current_user: UserResponse = Depends(get_current_user)
) -> Location:
    """
    Convert an address to coordinates.
    
    If Apple Maps API is not configured, returns placeholder data with a note.
    """
    # Check if Apple Maps API is properly configured
    if not all([
        settings.APPLE_MAPS_TOKEN,
        settings.APPLE_MAPS_TEAM_ID,
        settings.APPLE_MAPS_KEY_ID
    ]) or settings.APPLE_MAPS_TOKEN == "your-apple-maps-token":
        # API is not properly configured, but we'll still provide placeholder data
        pass  # The maps service itself will handle this case with placeholders
        
    try:
        location = await geocode_address(address, locale)
        if location is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Address not found"
            )
        return location
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error geocoding address: {str(e)}"
        )

@router.get(
    "/reverse-geocode",
    summary="Reverse geocode coordinates to address",
    response_model=Location
)
async def reverse(
    latitude: float = Query(..., description="Latitude"),
    longitude: float = Query(..., description="Longitude"),
    locale: str = Query("en-US", description="Locale for results"),
    current_user: UserResponse = Depends(get_current_user)
) -> Location:
    """
    Convert coordinates to an address.
    
    If Apple Maps API is not configured, returns placeholder data with a note.
    """
    # Check if Apple Maps API is properly configured
    if not all([
        settings.APPLE_MAPS_TOKEN,
        settings.APPLE_MAPS_TEAM_ID,
        settings.APPLE_MAPS_KEY_ID
    ]) or settings.APPLE_MAPS_TOKEN == "your-apple-maps-token":
        # API is not properly configured, but we'll still provide placeholder data
        pass  # The maps service itself will handle this case with placeholders
        
    try:
        location = await reverse_geocode(latitude, longitude, locale)
        if location is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="No address found for these coordinates"
            )
        return location
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error reverse geocoding: {str(e)}"
        ) 