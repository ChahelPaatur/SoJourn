from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional
from datetime import datetime
from uuid import UUID

from models.user import UserResponse, FriendResponse
from services.auth import get_current_user
from services.social import (
    get_user_friends,
    send_friend_request,
    accept_friend_request,
    decline_friend_request,
    remove_friend,
    get_friend_requests,
    get_mutual_friends,
    search_users,
    get_user_profile
)

router = APIRouter(prefix="/social", tags=["Social"])

@router.get("/friends", response_model=List[FriendResponse])
async def list_friends(
    current_user: dict = Depends(get_current_user)
):
    """Get the current user's friends list"""
    return await get_user_friends(current_user["id"])

@router.post("/friends/request/{user_id}", status_code=status.HTTP_201_CREATED)
async def create_friend_request(
    user_id: UUID,
    current_user: dict = Depends(get_current_user)
):
    """Send a friend request to another user"""
    return await send_friend_request(current_user["id"], user_id)

@router.post("/friends/accept/{request_id}", status_code=status.HTTP_200_OK)
async def accept_request(
    request_id: UUID,
    current_user: dict = Depends(get_current_user)
):
    """Accept a friend request"""
    return await accept_friend_request(current_user["id"], request_id)

@router.post("/friends/decline/{request_id}", status_code=status.HTTP_200_OK)
async def decline_request(
    request_id: UUID,
    current_user: dict = Depends(get_current_user)
):
    """Decline a friend request"""
    return await decline_friend_request(current_user["id"], request_id)

@router.delete("/friends/{friend_id}", status_code=status.HTTP_200_OK)
async def delete_friend(
    friend_id: UUID,
    current_user: dict = Depends(get_current_user)
):
    """Remove a friend from the user's friends list"""
    return await remove_friend(current_user["id"], friend_id)

@router.get("/friends/requests", response_model=List[dict])
async def list_friend_requests(
    current_user: dict = Depends(get_current_user)
):
    """Get the current user's pending friend requests"""
    return await get_friend_requests(current_user["id"])

@router.get("/friends/mutual/{user_id}", response_model=List[FriendResponse])
async def get_mutuals(
    user_id: UUID,
    current_user: dict = Depends(get_current_user)
):
    """Get mutual friends between current user and another user"""
    return await get_mutual_friends(current_user["id"], user_id)

@router.get("/users/search", response_model=List[UserResponse])
async def search_for_users(
    query: str = Query(..., min_length=2),
    limit: int = Query(10, ge=1, le=50),
    current_user: dict = Depends(get_current_user)
):
    """Search for users by username or email"""
    return await search_users(query, limit, current_user["id"])

@router.get("/users/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: UUID,
    current_user: dict = Depends(get_current_user)
):
    """Get user profile information"""
    return await get_user_profile(user_id, current_user["id"]) 