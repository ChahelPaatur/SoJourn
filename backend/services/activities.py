from datetime import datetime
from typing import List, Dict, Any, Optional
from fastapi import HTTPException, status
import uuid

from models.trip import Activity, ActivityType
from database.connection import get_db_client
from services.trips import check_trip_access

async def create_activity(activity: Activity, trip_id: str, user_id: str) -> Activity:
    """
    Create a new activity for a trip
    """
    # Check trip access
    await check_trip_access(trip_id, user_id)
    
    async with get_db_client() as db:
        # Generate activity ID if not provided
        if not activity.id:
            activity.id = str(uuid.uuid4())
        
        # Set timestamps
        now = datetime.utcnow()
        activity.created_at = now
        activity.updated_at = now
        
        # Convert model to dict
        activity_dict = activity.model_dump()
        
        # Handle nested location object
        if activity.location:
            location_dict = activity.location.model_dump()
            activity_dict.pop("location", None)
            activity_dict["location_id"] = location_dict["id"]
            
            # Insert or update location
            if not await location_exists(location_dict["id"]):
                db.table('locations').insert(location_dict).execute()
            else:
                db.table('locations').update(location_dict).eq('id', location_dict["id"]).execute()
        
        # Handle weather data
        if activity.weather_data:
            weather_dict = activity.weather_data.model_dump()
            activity_dict.pop("weather_data", None)
            
            # Add activity ID to weather data
            weather_dict["activity_id"] = activity.id
            
            # Insert weather data
            db.table('activity_weather').insert(weather_dict).execute()
        
        # Convert activity type enum to string
        activity_dict["activity_type"] = activity_dict["activity_type"].value if isinstance(activity_dict["activity_type"], ActivityType) else activity_dict["activity_type"]
        
        # Add trip ID
        activity_dict["trip_id"] = trip_id
        
        # Insert activity
        result = db.table('activities').insert(activity_dict).execute()
        
        # Process activity images
        if activity.images:
            image_records = []
            for image_url in activity.images:
                image_records.append({
                    "id": str(uuid.uuid4()),
                    "trip_id": trip_id,
                    "activity_id": activity.id,
                    "url": image_url,
                    "created_at": now.isoformat()
                })
            
            if image_records:
                db.table('trip_images').insert(image_records).execute()
        
        # Return the created activity with all related data
        return await get_activity_by_id(activity.id, user_id)

async def get_activity_by_id(activity_id: str, user_id: str) -> Activity:
    """
    Get an activity by ID
    """
    async with get_db_client() as db:
        # Get activity
        result = db.table('activities').select('*').eq('id', activity_id).execute()
        
        if not result.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Activity not found"
            )
        
        activity_data = result.data[0]
        
        # Check trip access
        await check_trip_access(activity_data["trip_id"], user_id)
        
        # Get location if available
        location = None
        if activity_data.get("location_id"):
            location_result = db.table('locations').select('*').eq('id', activity_data["location_id"]).execute()
            if location_result.data:
                location = location_result.data[0]
        
        # Get weather data if available
        weather_data = None
        weather_result = db.table('activity_weather').select('*').eq('activity_id', activity_id).execute()
        if weather_result.data:
            weather_data = weather_result.data[0]
        
        # Get images
        images = []
        image_result = db.table('trip_images').select('url').eq('activity_id', activity_id).execute()
        if image_result.data:
            images = [img["url"] for img in image_result.data]
        
        # Reconstruct full activity with related data
        return construct_activity_from_data(activity_data, location, weather_data, images)

async def update_activity(activity_id: str, activity_update: Activity, user_id: str) -> Activity:
    """
    Update an activity
    """
    async with get_db_client() as db:
        # Get existing activity
        result = db.table('activities').select('*').eq('id', activity_id).execute()
        
        if not result.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Activity not found"
            )
        
        existing_activity = result.data[0]
        
        # Check trip access
        await check_trip_access(existing_activity["trip_id"], user_id)
        
        # Update activity fields
        activity_update.id = activity_id
        activity_update.updated_at = datetime.utcnow()
        
        # Convert model to dict
        activity_dict = activity_update.model_dump(exclude={"location", "weather_data", "images"})
        
        # Convert activity type enum to string
        activity_dict["activity_type"] = activity_dict["activity_type"].value if isinstance(activity_dict["activity_type"], ActivityType) else activity_dict["activity_type"]
        
        # Handle location update
        if activity_update.location:
            location_dict = activity_update.location.model_dump()
            activity_dict["location_id"] = location_dict["id"]
            
            # Upsert location
            if not await location_exists(location_dict["id"]):
                db.table('locations').insert(location_dict).execute()
            else:
                db.table('locations').update(location_dict).eq('id', location_dict["id"]).execute()
        
        # Update activity
        db.table('activities').update(activity_dict).eq('id', activity_id).execute()
        
        # Handle weather data update
        if activity_update.weather_data:
            weather_dict = activity_update.weather_data.model_dump()
            
            # Try to update existing weather data
            weather_result = db.table('activity_weather').select('*').eq('activity_id', activity_id).execute()
            
            if weather_result.data:
                db.table('activity_weather').update(weather_dict).eq('activity_id', activity_id).execute()
            else:
                # Add activity ID to weather data
                weather_dict["activity_id"] = activity_id
                
                # Insert weather data
                db.table('activity_weather').insert(weather_dict).execute()
        
        # Update images if provided
        if activity_update.images:
            # Delete existing images
            db.table('trip_images').delete().eq('activity_id', activity_id).execute()
            
            # Add new images
            image_records = []
            for image_url in activity_update.images:
                image_records.append({
                    "id": str(uuid.uuid4()),
                    "trip_id": existing_activity["trip_id"],
                    "activity_id": activity_id,
                    "url": image_url,
                    "created_at": datetime.utcnow().isoformat()
                })
            
            if image_records:
                db.table('trip_images').insert(image_records).execute()
        
        # Return the updated activity
        return await get_activity_by_id(activity_id, user_id)

async def delete_activity(activity_id: str, user_id: str) -> Dict[str, Any]:
    """
    Delete an activity
    """
    async with get_db_client() as db:
        # Get activity to check trip access
        result = db.table('activities').select('*').eq('id', activity_id).execute()
        
        if not result.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Activity not found"
            )
        
        existing_activity = result.data[0]
        
        # Check trip access
        await check_trip_access(existing_activity["trip_id"], user_id)
        
        # Delete related data
        db.table('trip_images').delete().eq('activity_id', activity_id).execute()
        db.table('activity_weather').delete().eq('activity_id', activity_id).execute()
        
        # Delete activity
        db.table('activities').delete().eq('id', activity_id).execute()
        
        return {"message": "Activity deleted successfully"}

async def get_trip_activities(
    trip_id: str, 
    date: Optional[str] = None, 
    activity_type: Optional[str] = None,
    user_id: str = None
) -> List[Activity]:
    """
    Get all activities for a trip with optional filters
    """
    # Check trip access
    await check_trip_access(trip_id, user_id)
    
    async with get_db_client() as db:
        # Base query
        query = db.table('activities').select('*').eq('trip_id', trip_id)
        
        # Apply date filter if provided
        if date:
            try:
                filter_date = datetime.fromisoformat(date).date()
                # Filter activities that occur on the given date
                # This is a simplified implementation - in a real system, need to handle
                # filtering based on start_datetime and end_datetime relationship
                query = query.like('start_datetime', f'{filter_date.isoformat()}%')
            except ValueError:
                # Ignore invalid date format
                pass
        
        # Apply activity type filter if provided
        if activity_type:
            query = query.eq('activity_type', activity_type)
        
        # Execute query
        result = query.execute()
        
        activities = []
        
        # Process results
        for activity_data in result.data:
            # Get location if available
            location = None
            if activity_data.get("location_id"):
                location_result = db.table('locations').select('*').eq('id', activity_data["location_id"]).execute()
                if location_result.data:
                    location = location_result.data[0]
            
            # Get weather data if available
            weather_data = None
            weather_result = db.table('activity_weather').select('*').eq('activity_id', activity_data["id"]).execute()
            if weather_result.data:
                weather_data = weather_result.data[0]
            
            # Get images
            images = []
            image_result = db.table('trip_images').select('url').eq('activity_id', activity_data["id"]).execute()
            if image_result.data:
                images = [img["url"] for img in image_result.data]
            
            # Create activity object
            activity = construct_activity_from_data(activity_data, location, weather_data, images)
            activities.append(activity)
        
        return activities

async def location_exists(location_id: str) -> bool:
    """
    Check if a location exists
    """
    async with get_db_client() as db:
        result = db.table('locations').select('id').eq('id', location_id).execute()
        return len(result.data) > 0

def construct_activity_from_data(
    activity_data: Dict[str, Any],
    location_data: Optional[Dict[str, Any]],
    weather_data: Optional[Dict[str, Any]],
    images: List[str]
) -> Activity:
    """
    Construct an Activity object from database data
    """
    from models.trip import Location, WeatherData
    
    # Create location object if available
    location = None
    if location_data:
        location = Location(
            id=location_data["id"],
            name=location_data["name"],
            address=location_data.get("address"),
            latitude=location_data.get("latitude"),
            longitude=location_data.get("longitude"),
            place_id=location_data.get("place_id")
        )
    
    # Create weather data object if available
    weather = None
    if weather_data:
        weather = WeatherData(
            temperature=weather_data.get("temperature"),
            temperature_min=weather_data.get("temperature_min"),
            temperature_max=weather_data.get("temperature_max"),
            condition=weather_data.get("condition"),
            precipitation_probability=weather_data.get("precipitation_probability"),
            humidity=weather_data.get("humidity"),
            wind_speed=weather_data.get("wind_speed"),
            wind_direction=weather_data.get("wind_direction"),
            cloud_cover=weather_data.get("cloud_cover"),
            sunrise=weather_data.get("sunrise"),
            sunset=weather_data.get("sunset"),
            forecast_timestamp=weather_data.get("forecast_timestamp")
        )
    
    # Parse datetime fields
    start_datetime = activity_data["start_datetime"]
    if isinstance(start_datetime, str):
        start_datetime = datetime.fromisoformat(start_datetime)
    
    end_datetime = activity_data.get("end_datetime")
    if end_datetime and isinstance(end_datetime, str):
        end_datetime = datetime.fromisoformat(end_datetime)
    
    created_at = activity_data["created_at"]
    if isinstance(created_at, str):
        created_at = datetime.fromisoformat(created_at)
    
    updated_at = activity_data["updated_at"]
    if isinstance(updated_at, str):
        updated_at = datetime.fromisoformat(updated_at)
    
    # Create activity object
    activity = Activity(
        id=activity_data["id"],
        title=activity_data["title"],
        description=activity_data.get("description"),
        start_datetime=start_datetime,
        end_datetime=end_datetime,
        all_day=activity_data.get("all_day", False),
        location=location,
        notes=activity_data.get("notes"),
        activity_type=activity_data.get("activity_type", "other"),
        cost=activity_data.get("cost"),
        currency=activity_data.get("currency", "USD"),
        reservation_info=activity_data.get("reservation_info"),
        weather_data=weather,
        images=images,
        created_at=created_at,
        updated_at=updated_at
    )
    
    return activity 