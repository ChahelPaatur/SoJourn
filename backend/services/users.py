from typing import List, Optional, Dict, Any
from fastapi import HTTPException, status
import uuid
from datetime import datetime

from models.user import UserProfile, UserProfileUpdate, UserResponse, FriendResponse
from database.connection import get_db_client

async def get_user_profile(user_id: str) -> UserProfile:
    """Get a user's profile"""
    async with get_db_client() as db:
        result = db.table('user_profiles').select('*').eq('user_id', user_id).execute()
        
        if not result.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User profile not found",
            )
        
        profile_data = result.data[0]
        
        return UserProfile(
            user_id=profile_data["user_id"],
            dark_mode_enabled=profile_data.get("dark_mode_enabled", False),
            gender=profile_data.get("gender"),
            age=profile_data.get("age"),
            weather_preference=profile_data.get("weather_preference"),
            notifications_enabled=profile_data.get("notifications_enabled", True),
            email_notifications_enabled=profile_data.get("email_notifications_enabled", True),
            pinterest_connected=profile_data.get("pinterest_connected", False),
            pinterest_username=profile_data.get("pinterest_username"),
            profile_image_url=profile_data.get("profile_image_url"),
            preferred_climate=profile_data.get("preferred_climate"),
            preferred_trip_type=profile_data.get("preferred_trip_type"),
            budget=profile_data.get("budget"),
            preferred_activities=profile_data.get("preferred_activities", []),
            language_preference=profile_data.get("language_preference", "en")
        )

async def update_user_profile(user_id: str, profile_update: UserProfileUpdate) -> UserProfile:
    """Update a user's profile"""
    async with get_db_client() as db:
        # Check if profile exists
        result = db.table('user_profiles').select('*').eq('user_id', user_id).execute()
        
        if not result.data:
            # Create profile if it doesn't exist
            profile_data = profile_update.model_dump(exclude_unset=True)
            profile_data["user_id"] = user_id
            
            db.table('user_profiles').insert(profile_data).execute()
        else:
            # Update existing profile
            update_data = profile_update.model_dump(exclude_unset=True)
            
            if update_data:  # Only update if there are fields to update
                db.table('user_profiles').update(update_data).eq('user_id', user_id).execute()
        
        # Get updated profile
        return await get_user_profile(user_id)

async def get_user_by_id(user_id: str) -> UserResponse:
    """Get a user by ID"""
    async with get_db_client() as db:
        result = db.table('users').select('*').eq('id', user_id).execute()
        
        if not result.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found",
            )
        
        user_data = result.data[0]
        
        return UserResponse(
            id=user_data["id"],
            email=user_data["email"],
            username=user_data["username"],
            first_name=user_data.get("first_name"),
            last_name=user_data.get("last_name"),
            created_at=datetime.fromisoformat(user_data["created_at"]),
            is_active=user_data["is_active"]
        )

async def search_users(query: str, limit: int = 10, exclude_user_id: Optional[str] = None) -> List[UserResponse]:
    """Search for users by username or name"""
    async with get_db_client() as db:
        # Search by username, first_name, or last_name
        if exclude_user_id:
            result = db.table('users').select('*').or_(
                f'username.ilike.%{query}%',
                f'first_name.ilike.%{query}%',
                f'last_name.ilike.%{query}%'
            ).neq('id', exclude_user_id).limit(limit).execute()
        else:
            result = db.table('users').select('*').or_(
                f'username.ilike.%{query}%',
                f'first_name.ilike.%{query}%', 
                f'last_name.ilike.%{query}%'
            ).limit(limit).execute()
        
        users = []
        for user_data in result.data:
            users.append(
                UserResponse(
                    id=user_data["id"],
                    email=user_data["email"],
                    username=user_data["username"],
                    first_name=user_data.get("first_name"),
                    last_name=user_data.get("last_name"),
                    created_at=datetime.fromisoformat(user_data["created_at"]),
                    is_active=user_data["is_active"]
                )
            )
        
        return users

async def get_user_friends(user_id: str) -> List[FriendResponse]:
    """Get a user's friends"""
    async with get_db_client() as db:
        # Get friends where user_id is either the user or the friend
        result = db.table('user_friends').select('*').or_(
            f'user_id.eq.{user_id}',
            f'friend_id.eq.{user_id}'
        ).execute()
        
        friends = []
        for friend_data in result.data:
            # Determine which ID is the friend's ID
            friend_id = friend_data["friend_id"] if friend_data["user_id"] == user_id else friend_data["user_id"]
            
            # Get friend's user data
            user_result = db.table('users').select('*').eq('id', friend_id).execute()
            
            if user_result.data:
                user_data = user_result.data[0]
                
                # Get profile image URL
                profile_result = db.table('user_profiles').select('profile_image_url').eq('user_id', friend_id).execute()
                profile_image_url = profile_result.data[0].get("profile_image_url") if profile_result.data else None
                
                friends.append(
                    FriendResponse(
                        id=user_data["id"],
                        username=user_data["username"],
                        first_name=user_data.get("first_name"),
                        last_name=user_data.get("last_name"),
                        profile_image_url=profile_image_url,
                        status=friend_data["status"]
                    )
                )
        
        return friends

async def add_friend(user_id: str, friend_id: str) -> Dict[str, Any]:
    """Send a friend request"""
    async with get_db_client() as db:
        # Check if friend exists
        user_result = db.table('users').select('id').eq('id', friend_id).execute()
        
        if not user_result.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found",
            )
        
        # Check if friendship already exists
        friend_result = db.table('user_friends').select('*').or_(
            f'user_id.eq.{user_id},friend_id.eq.{friend_id}',
            f'user_id.eq.{friend_id},friend_id.eq.{user_id}'
        ).execute()
        
        if friend_result.data:
            existing_status = friend_result.data[0]["status"]
            return {"message": f"Friend request already exists with status: {existing_status}"}
        
        # Create friend request
        friend_data = {
            "id": str(uuid.uuid4()),
            "user_id": user_id,
            "friend_id": friend_id,
            "status": "pending",
            "created_at": datetime.utcnow().isoformat()
        }
        
        db.table('user_friends').insert(friend_data).execute()
        
        return {"message": "Friend request sent successfully"}

async def accept_friend_request(user_id: str, friend_id: str) -> Dict[str, Any]:
    """Accept a friend request"""
    async with get_db_client() as db:
        # Find the friend request where user is the recipient
        result = db.table('user_friends').select('*').eq('user_id', friend_id).eq('friend_id', user_id).eq('status', 'pending').execute()
        
        if not result.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Friend request not found",
            )
        
        # Update status to accepted
        db.table('user_friends').update({"status": "accepted"}).eq('id', result.data[0]["id"]).execute()
        
        return {"message": "Friend request accepted"}

async def decline_friend_request(user_id: str, friend_id: str) -> Dict[str, Any]:
    """Decline a friend request"""
    async with get_db_client() as db:
        # Find the friend request where user is the recipient
        result = db.table('user_friends').select('*').eq('user_id', friend_id).eq('friend_id', user_id).eq('status', 'pending').execute()
        
        if not result.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Friend request not found",
            )
        
        # Update status to declined
        db.table('user_friends').update({"status": "declined"}).eq('id', result.data[0]["id"]).execute()
        
        return {"message": "Friend request declined"}

async def remove_friend(user_id: str, friend_id: str) -> Dict[str, Any]:
    """Remove a friend"""
    async with get_db_client() as db:
        # Find the friendship
        result = db.table('user_friends').select('*').or_(
            f'user_id.eq.{user_id},friend_id.eq.{friend_id}',
            f'user_id.eq.{friend_id},friend_id.eq.{user_id}'
        ).execute()
        
        if not result.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Friendship not found",
            )
        
        # Delete the friendship
        for friendship in result.data:
            db.table('user_friends').delete().eq('id', friendship["id"]).execute()
        
        return {"message": "Friend removed successfully"} 