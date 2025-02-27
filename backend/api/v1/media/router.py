from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form, Query
from typing import List, Optional
from uuid import UUID

from services.auth import get_current_user
from services.media import (
    upload_media_file,
    get_user_media,
    get_media_details,
    delete_media
)

router = APIRouter(prefix="/media", tags=["Media"])

@router.post("/upload", status_code=status.HTTP_201_CREATED)
async def upload_file(
    file: UploadFile = File(...),
    title: str = Form(None),
    description: str = Form(None),
    media_type: str = Form(...),  # image, video, audio, etc.
    current_user: dict = Depends(get_current_user)
):
    """Upload a media file with optional metadata"""
    return await upload_media_file(current_user["id"], file, title, description, media_type)

@router.get("/user", response_model=List[dict])
async def get_current_user_media(
    media_type: Optional[str] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    current_user: dict = Depends(get_current_user)
):
    """Get current user's media files with optional type filter"""
    return await get_user_media(current_user["id"], media_type, skip, limit)

@router.get("/{media_id}", response_model=dict)
async def get_media_file_details(
    media_id: UUID,
    current_user: dict = Depends(get_current_user)
):
    """Get detailed information about a media file"""
    return await get_media_details(media_id, current_user["id"])

@router.delete("/{media_id}", status_code=status.HTTP_200_OK)
async def delete_media_file(
    media_id: UUID,
    current_user: dict = Depends(get_current_user)
):
    """Delete a media file"""
    return await delete_media(media_id, current_user["id"]) 