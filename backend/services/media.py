from typing import List, Dict, Any, Optional, BinaryIO
from datetime import datetime
from uuid import UUID, uuid4
import os
from fastapi import HTTPException, status, UploadFile
import asyncio
import aiofiles
from PIL import Image
from io import BytesIO

from config.settings import settings
from database.connection import get_db_client

async def upload_media_file(
    user_id: UUID, 
    file: UploadFile,
    title: Optional[str],
    description: Optional[str],
    media_type: str
) -> Dict[str, Any]:
    """
    Upload a media file (image, video, audio) and save to storage
    
    Args:
        user_id: ID of the user uploading the file
        file: The uploaded file
        title: Optional title for the media
        description: Optional description for the media
        media_type: Type of media (image, video, audio, etc.)
    
    Returns:
        Dict containing the media information including URL
    """
    # Validate media type
    valid_media_types = ["image", "video", "audio", "document"]
    if media_type not in valid_media_types:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid media type. Must be one of: {', '.join(valid_media_types)}"
        )
    
    # Generate unique ID for the file
    file_id = str(uuid4())
    
    # Get file extension
    file_extension = os.path.splitext(file.filename)[1].lower()
    
    # Create storage path
    storage_path = f"media/{media_type}/{user_id}/{file_id}{file_extension}"
    
    # Read file content
    content = await file.read()
    
    # For images, create a thumbnail
    thumbnail_url = None
    if media_type == "image":
        try:
            # Create thumbnail
            img = Image.open(BytesIO(content))
            img.thumbnail((200, 200))
            thumbnail_buffer = BytesIO()
            img.save(thumbnail_buffer, format=img.format)
            thumbnail_buffer.seek(0)
            
            # Save thumbnail
            thumbnail_path = f"media/{media_type}/{user_id}/thumbnails/{file_id}{file_extension}"
            thumbnail_url = await save_file_to_storage(thumbnail_path, thumbnail_buffer.read())
        except Exception as e:
            print(f"Error creating thumbnail: {str(e)}")
    
    # Save file to storage
    file_url = await save_file_to_storage(storage_path, content)
    
    # Reset file pointer for potential further processing
    await file.seek(0)
    
    # Get file size
    content_length = len(content)
    
    # Save media record in database
    async with get_db_client() as db:
        media_data = {
            "id": file_id,
            "user_id": str(user_id),
            "title": title or file.filename,
            "description": description,
            "file_name": file.filename,
            "file_size": content_length,
            "file_type": file.content_type,
            "media_type": media_type,
            "url": file_url,
            "thumbnail_url": thumbnail_url,
            "status": "active"
        }
        
        record = await db.table("media").insert(media_data).execute()
        
        return record.data[0]

async def get_user_media(
    user_id: UUID,
    media_type: Optional[str] = None,
    skip: int = 0,
    limit: int = 20
) -> List[Dict[str, Any]]:
    """
    Get a user's media files with optional filtering by type
    
    Args:
        user_id: ID of the user
        media_type: Optional type to filter by
        skip: Number of records to skip for pagination
        limit: Maximum number of records to return
    
    Returns:
        List of media items
    """
    async with get_db_client() as db:
        query = db.table("media").select("*").eq("user_id", str(user_id))
        
        if media_type:
            query = query.eq("media_type", media_type)
        
        # Add pagination
        query = query.range(skip, skip + limit - 1)
        
        # Add ordering by most recent first
        query = query.order("created_at", desc=True)
        
        result = await query.execute()
        
        return result.data

async def get_media_details(media_id: UUID, user_id: UUID) -> Dict[str, Any]:
    """
    Get detailed information about a specific media file
    
    Args:
        media_id: ID of the media to retrieve
        user_id: ID of the user making the request
    
    Returns:
        Media details
    """
    async with get_db_client() as db:
        # Get media record
        media = await db.table("media").select("*").eq("id", str(media_id)).execute()
        
        if not media.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Media not found"
            )
        
        media_item = media.data[0]
        
        # Check if user has access (owner)
        if media_item["user_id"] != str(user_id):
            # In a real app, you might check for shared access here
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have permission to access this media"
            )
        
        return media_item

async def delete_media(media_id: UUID, user_id: UUID) -> Dict[str, Any]:
    """
    Delete a media file
    
    Args:
        media_id: ID of the media to delete
        user_id: ID of the user making the request
    
    Returns:
        Status information
    """
    async with get_db_client() as db:
        # Get media record
        media = await db.table("media").select("*").eq("id", str(media_id)).execute()
        
        if not media.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Media not found"
            )
        
        media_item = media.data[0]
        
        # Check if user has access (owner)
        if media_item["user_id"] != str(user_id):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have permission to delete this media"
            )
        
        # Delete file from storage
        if media_item["url"]:
            await delete_file_from_storage(media_item["url"])
        
        # Delete thumbnail if exists
        if media_item.get("thumbnail_url"):
            await delete_file_from_storage(media_item["thumbnail_url"])
        
        # Delete database record
        await db.table("media").delete().eq("id", str(media_id)).execute()
        
        return {"status": "success", "message": "Media deleted successfully"}

async def save_file_to_storage(path: str, content: bytes) -> str:
    """
    Save a file to storage and return the URL
    
    This implementation uses Supabase Storage
    
    Args:
        path: Path where the file will be stored
        content: File content as bytes
    
    Returns:
        URL to the stored file
    """
    bucket_name = "media"
    
    try:
        async with get_db_client() as db:
            # Make sure bucket exists
            # Note: In a real implementation, you'd check if the bucket exists first
            
            # Upload the file
            # In a real implementation with Supabase:
            # await supabase.storage.from_(bucket_name).upload(path, content)
            
            # For now, simulate file storage and return a mock URL
            file_url = f"{settings.STORAGE_URL}/{bucket_name}/{path}"
            
            return file_url
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error saving file to storage: {str(e)}"
        )

async def delete_file_from_storage(url: str) -> None:
    """
    Delete a file from storage using its URL
    
    Args:
        url: URL of the file to delete
    """
    try:
        # Extract path from URL
        # Example URL: https://storage.example.com/bucket/path/to/file.jpg
        path = url.split("/media/", 1)[1] if "/media/" in url else None
        
        if not path:
            return
        
        async with get_db_client() as db:
            # In a real implementation with Supabase:
            # await supabase.storage.from_("media").remove(path)
            pass
    except Exception as e:
        # Log the error but don't raise an exception
        print(f"Error deleting file from storage: {str(e)}")
        
        # In a production environment, you might want to:
        # 1. Log this to a proper logging service
        # 2. Add a record to a cleanup queue for later processing 