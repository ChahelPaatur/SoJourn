from fastapi import APIRouter, Depends, HTTPException, status, Path, Query
from typing import Any, List, Optional

from models.trip import Activity
from models.user import UserResponse
from services.auth import get_current_user
from services.activities import (
    create_activity,
    get_activity_by_id,
    update_activity,
    delete_activity,
    get_trip_activities
)

router = APIRouter()

@router.post("", response_model=Activity, status_code=status.HTTP_201_CREATED)
async def create_trip_activity(
    activity: Activity,
    trip_id: str = Query(..., description="ID of the trip to add activity to"),
    current_user: UserResponse = Depends(get_current_user)
) -> Any:
    """
    Create a new activity for a trip.
    """
    return await create_activity(activity, trip_id, current_user.id)

@router.get("/{activity_id}", response_model=Activity)
async def get_activity(
    activity_id: str = Path(..., description="ID of the activity to retrieve"),
    current_user: UserResponse = Depends(get_current_user)
) -> Any:
    """
    Get activity by ID.
    """
    return await get_activity_by_id(activity_id, current_user.id)

@router.put("/{activity_id}", response_model=Activity)
async def update_trip_activity(
    activity_update: Activity,
    activity_id: str = Path(..., description="ID of the activity to update"),
    current_user: UserResponse = Depends(get_current_user)
) -> Any:
    """
    Update an activity.
    """
    return await update_activity(activity_id, activity_update, current_user.id)

@router.delete("/{activity_id}")
async def delete_trip_activity(
    activity_id: str = Path(..., description="ID of the activity to delete"),
    current_user: UserResponse = Depends(get_current_user)
) -> Any:
    """
    Delete an activity.
    """
    return await delete_activity(activity_id, current_user.id)

@router.get("/trip/{trip_id}", response_model=List[Activity])
async def get_activities_by_trip(
    trip_id: str = Path(..., description="ID of the trip to get activities for"),
    date: Optional[str] = Query(None, description="Filter activities by date (ISO format YYYY-MM-DD)"),
    activity_type: Optional[str] = Query(None, description="Filter activities by type"),
    current_user: UserResponse = Depends(get_current_user)
) -> Any:
    """
    Get all activities for a trip with optional filters.
    """
    return await get_trip_activities(trip_id, date, activity_type, current_user.id) 