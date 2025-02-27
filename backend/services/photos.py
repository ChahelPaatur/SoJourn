from datetime import datetime
from typing import Dict, Any, List, Optional, BinaryIO
import jwt
import time
import httpx
import uuid
import os
from fastapi import HTTPException, status, UploadFile, File
from io import BytesIO
from PIL import Image

from config.settings import settings
from database.connection import get_db_client

async def upload_trip_image(
    trip_id: str, 
    activity_id: Optional[str], 
    image_file: UploadFile, 
    caption: Optional[str] = None,
    user_id: str = None
) -> Dict[str, Any]:
    """
    Upload and save an image for a trip or activity
    """
    from services.trips import check_trip_access
    
    # Check trip access
    await check_trip_access(trip_id, user_id)
    
    try:
        # Read file content
        content = await image_file.read()
        
        # Process image: resize and optimize
        processed_image, thumbnail = await process_image(content)
        
        # Generate unique ID for the image
        image_id = str(uuid.uuid4())
        
        # Get image extension
        file_ext = os.path.splitext(image_file.filename)[1].lower()
        if not file_ext:
            file_ext = ".jpg"  # Default to jpg if no extension
        
        # Format filename
        filename = f"{image_id}{file_ext}"
        thumbnail_filename = f"{image_id}_thumb{file_ext}"
        
        # Save to storage and get URLs
        image_url = await save_image_to_storage(processed_image, filename, trip_id)
        thumbnail_url = await save_image_to_storage(thumbnail, thumbnail_filename, trip_id)
        
        # Save metadata to database
        async with get_db_client() as db:
            image_data = {
                "id": image_id,
                "trip_id": trip_id,
                "activity_id": activity_id,
                "url": image_url,
                "thumbnail_url": thumbnail_url,
                "caption": caption,
                "created_at": datetime.utcnow().isoformat(),
                "metadata": {
                    "original_filename": image_file.filename,
                    "content_type": image_file.content_type,
                    "size": len(content)
                }
            }
            
            result = db.table('trip_images').insert(image_data).execute()
        
        return {
            "id": image_id,
            "url": image_url,
            "thumbnail_url": thumbnail_url,
            "caption": caption
        }
        
    except Exception as e:
        print(f"Error uploading image: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error uploading image: {str(e)}"
        )

async def get_trip_images(
    trip_id: str, 
    activity_id: Optional[str] = None,
    user_id: str = None
) -> List[Dict[str, Any]]:
    """
    Get images for a trip or activity
    """
    from services.trips import check_trip_access
    
    # Check trip access
    await check_trip_access(trip_id, user_id)
    
    async with get_db_client() as db:
        # Base query
        query = db.table('trip_images').select('*').eq('trip_id', trip_id)
        
        # Filter by activity if provided
        if activity_id:
            query = query.eq('activity_id', activity_id)
        
        # Execute query
        result = query.execute()
        
        # Format results
        images = []
        for img in result.data:
            images.append({
                "id": img["id"],
                "url": img["url"],
                "thumbnail_url": img.get("thumbnail_url"),
                "caption": img.get("caption"),
                "created_at": img["created_at"],
                "activity_id": img.get("activity_id")
            })
        
        return images

async def delete_image(image_id: str, user_id: str) -> Dict[str, Any]:
    """
    Delete an image
    """
    from services.trips import check_trip_access
    
    async with get_db_client() as db:
        # Get image data
        result = db.table('trip_images').select('*').eq('id', image_id).execute()
        
        if not result.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Image not found"
            )
        
        image_data = result.data[0]
        
        # Check trip access
        await check_trip_access(image_data["trip_id"], user_id)
        
        # Delete the image from storage
        await delete_image_from_storage(image_data["url"])
        
        # Delete thumbnail if exists
        if image_data.get("thumbnail_url"):
            await delete_image_from_storage(image_data["thumbnail_url"])
        
        # Delete from database
        db.table('trip_images').delete().eq('id', image_id).execute()
        
        return {"message": "Image deleted successfully"}

async def update_image_caption(
    image_id: str, 
    caption: str,
    user_id: str
) -> Dict[str, Any]:
    """
    Update the caption of an image
    """
    from services.trips import check_trip_access
    
    async with get_db_client() as db:
        # Get image data
        result = db.table('trip_images').select('*').eq('id', image_id).execute()
        
        if not result.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Image not found"
            )
        
        image_data = result.data[0]
        
        # Check trip access
        await check_trip_access(image_data["trip_id"], user_id)
        
        # Update caption
        db.table('trip_images').update({"caption": caption}).eq('id', image_id).execute()
        
        # Return updated image data
        updated_result = db.table('trip_images').select('*').eq('id', image_id).execute()
        
        if not updated_result.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Image not found after update"
            )
        
        updated_image = updated_result.data[0]
        
        return {
            "id": updated_image["id"],
            "url": updated_image["url"],
            "thumbnail_url": updated_image.get("thumbnail_url"),
            "caption": updated_image.get("caption"),
            "created_at": updated_image["created_at"],
            "activity_id": updated_image.get("activity_id")
        }

async def process_image(content: bytes) -> tuple[bytes, bytes]:
    """
    Process and optimize image for storage
    Returns (processed_image, thumbnail)
    """
    try:
        # Open image
        img = Image.open(BytesIO(content))
        
        # Resize main image if it's too large
        max_size = (2000, 2000)
        if img.width > max_size[0] or img.height > max_size[1]:
            img.thumbnail(max_size, Image.LANCZOS)
        
        # Create thumbnail
        thumbnail_size = (300, 300)
        thumbnail = img.copy()
        thumbnail.thumbnail(thumbnail_size, Image.LANCZOS)
        
        # Save processed images to bytes
        img_byte_arr = BytesIO()
        thumbnail_byte_arr = BytesIO()
        
        # Preserve transparency for PNG
        if img.format == 'PNG':
            img.save(img_byte_arr, format='PNG', optimize=True)
            thumbnail.save(thumbnail_byte_arr, format='PNG', optimize=True)
        else:
            # Convert to JPEG for other formats
            if img.mode != 'RGB':
                img = img.convert('RGB')
                thumbnail = thumbnail.convert('RGB')
            
            img.save(img_byte_arr, format='JPEG', quality=85, optimize=True)
            thumbnail.save(thumbnail_byte_arr, format='JPEG', quality=75, optimize=True)
        
        return img_byte_arr.getvalue(), thumbnail_byte_arr.getvalue()
    
    except Exception as e:
        print(f"Error processing image: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Error processing image: {str(e)}"
        )

async def save_image_to_storage(image_data: bytes, filename: str, trip_id: str) -> str:
    """
    Save image to storage (currently using Supabase Storage)
    Returns the URL to the saved image
    """
    from database.connection import get_supabase_client
    
    try:
        # Initialize Supabase client
        supabase = await get_supabase_client()
        
        # Upload to Supabase Storage
        path = f"trips/{trip_id}/{filename}"
        
        # Determine content type
        content_type = "image/jpeg"
        if filename.lower().endswith('.png'):
            content_type = "image/png"
        elif filename.lower().endswith('.gif'):
            content_type = "image/gif"
        
        # Upload file
        response = supabase.storage.from_("trip_images").upload(
            path,
            image_data,
            {"content-type": content_type}
        )
        
        # Get public URL
        public_url = supabase.storage.from_("trip_images").get_public_url(path)
        
        return public_url
    
    except Exception as e:
        print(f"Error saving image to storage: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error saving image: {str(e)}"
        )

async def delete_image_from_storage(image_url: str) -> None:
    """
    Delete image from storage
    """
    from database.connection import get_supabase_client
    
    try:
        # Extract path from URL
        path = image_url.split("trip_images/")[1] if "trip_images/" in image_url else ""
        
        if not path:
            return
        
        # Initialize Supabase client
        supabase = await get_supabase_client()
        
        # Delete file
        supabase.storage.from_("trip_images").remove(path)
    
    except Exception as e:
        print(f"Error deleting image from storage: {str(e)}")
        # Don't raise exception as this is cleanup 