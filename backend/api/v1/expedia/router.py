from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import Dict, Any, List, Optional
from datetime import date

from services.expedia import (
    search_activities,
    search_hotels,
    get_activity_details,
    get_hotel_details
)
from models.user import UserResponse
from dependencies.auth import get_current_user

router = APIRouter()

@router.get(
    "/activities/search",
    summary="Search for activities at a destination",
    response_description="List of activities"
)
async def search_activities_endpoint(
    location: str = Query(..., description="Destination location (city, region, etc.)"),
    start_date: date = Query(..., description="Activity start date"),
    end_date: date = Query(..., description="Activity end date"),
    activity_type: Optional[str] = Query(None, description="Type of activity (e.g., 'adventure', 'cultural')"),
    limit: int = Query(10, description="Maximum number of results"),
    current_user: UserResponse = Depends(get_current_user)
) -> List[Dict[str, Any]]:
    """
    Search for activities at a specific destination for given dates.
    
    The function returns a list of activities that match the search criteria,
    including activity name, price, rating, and location information.
    """
    try:
        activities = await search_activities(
            location=location, 
            start_date=start_date, 
            end_date=end_date, 
            activity_type=activity_type, 
            limit=limit
        )
        return activities
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error searching activities: {str(e)}"
        )

@router.get(
    "/hotels/search",
    summary="Search for hotels at a destination",
    response_description="List of hotels"
)
async def search_hotels_endpoint(
    location: str = Query(..., description="Destination location (city, region, etc.)"),
    check_in_date: date = Query(..., description="Check-in date"),
    check_out_date: date = Query(..., description="Check-out date"),
    guests: int = Query(2, description="Number of guests"),
    rooms: int = Query(1, description="Number of rooms"),
    limit: int = Query(10, description="Maximum number of results"),
    current_user: UserResponse = Depends(get_current_user)
) -> List[Dict[str, Any]]:
    """
    Search for hotels at a specific destination for given dates.
    
    The function returns a list of hotels that match the search criteria,
    including hotel name, price, rating, and location information.
    """
    try:
        hotels = await search_hotels(
            location=location,
            check_in_date=check_in_date,
            check_out_date=check_out_date,
            guests=guests,
            rooms=rooms,
            limit=limit
        )
        return hotels
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error searching hotels: {str(e)}"
        )

@router.get(
    "/activities/{activity_id}",
    summary="Get details for a specific activity",
    response_description="Activity details"
)
async def get_activity_details_endpoint(
    activity_id: str,
    current_user: UserResponse = Depends(get_current_user)
) -> Dict[str, Any]:
    """
    Get detailed information about a specific activity.
    
    The function returns comprehensive information about the requested activity,
    including description, price options, available dates, location details, and more.
    """
    try:
        activity = await get_activity_details(activity_id=activity_id)
        if not activity:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Activity not found"
            )
        return activity
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error getting activity details: {str(e)}"
        )

@router.get(
    "/hotels/{hotel_id}",
    summary="Get details for a specific hotel",
    response_description="Hotel details"
)
async def get_hotel_details_endpoint(
    hotel_id: str,
    current_user: UserResponse = Depends(get_current_user)
) -> Dict[str, Any]:
    """
    Get detailed information about a specific hotel.
    
    The function returns comprehensive information about the requested hotel,
    including amenities, room options, price details, location information, and more.
    """
    try:
        hotel = await get_hotel_details(hotel_id=hotel_id)
        if not hotel:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Hotel not found"
            )
        return hotel
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error getting hotel details: {str(e)}"
        ) 