from typing import List, Dict, Any, Optional
from datetime import datetime
from uuid import UUID
import asyncio

from fastapi import HTTPException, status
from models.user import UserResponse, FriendResponse
from database.connection import get_db_client

async def get_user_friends(user_id: UUID) -> List[FriendResponse]:
    """
    Get a list of user's friends
    """
    async with get_db_client() as db:
        query = """
        SELECT u.id, u.username, u.email, u.first_name, u.last_name, u.created_at
        FROM users u
        JOIN friends f ON (f.user_id = $1 AND f.friend_id = u.id) OR (f.friend_id = $1 AND f.user_id = u.id)
        WHERE f.status = 'accepted'
        """
        friends = await db.table("users").execute(query, str(user_id))
        
        return [
            {
                "id": str(friend["id"]),
                "username": friend["username"],
                "email": friend["email"],
                "first_name": friend["first_name"],
                "last_name": friend["last_name"],
                "created_at": friend["created_at"]
            }
            for friend in friends.data
        ]

async def send_friend_request(sender_id: UUID, recipient_id: UUID) -> Dict[str, Any]:
    """
    Send a friend request to another user
    """
    async with get_db_client() as db:
        # Check if users are already friends
        check_query = """
        SELECT id, status FROM friends 
        WHERE (user_id = $1 AND friend_id = $2) OR (user_id = $2 AND friend_id = $1)
        """
        existing = await db.table("friends").execute(check_query, str(sender_id), str(recipient_id))
        
        if existing.data:
            existing = existing.data[0]
            if existing["status"] == "accepted":
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Users are already friends"
                )
            elif existing["status"] == "pending":
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Friend request already exists"
                )
        
        # Check if recipient exists
        user_check = """SELECT id FROM users WHERE id = $1"""
        user = await db.table("users").execute(user_check, str(recipient_id))
        
        if not user.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        # Create friend request
        friend_data = {
            "user_id": str(sender_id),
            "friend_id": str(recipient_id),
            "status": "pending"
        }
        
        record = await db.table("friends").insert(friend_data).execute()
        
        return {
            "id": str(record.data[0]["id"]),
            "user_id": str(record.data[0]["user_id"]),
            "friend_id": str(record.data[0]["friend_id"]),
            "status": record.data[0]["status"],
            "created_at": record.data[0]["created_at"]
        }

async def accept_friend_request(user_id: UUID, request_id: UUID) -> Dict[str, Any]:
    """
    Accept a friend request
    """
    async with get_db_client() as db:
        # Check if the request exists and belongs to the user
        check_query = """
        SELECT id, user_id, friend_id, status FROM friends 
        WHERE id = $1 AND friend_id = $2 AND status = 'pending'
        """
        request = await db.table("friends").execute(check_query, str(request_id), str(user_id))
        
        if not request.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Friend request not found or already processed"
            )
        
        # Update the request status
        update_data = {"status": "accepted"}
        record = await db.table("friends").update(update_data).eq("id", str(request_id)).execute()
        
        return {
            "id": str(record.data[0]["id"]),
            "user_id": str(record.data[0]["user_id"]),
            "friend_id": str(record.data[0]["friend_id"]),
            "status": record.data[0]["status"],
            "updated_at": record.data[0]["updated_at"]
        }

async def decline_friend_request(user_id: UUID, request_id: UUID) -> Dict[str, Any]:
    """
    Decline a friend request
    """
    async with get_db_client() as db:
        # Check if the request exists and belongs to the user
        check_query = """
        SELECT id FROM friends 
        WHERE id = $1 AND friend_id = $2 AND status = 'pending'
        """
        request = await db.table("friends").execute(check_query, str(request_id), str(user_id))
        
        if not request.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Friend request not found or already processed"
            )
        
        # Delete the request
        await db.table("friends").delete().eq("id", str(request_id)).execute()
        
        return {
            "id": str(request_id),
            "status": "declined"
        }

async def remove_friend(user_id: UUID, friend_id: UUID) -> Dict[str, Any]:
    """
    Remove a friend from user's friends list
    """
    async with get_db_client() as db:
        # Check if they are friends
        check_query = """
        SELECT id FROM friends 
        WHERE ((user_id = $1 AND friend_id = $2) OR (user_id = $2 AND friend_id = $1))
        AND status = 'accepted'
        """
        friendship = await db.table("friends").execute(check_query, str(user_id), str(friend_id))
        
        if not friendship.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Friendship not found"
            )
        
        # Delete the friendship
        friendship_id = friendship.data[0]["id"]
        await db.table("friends").delete().eq("id", str(friendship_id)).execute()
        
        return {
            "user_id": str(user_id),
            "friend_id": str(friend_id),
            "status": "removed"
        }

async def get_friend_requests(user_id: UUID) -> List[Dict[str, Any]]:
    """
    Get pending friend requests for the user
    """
    async with get_db_client() as db:
        query = """
        SELECT f.id, f.user_id, f.friend_id, f.status, f.created_at,
               u.username, u.email, u.first_name, u.last_name
        FROM friends f
        JOIN users u ON f.user_id = u.id
        WHERE f.friend_id = $1 AND f.status = 'pending'
        """
        
        requests = await db.table("friends").execute(query, str(user_id))
        
        return [
            {
                "id": str(req["id"]),
                "user_id": str(req["user_id"]),
                "friend_id": str(req["friend_id"]),
                "status": req["status"],
                "created_at": req["created_at"],
                "requester": {
                    "username": req["username"],
                    "email": req["email"],
                    "first_name": req["first_name"],
                    "last_name": req["last_name"]
                }
            }
            for req in requests.data
        ]

async def get_mutual_friends(user_id: UUID, other_user_id: UUID) -> List[FriendResponse]:
    """
    Get mutual friends between two users
    """
    async with get_db_client() as db:
        # Get user1's friends
        user1_friends_query = """
        SELECT friend_id as id FROM friends 
        WHERE user_id = $1 AND status = 'accepted'
        UNION
        SELECT user_id as id FROM friends 
        WHERE friend_id = $1 AND status = 'accepted'
        """
        
        # Get user2's friends
        user2_friends_query = """
        SELECT friend_id as id FROM friends 
        WHERE user_id = $1 AND status = 'accepted'
        UNION
        SELECT user_id as id FROM friends 
        WHERE friend_id = $1 AND status = 'accepted'
        """
        
        user1_friends = await db.table("friends").execute(user1_friends_query, str(user_id))
        user2_friends = await db.table("friends").execute(user2_friends_query, str(other_user_id))
        
        user1_friend_ids = [str(f["id"]) for f in user1_friends.data]
        user2_friend_ids = [str(f["id"]) for f in user2_friends.data]
        
        # Find common friends
        mutual_ids = set(user1_friend_ids).intersection(set(user2_friend_ids))
        
        if not mutual_ids:
            return []
        
        # Get full user info for mutual friends
        mutual_friends = await db.table("users").select("*").in_("id", list(mutual_ids)).execute()
        
        return [
            {
                "id": str(friend["id"]),
                "username": friend["username"],
                "email": friend["email"],
                "first_name": friend["first_name"],
                "last_name": friend["last_name"],
                "created_at": friend["created_at"]
            }
            for friend in mutual_friends.data
        ]

async def search_users(query: str, limit: int, current_user_id: UUID) -> List[UserResponse]:
    """
    Search for users by username, email, or name
    """
    async with get_db_client() as db:
        search_pattern = f"%{query}%"
        
        # Using ilike for case-insensitive search
        users = await db.table("users").select("*") \
            .not_("id", "eq", str(current_user_id)) \
            .or_(f"username.ilike.{search_pattern},email.ilike.{search_pattern},first_name.ilike.{search_pattern},last_name.ilike.{search_pattern}") \
            .limit(limit) \
            .execute()
        
        return [
            {
                "id": str(user["id"]),
                "username": user["username"],
                "email": user["email"],
                "first_name": user["first_name"],
                "last_name": user["last_name"],
                "created_at": user["created_at"]
            }
            for user in users.data
        ]

async def get_user_profile(user_id: UUID, current_user_id: UUID) -> UserResponse:
    """
    Get user profile information
    """
    async with get_db_client() as db:
        user = await db.table("users").select("*").eq("id", str(user_id)).execute()
        
        if not user.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        user = user.data[0]
        
        # Check friendship status
        friendship = await db.table("friends").select("*") \
            .or_(f"user_id.eq.{str(current_user_id)},friend_id.eq.{str(current_user_id)}") \
            .or_(f"user_id.eq.{str(user_id)},friend_id.eq.{str(user_id)}") \
            .execute()
        
        friendship_status = None
        if friendship.data:
            friendship_status = friendship.data[0]["status"]
        
        return {
            "id": str(user["id"]),
            "username": user["username"],
            "email": user["email"],
            "first_name": user["first_name"],
            "last_name": user["last_name"],
            "created_at": user["created_at"],
            "friendship_status": friendship_status
        } 