from fastapi import APIRouter, Depends, HTTPException, status, Form, File, UploadFile, Path, Query
from typing import Any, List, Optional

from models.user import UserResponse
from services.auth import get_current_user
from services.photos import (
    upload_trip_image,
    get_trip_images,
    delete_image,
    update_image_caption
)

router = APIRouter()

@router.post("/upload", status_code=status.HTTP_201_CREATED)
async def upload_image(
    trip_id: str = Form(..., description="ID of the trip"),
    activity_id: Optional[str] = Form(None, description="ID of the activity (optional)"),
    image: UploadFile = File(..., description="Image file to upload"),
    caption: Optional[str] = Form(None, description="Image caption (optional)"),
    current_user: UserResponse = Depends(get_current_user)
) -> Any:
    """
    Upload an image for a trip or activity
    """
    return await upload_trip_image(trip_id, activity_id, image, caption, current_user.id)

@router.get("/trip/{trip_id}")
async def get_images_for_trip(
    trip_id: str = Path(..., description="ID of the trip"),
    activity_id: Optional[str] = Query(None, description="Filter by activity ID (optional)"),
    current_user: UserResponse = Depends(get_current_user)
) -> Any:
    """
    Get all images for a trip, optionally filtered by activity
    """
    return await get_trip_images(trip_id, activity_id, current_user.id)

@router.delete("/{image_id}")
async def delete_trip_image(
    image_id: str = Path(..., description="ID of the image to delete"),
    current_user: UserResponse = Depends(get_current_user)
) -> Any:
    """
    Delete an image
    """
    return await delete_image(image_id, current_user.id)

@router.put("/{image_id}/caption")
async def update_caption(
    image_id: str = Path(..., description="ID of the image"),
    caption: str = Form(..., description="New caption for the image"),
    current_user: UserResponse = Depends(get_current_user)
) -> Any:
    """
    Update the caption of an image
    """
    return await update_image_caption(image_id, caption, current_user.id) 