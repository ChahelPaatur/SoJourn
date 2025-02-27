from fastapi import APIRouter, Depends, HTTPException, status, Body
from fastapi.security import OAuth2PasswordRequestForm
from typing import Any
from datetime import timedelta

from models.user import UserCreate, UserResponse
from services.auth import (
    authenticate_user, 
    create_access_token,
    create_refresh_token,
    get_current_user,
    register_new_user,
    verify_refresh_token,
    request_password_reset,
    reset_password
)
from config.settings import settings

router = APIRouter()

@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register(user_data: UserCreate) -> Any:
    """
    Register a new user.
    """
    return await register_new_user(user_data)

@router.post("/login")
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
    """
    OAuth2 compatible token login, get an access token for future requests.
    """
    user = await authenticate_user(form_data.username, form_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.id}, expires_delta=access_token_expires
    )
    refresh_token = create_refresh_token(data={"sub": user.id})
    
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "user_id": user.id
    }

@router.post("/refresh-token")
async def refresh_token(refresh_token: str = Body(...)):
    """
    Refresh access token using refresh token.
    """
    user_id = await verify_refresh_token(refresh_token)
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user_id}, expires_delta=access_token_expires
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
    }

@router.post("/logout")
async def logout(current_user: UserResponse = Depends(get_current_user)):
    """
    Logout current user.
    This is mostly a placeholder as we don't maintain token state on the server.
    For a more secure implementation, we'd need to store token revocation info.
    """
    return {"message": "Successfully logged out"}

@router.post("/password-reset-request")
async def request_reset(email: str = Body(..., embed=True)):
    """
    Request a password reset email.
    """
    await request_password_reset(email)
    return {"message": "If the email exists, a password reset link has been sent."}

@router.post("/password-reset")
async def reset(token: str = Body(...), new_password: str = Body(...)):
    """
    Reset password using token.
    """
    success = await reset_password(token, new_password)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired password reset token",
        )
    return {"message": "Password has been reset successfully"} 