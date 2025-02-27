from fastapi import APIRouter, Depends, HTTPException, status, Query, Path
from typing import Any, List, Optional

from models.trip import TripCreate, Trip, TripUpdate, TripSummary, TripShareCreate
from models.user import UserResponse
from services.auth import get_current_user
from services.trips import (
    create_trip,
    get_trip_by_id,
    update_trip,
    delete_trip,
    get_user_trips,
    publish_trip,
    archive_trip,
    unarchive_trip,
    share_trip,
    get_trip_shares,
    remove_trip_share
)

router = APIRouter()

@router.post("", response_model=Trip, status_code=status.HTTP_201_CREATED)
async def create_new_trip(
    trip_data: TripCreate,
    current_user: UserResponse = Depends(get_current_user)
) -> Any:
    """
    Create a new trip.
    """
    return await create_trip(trip_data, current_user.id)

@router.get("", response_model=List[TripSummary])
async def get_trips(
    status: Optional[str] = None,
    archived: Optional[bool] = None,
    shared: Optional[bool] = None,
    limit: int = Query(10, gt=0),
    offset: int = Query(0, ge=0),
    current_user: UserResponse = Depends(get_current_user)
) -> Any:
    """
    Get user's trips with filters.
    """
    return await get_user_trips(current_user.id, status, archived, shared, limit, offset)

@router.get("/{trip_id}", response_model=Trip)
async def get_trip(
    trip_id: str = Path(...),
    current_user: UserResponse = Depends(get_current_user)
) -> Any:
    """
    Get trip by ID.
    """
    return await get_trip_by_id(trip_id, current_user.id)

@router.put("/{trip_id}", response_model=Trip)
async def update_trip_details(
    trip_update: TripUpdate,
    trip_id: str = Path(...),
    current_user: UserResponse = Depends(get_current_user)
) -> Any:
    """
    Update trip details.
    """
    return await update_trip(trip_id, trip_update, current_user.id)

@router.delete("/{trip_id}")
async def delete_trip_by_id(
    trip_id: str = Path(...),
    current_user: UserResponse = Depends(get_current_user)
) -> Any:
    """
    Delete trip by ID.
    """
    return await delete_trip(trip_id, current_user.id)

@router.post("/{trip_id}/publish", response_model=Trip)
async def publish_trip_by_id(
    trip_id: str = Path(...),
    current_user: UserResponse = Depends(get_current_user)
) -> Any:
    """
    Publish a draft trip.
    """
    return await publish_trip(trip_id, current_user.id)

@router.post("/{trip_id}/archive")
async def archive_trip_by_id(
    trip_id: str = Path(...),
    current_user: UserResponse = Depends(get_current_user)
) -> Any:
    """
    Archive a trip.
    """
    return await archive_trip(trip_id, current_user.id)

@router.post("/{trip_id}/unarchive")
async def unarchive_trip_by_id(
    trip_id: str = Path(...),
    current_user: UserResponse = Depends(get_current_user)
) -> Any:
    """
    Unarchive a trip.
    """
    return await unarchive_trip(trip_id, current_user.id)

@router.post("/{trip_id}/share", status_code=status.HTTP_201_CREATED)
async def share_trip_with_user(
    share_data: TripShareCreate,
    trip_id: str = Path(...),
    current_user: UserResponse = Depends(get_current_user)
) -> Any:
    """
    Share a trip with another user.
    """
    return await share_trip(trip_id, share_data.user_id, share_data.permission, current_user.id)

@router.get("/{trip_id}/shares", response_model=List[dict])
async def get_trip_share_users(
    trip_id: str = Path(...),
    current_user: UserResponse = Depends(get_current_user)
) -> Any:
    """
    Get users with whom a trip is shared.
    """
    return await get_trip_shares(trip_id, current_user.id)

@router.delete("/{trip_id}/shares/{user_id}")
async def remove_trip_share_user(
    trip_id: str = Path(...),
    user_id: str = Path(...),
    current_user: UserResponse = Depends(get_current_user)
) -> Any:
    """
    Remove a user's access to a shared trip.
    """
    return await remove_trip_share(trip_id, user_id, current_user.id) 