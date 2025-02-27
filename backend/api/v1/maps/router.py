from fastapi import APIRouter, Depends, Query
from typing import Any, List, Optional
from datetime import datetime

from models.user import UserResponse
from models.trip import Location
from services.auth import get_current_user
from services.maps import (
    search_locations,
    get_place_details,
    get_directions,
    geocode_address,
    reverse_geocode
)

router = APIRouter()

@router.get("/search", response_model=List[Location])
async def search_locations_endpoint(
    query: str = Query(..., description="Search query"),
    latitude: Optional[float] = Query(None, description="Location latitude for context"),
    longitude: Optional[float] = Query(None, description="Location longitude for context"),
    locale: str = Query("en-US", description="Locale for results"),
    current_user: UserResponse = Depends(get_current_user)
) -> Any:
    """
    Search for locations using Apple Maps API
    """
    return await search_locations(query, latitude, longitude, locale)

@router.get("/place/{place_id}")
async def get_place_details_endpoint(
    place_id: str,
    locale: str = Query("en-US", description="Locale for results"),
    current_user: UserResponse = Depends(get_current_user)
) -> Any:
    """
    Get detailed information about a place
    """
    result = await get_place_details(place_id, locale)
    if result is None:
        return {"error": "Place not found"}
    return result

@router.get("/directions")
async def get_directions_endpoint(
    origin_lat: float = Query(..., description="Origin latitude"),
    origin_lng: float = Query(..., description="Origin longitude"),
    destination_lat: float = Query(..., description="Destination latitude"),
    destination_lng: float = Query(..., description="Destination longitude"),
    mode: str = Query("DRIVING", description="Transportation mode (DRIVING, WALKING, TRANSIT)"),
    departure_time: Optional[str] = Query(None, description="Departure time in ISO format"),
    locale: str = Query("en-US", description="Locale for results"),
    current_user: UserResponse = Depends(get_current_user)
) -> Any:
    """
    Get directions between two points
    """
    # Parse departure time if provided
    departure_datetime = None
    if departure_time:
        try:
            departure_datetime = datetime.fromisoformat(departure_time)
        except ValueError:
            return {"error": "Invalid departure time format"}
    
    result = await get_directions(
        origin_lat,
        origin_lng,
        destination_lat,
        destination_lng,
        mode,
        departure_datetime,
        locale
    )
    
    if result is None:
        return {"error": "Could not find directions"}
    
    return result

@router.get("/geocode", response_model=Location)
async def geocode_address_endpoint(
    address: str = Query(..., description="Address to geocode"),
    locale: str = Query("en-US", description="Locale for results"),
    current_user: UserResponse = Depends(get_current_user)
) -> Any:
    """
    Geocode an address to get its coordinates
    """
    result = await geocode_address(address, locale)
    if result is None:
        return {"error": "Address could not be geocoded"}
    return result

@router.get("/reverse-geocode", response_model=Location)
async def reverse_geocode_endpoint(
    latitude: float = Query(..., description="Latitude"),
    longitude: float = Query(..., description="Longitude"),
    locale: str = Query("en-US", description="Locale for results"),
    current_user: UserResponse = Depends(get_current_user)
) -> Any:
    """
    Reverse geocode coordinates to get address
    """
    result = await reverse_geocode(latitude, longitude, locale)
    if result is None:
        return {"error": "Coordinates could not be reverse geocoded"}
    return result 