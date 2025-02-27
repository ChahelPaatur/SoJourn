from typing import List, Optional, Dict, Any
from fastapi import HTTPException, status
import uuid
from datetime import datetime

from models.trip import TripCreate, Trip, TripUpdate, TripSummary, TripStatus, Activity
from database.connection import get_db_client

async def check_trip_access(trip_id: str, user_id: str, permission: str = "view") -> bool:
    """
    Check if the user has access to the trip.
    Permissions can be 'view', 'edit', or 'admin'
    Raises HTTP 403 if no access, returns True if access is granted
    """
    async with get_db_client() as db:
        # First check if user is the owner
        result = db.table('trips').select('owner_id').eq('id', trip_id).execute()
        
        if not result.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Trip not found"
            )
        
        owner_id = result.data[0]['owner_id']
        
        # If user is the owner, they have all permissions
        if owner_id == user_id:
            return True
            
        # If not owner, check if the trip is shared with the user
        if permission == "view":
            # For view, also check if the trip is publicly shared
            trip_result = db.table('trips').select('is_shared').eq('id', trip_id).execute()
            if trip_result.data and trip_result.data[0]['is_shared']:
                return True
                
        # Check for explicit sharing permissions
        share_result = db.table('trip_shares').select('permission').eq('trip_id', trip_id).eq('user_id', user_id).execute()
        
        if not share_result.data:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have access to this trip"
            )
            
        user_permission = share_result.data[0]['permission']
        
        # Check if user has sufficient permission
        if permission == "view" or (permission == "edit" and user_permission in ["edit", "admin"]) or (permission == "admin" and user_permission == "admin"):
            return True
            
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"You don't have {permission} permission for this trip"
        )

async def create_trip(trip_data: TripCreate, user_id: str) -> Trip:
    """Create a new trip"""
    async with get_db_client() as db:
        # Generate trip ID
        trip_id = str(uuid.uuid4())
        
        # Prepare trip data
        trip_dict = {
            "id": trip_id,
            "title": trip_data.title,
            "destination": trip_data.destination,
            "start_date": trip_data.start_date.isoformat(),
            "end_date": trip_data.end_date.isoformat(),
            "notes": trip_data.notes,
            "status": trip_data.status.value,
            "is_archived": trip_data.is_archived,
            "is_draft": trip_data.status == TripStatus.DRAFT,
            "is_shared": trip_data.is_shared,
            "owner_id": user_id,
            "created_at": datetime.utcnow().isoformat(),
            "updated_at": datetime.utcnow().isoformat(),
            "published_at": None
        }
        
        # Insert trip
        result = db.table('trips').insert(trip_dict).execute()
        
        # Insert activities if any
        if trip_data.activities:
            activities_dict = []
            for activity in trip_data.activities:
                activity_id = activity.id or str(uuid.uuid4())
                location_data = None
                
                if activity.location:
                    location_id = activity.location.id or str(uuid.uuid4())
                    location_data = {
                        "id": location_id,
                        "name": activity.location.name,
                        "address": activity.location.address,
                        "latitude": activity.location.latitude,
                        "longitude": activity.location.longitude,
                        "place_id": activity.location.place_id
                    }
                    
                    # Insert location
                    db.table('locations').insert(location_data).execute()
                
                activities_dict.append({
                    "id": activity_id,
                    "trip_id": trip_id,
                    "title": activity.title,
                    "description": activity.description,
                    "start_datetime": activity.start_datetime.isoformat(),
                    "end_datetime": activity.end_datetime.isoformat() if activity.end_datetime else None,
                    "all_day": activity.all_day,
                    "location_id": location_data["id"] if location_data else None,
                    "notes": activity.notes,
                    "activity_type": activity.activity_type.value,
                    "cost": activity.cost,
                    "currency": activity.currency,
                    "reservation_info": activity.reservation_info,
                    "weather_data": activity.weather_data.model_dump() if activity.weather_data else None,
                    "images": activity.images,
                    "created_at": activity.created_at.isoformat(),
                    "updated_at": activity.updated_at.isoformat()
                })
            
            if activities_dict:
                db.table('activities').insert(activities_dict).execute()
        
        # Return created trip
        return await get_trip_by_id(trip_id, user_id)

async def get_trip_by_id(trip_id: str, user_id: str) -> Trip:
    """Get a trip by ID"""
    async with get_db_client() as db:
        # Check if trip exists and user has access
        result = db.table('trips').select('*').eq('id', trip_id).execute()
        
        if not result.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Trip not found",
            )
        
        trip_data = result.data[0]
        
        # Check if user is owner or has access
        if trip_data["owner_id"] != user_id:
            # Check if trip is shared with user
            share_result = db.table('trip_shares').select('*').eq('trip_id', trip_id).eq('user_id', user_id).execute()
            
            if not share_result.data:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="You don't have access to this trip",
                )
        
        # Get activities
        activities_result = db.table('activities').select('*').eq('trip_id', trip_id).execute()
        activities = []
        
        for activity_data in activities_result.data:
            location = None
            
            # Get location if exists
            if activity_data.get("location_id"):
                location_result = db.table('locations').select('*').eq('id', activity_data["location_id"]).execute()
                
                if location_result.data:
                    location_data = location_result.data[0]
                    location = {
                        "id": location_data["id"],
                        "name": location_data["name"],
                        "address": location_data.get("address"),
                        "latitude": location_data.get("latitude"),
                        "longitude": location_data.get("longitude"),
                        "place_id": location_data.get("place_id")
                    }
            
            # Create activity
            activity = {
                "id": activity_data["id"],
                "title": activity_data["title"],
                "description": activity_data.get("description"),
                "start_datetime": datetime.fromisoformat(activity_data["start_datetime"]),
                "end_datetime": datetime.fromisoformat(activity_data["end_datetime"]) if activity_data.get("end_datetime") else None,
                "all_day": activity_data.get("all_day", False),
                "location": location,
                "notes": activity_data.get("notes"),
                "activity_type": activity_data.get("activity_type", "other"),
                "cost": activity_data.get("cost"),
                "currency": activity_data.get("currency", "USD"),
                "reservation_info": activity_data.get("reservation_info"),
                "weather_data": activity_data.get("weather_data"),
                "images": activity_data.get("images", []),
                "created_at": datetime.fromisoformat(activity_data["created_at"]),
                "updated_at": datetime.fromisoformat(activity_data["updated_at"])
            }
            
            activities.append(activity)
        
        # Create trip
        trip = {
            "id": trip_data["id"],
            "title": trip_data["title"],
            "destination": trip_data["destination"],
            "start_date": datetime.fromisoformat(trip_data["start_date"]),
            "end_date": datetime.fromisoformat(trip_data["end_date"]),
            "notes": trip_data.get("notes"),
            "status": trip_data["status"],
            "is_archived": trip_data.get("is_archived", False),
            "is_draft": trip_data.get("is_draft", False),
            "is_shared": trip_data.get("is_shared", False),
            "owner_id": trip_data["owner_id"],
            "activities": activities,
            "created_at": datetime.fromisoformat(trip_data["created_at"]),
            "updated_at": datetime.fromisoformat(trip_data["updated_at"]),
            "published_at": datetime.fromisoformat(trip_data["published_at"]) if trip_data.get("published_at") else None
        }
        
        return Trip(**trip)

async def update_trip(trip_id: str, trip_update: TripUpdate, user_id: str) -> Trip:
    """Update a trip"""
    async with get_db_client() as db:
        # Check if trip exists and user has access
        result = db.table('trips').select('*').eq('id', trip_id).execute()
        
        if not result.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Trip not found",
            )
        
        trip_data = result.data[0]
        
        # Check if user is owner
        if trip_data["owner_id"] != user_id:
            # Check if user has edit permission
            share_result = db.table('trip_shares').select('*').eq('trip_id', trip_id).eq('user_id', user_id).execute()
            
            if not share_result.data or share_result.data[0]["permission"] not in ["edit", "admin"]:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="You don't have permission to update this trip",
                )
        
        # Update trip
        update_data = trip_update.model_dump(exclude_unset=True)
        
        if "start_date" in update_data:
            update_data["start_date"] = update_data["start_date"].isoformat()
        
        if "end_date" in update_data:
            update_data["end_date"] = update_data["end_date"].isoformat()
        
        if "status" in update_data:
            update_data["status"] = update_data["status"].value
            # Update is_draft if status is changed
            update_data["is_draft"] = update_data["status"] == TripStatus.DRAFT.value
        
        update_data["updated_at"] = datetime.utcnow().isoformat()
        
        db.table('trips').update(update_data).eq('id', trip_id).execute()
        
        # Return updated trip
        return await get_trip_by_id(trip_id, user_id)

async def delete_trip(trip_id: str, user_id: str) -> Dict[str, Any]:
    """Delete a trip"""
    async with get_db_client() as db:
        # Check if trip exists and user has access
        result = db.table('trips').select('*').eq('id', trip_id).execute()
        
        if not result.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Trip not found",
            )
        
        trip_data = result.data[0]
        
        # Check if user is owner
        if trip_data["owner_id"] != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only the owner can delete this trip",
            )
        
        # Delete trip shares
        db.table('trip_shares').delete().eq('trip_id', trip_id).execute()
        
        # Delete activities
        activities_result = db.table('activities').select('id', 'location_id').eq('trip_id', trip_id).execute()
        
        for activity_data in activities_result.data:
            # Delete location if exists
            if activity_data.get("location_id"):
                db.table('locations').delete().eq('id', activity_data["location_id"]).execute()
        
        db.table('activities').delete().eq('trip_id', trip_id).execute()
        
        # Delete trip
        db.table('trips').delete().eq('id', trip_id).execute()
        
        return {"message": "Trip deleted successfully"}

async def get_user_trips(
    user_id: str, 
    status: Optional[str] = None, 
    archived: Optional[bool] = None, 
    shared: Optional[bool] = None, 
    limit: int = 10, 
    offset: int = 0
) -> List[TripSummary]:
    """Get a user's trips with filters"""
    async with get_db_client() as db:
        # Build query for owned trips
        query = db.table('trips').select('*').eq('owner_id', user_id)
        
        # Apply filters to query
        if status:
            query = query.eq('status', status)
        
        if archived is not None:
            query = query.eq('is_archived', archived)
        
        if shared is not None:
            query = query.eq('is_shared', shared)
        
        # Execute query
        result = query.order('created_at', desc=True).limit(limit).offset(offset).execute()
        
        # Get shared trips
        shared_trips_result = db.table('trip_shares').select('trip_id').eq('user_id', user_id).execute()
        shared_trip_ids = [item["trip_id"] for item in shared_trips_result.data]
        
        shared_trips = []
        if shared_trip_ids:
            # Get the actual trip data for shared trips
            for trip_id in shared_trip_ids:
                shared_trip = db.table('trips').select('*').eq('id', trip_id).execute()
                if shared_trip.data:
                    shared_trips.extend(shared_trip.data)
        
        # Combine owned and shared trips
        all_trips = result.data + shared_trips
        
        # Format trips as TripSummary
        trips = []
        for trip_data in all_trips:
            # Get activity count
            activity_count_result = db.table('activities').select('id', count='exact').eq('trip_id', trip_data["id"]).execute()
            activity_count = activity_count_result.count
            
            # Get cover image if any
            cover_image_url = None
            image_result = db.table('trip_images').select('url').eq('trip_id', trip_data["id"]).is_('activity_id', 'null').limit(1).execute()
            
            if image_result.data:
                cover_image_url = image_result.data[0]["url"]
            
            # Create trip summary
            trip_summary = TripSummary(
                id=trip_data["id"],
                title=trip_data["title"],
                destination=trip_data["destination"],
                start_date=datetime.fromisoformat(trip_data["start_date"]),
                end_date=datetime.fromisoformat(trip_data["end_date"]),
                status=trip_data["status"],
                is_archived=trip_data.get("is_archived", False),
                is_draft=trip_data.get("is_draft", False),
                is_shared=trip_data.get("is_shared", False),
                activity_count=activity_count,
                cover_image_url=cover_image_url
            )
            
            trips.append(trip_summary)
        
        return trips

async def publish_trip(trip_id: str, user_id: str) -> Trip:
    """Publish a draft trip"""
    async with get_db_client() as db:
        # Check if trip exists and user has access
        result = db.table('trips').select('*').eq('id', trip_id).execute()
        
        if not result.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Trip not found",
            )
        
        trip_data = result.data[0]
        
        # Check if user is owner
        if trip_data["owner_id"] != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only the owner can publish this trip",
            )
        
        # Check if trip is a draft
        if not trip_data.get("is_draft", False):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Trip is already published",
            )
        
        # Update trip status
        now = datetime.utcnow().isoformat()
        db.table('trips').update({
            "status": TripStatus.UPCOMING.value,
            "is_draft": False,
            "published_at": now,
            "updated_at": now
        }).eq('id', trip_id).execute()
        
        # Return updated trip
        return await get_trip_by_id(trip_id, user_id)

async def archive_trip(trip_id: str, user_id: str) -> Dict[str, Any]:
    """Archive a trip"""
    async with get_db_client() as db:
        # Check if trip exists and user has access
        result = db.table('trips').select('*').eq('id', trip_id).execute()
        
        if not result.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Trip not found",
            )
        
        trip_data = result.data[0]
        
        # Check if user is owner
        if trip_data["owner_id"] != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only the owner can archive this trip",
            )
        
        # Update trip
        now = datetime.utcnow().isoformat()
        db.table('trips').update({
            "is_archived": True,
            "updated_at": now
        }).eq('id', trip_id).execute()
        
        return {"message": "Trip archived successfully"}

async def unarchive_trip(trip_id: str, user_id: str) -> Dict[str, Any]:
    """Unarchive a trip"""
    async with get_db_client() as db:
        # Check if trip exists and user has access
        result = db.table('trips').select('*').eq('id', trip_id).execute()
        
        if not result.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Trip not found",
            )
        
        trip_data = result.data[0]
        
        # Check if user is owner
        if trip_data["owner_id"] != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only the owner can unarchive this trip",
            )
        
        # Update trip
        now = datetime.utcnow().isoformat()
        db.table('trips').update({
            "is_archived": False,
            "updated_at": now
        }).eq('id', trip_id).execute()
        
        return {"message": "Trip unarchived successfully"}

async def share_trip(trip_id: str, shared_user_id: str, permission: str, user_id: str) -> Dict[str, Any]:
    """Share a trip with another user"""
    async with get_db_client() as db:
        # Check if trip exists and user has access
        result = db.table('trips').select('*').eq('id', trip_id).execute()
        
        if not result.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Trip not found",
            )
        
        trip_data = result.data[0]
        
        # Check if user is owner
        if trip_data["owner_id"] != user_id:
            # Check if user has admin permission
            share_result = db.table('trip_shares').select('*').eq('trip_id', trip_id).eq('user_id', user_id).execute()
            
            if not share_result.data or share_result.data[0]["permission"] != "admin":
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="You don't have permission to share this trip",
                )
        
        # Check if user exists
        user_result = db.table('users').select('id').eq('id', shared_user_id).execute()
        
        if not user_result.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found",
            )
        
        # Check if sharing with self
        if shared_user_id == user_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="You cannot share a trip with yourself",
            )
        
        # Check if sharing with owner
        if shared_user_id == trip_data["owner_id"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="You cannot share a trip with its owner",
            )
        
        # Check if already shared
        share_result = db.table('trip_shares').select('*').eq('trip_id', trip_id).eq('user_id', shared_user_id).execute()
        
        if share_result.data:
            # Update permission if changed
            if share_result.data[0]["permission"] != permission:
                db.table('trip_shares').update({
                    "permission": permission
                }).eq('id', share_result.data[0]["id"]).execute()
                
                return {"message": f"Trip share permission updated to {permission}"}
            else:
                return {"message": "Trip is already shared with this user"}
        
        # Create share
        share_data = {
            "id": str(uuid.uuid4()),
            "trip_id": trip_id,
            "user_id": shared_user_id,
            "permission": permission,
            "created_at": datetime.utcnow().isoformat(),
            "created_by": user_id
        }
        
        db.table('trip_shares').insert(share_data).execute()
        
        # Update trip shared status
        db.table('trips').update({
            "is_shared": True,
            "updated_at": datetime.utcnow().isoformat()
        }).eq('id', trip_id).execute()
        
        return {"message": f"Trip shared successfully with permission: {permission}"}

async def get_trip_shares(trip_id: str, user_id: str) -> List[Dict[str, Any]]:
    """Get users with whom a trip is shared"""
    async with get_db_client() as db:
        # Check if trip exists and user has access
        result = db.table('trips').select('*').eq('id', trip_id).execute()
        
        if not result.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Trip not found",
            )
        
        trip_data = result.data[0]
        
        # Check if user is owner or has access
        if trip_data["owner_id"] != user_id:
            # Check if user has access
            share_result = db.table('trip_shares').select('*').eq('trip_id', trip_id).eq('user_id', user_id).execute()
            
            if not share_result.data:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="You don't have access to this trip",
                )
        
        # Get shares
        shares_result = db.table('trip_shares').select('*').eq('trip_id', trip_id).execute()
        
        shares = []
        for share_data in shares_result.data:
            # Get user info
            user_result = db.table('users').select('username', 'first_name', 'last_name', 'email').eq('id', share_data["user_id"]).execute()
            
            if user_result.data:
                user_data = user_result.data[0]
                
                # Get profile image URL
                profile_result = db.table('user_profiles').select('profile_image_url').eq('user_id', share_data["user_id"]).execute()
                profile_image_url = profile_result.data[0].get("profile_image_url") if profile_result.data else None
                
                shares.append({
                    "id": share_data["id"],
                    "user_id": share_data["user_id"],
                    "username": user_data["username"],
                    "first_name": user_data.get("first_name"),
                    "last_name": user_data.get("last_name"),
                    "email": user_data["email"],
                    "profile_image_url": profile_image_url,
                    "permission": share_data["permission"],
                    "created_at": share_data["created_at"]
                })
        
        return shares

async def remove_trip_share(trip_id: str, shared_user_id: str, user_id: str) -> Dict[str, Any]:
    """Remove a user's access to a shared trip"""
    async with get_db_client() as db:
        # Check if trip exists and user has access
        result = db.table('trips').select('*').eq('id', trip_id).execute()
        
        if not result.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Trip not found",
            )
        
        trip_data = result.data[0]
        
        # Check if user is owner
        if trip_data["owner_id"] != user_id:
            # Check if user has admin permission
            share_result = db.table('trip_shares').select('*').eq('trip_id', trip_id).eq('user_id', user_id).execute()
            
            if not share_result.data or share_result.data[0]["permission"] != "admin":
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="You don't have permission to remove access to this trip",
                )
        
        # Check if share exists
        share_result = db.table('trip_shares').select('*').eq('trip_id', trip_id).eq('user_id', shared_user_id).execute()
        
        if not share_result.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Trip is not shared with this user",
            )
        
        # Delete share
        db.table('trip_shares').delete().eq('id', share_result.data[0]["id"]).execute()
        
        # Check if trip still has shares
        shares_result = db.table('trip_shares').select('id', count='exact').eq('trip_id', trip_id).execute()
        
        if shares_result.count == 0:
            # Update trip shared status
            db.table('trips').update({
                "is_shared": False,
                "updated_at": datetime.utcnow().isoformat()
            }).eq('id', trip_id).execute()
        
        return {"message": "Access removed successfully"} 