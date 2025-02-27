from fastapi import APIRouter, Depends, HTTPException, status, Body
from typing import Any, List

from models.user import (
    UserResponse, 
    UserWithProfile, 
    UserProfile, 
    UserProfileUpdate,
    FriendResponse
)
from services.auth import get_current_user
from services.users import (
    get_user_profile,
    update_user_profile,
    get_user_friends,
    add_friend,
    accept_friend_request,
    decline_friend_request,
    remove_friend,
    search_users,
    get_user_by_id
)

router = APIRouter()

@router.get("/me", response_model=UserWithProfile)
async def read_user_me(current_user: UserResponse = Depends(get_current_user)) -> Any:
    """
    Get current user profile.
    """
    profile = await get_user_profile(current_user.id)
    return UserWithProfile(
        **current_user.model_dump(),
        profile=profile
    )

@router.put("/me/profile", response_model=UserProfile)
async def update_profile(
    profile_update: UserProfileUpdate,
    current_user: UserResponse = Depends(get_current_user)
) -> Any:
    """
    Update user profile.
    """
    return await update_user_profile(current_user.id, profile_update)

@router.get("/friends", response_model=List[FriendResponse])
async def get_friends(current_user: UserResponse = Depends(get_current_user)) -> Any:
    """
    Get user's friends.
    """
    return await get_user_friends(current_user.id)

@router.post("/friends/{user_id}", status_code=status.HTTP_201_CREATED)
async def add_user_friend(
    user_id: str,
    current_user: UserResponse = Depends(get_current_user)
) -> Any:
    """
    Send a friend request to a user.
    """
    if user_id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You cannot add yourself as a friend",
        )
    
    return await add_friend(current_user.id, user_id)

@router.post("/friends/{user_id}/accept")
async def accept_request(
    user_id: str,
    current_user: UserResponse = Depends(get_current_user)
) -> Any:
    """
    Accept a friend request.
    """
    return await accept_friend_request(current_user.id, user_id)

@router.post("/friends/{user_id}/decline")
async def decline_request(
    user_id: str,
    current_user: UserResponse = Depends(get_current_user)
) -> Any:
    """
    Decline a friend request.
    """
    return await decline_friend_request(current_user.id, user_id)

@router.delete("/friends/{user_id}")
async def remove_user_friend(
    user_id: str,
    current_user: UserResponse = Depends(get_current_user)
) -> Any:
    """
    Remove a friend.
    """
    return await remove_friend(current_user.id, user_id)

@router.get("/search", response_model=List[UserResponse])
async def search(
    query: str,
    limit: int = 10,
    current_user: UserResponse = Depends(get_current_user)
) -> Any:
    """
    Search for users by username or name.
    """
    return await search_users(query, limit, current_user.id)

@router.get("/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: str,
    current_user: UserResponse = Depends(get_current_user)
) -> Any:
    """
    Get user by ID.
    """
    return await get_user_by_id(user_id) 