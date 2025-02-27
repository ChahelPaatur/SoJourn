from datetime import datetime, timedelta
from typing import Optional
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from passlib.context import CryptContext
import uuid

from models.user import UserCreate, UserResponse, UserBase
from database.connection import get_db_client
from config.settings import settings

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# OAuth2 token handling
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a password against a hash"""
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    """Hash a password for storing"""
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """Create JWT access token"""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(
        to_encode, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM
    )
    return encoded_jwt

def create_refresh_token(data: dict) -> str:
    """Create JWT refresh token with longer expiry"""
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(days=30)  # 30 days
    to_encode.update({"exp": expire, "refresh": True})
    encoded_jwt = jwt.encode(
        to_encode, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM
    )
    return encoded_jwt

async def register_new_user(user_data: UserCreate) -> UserResponse:
    """Register a new user"""
    async with get_db_client() as db:
        # Check if email already exists
        result = db.table('users').select('id').eq('email', user_data.email).execute()
        if result.data:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="User with this email already exists",
            )
        
        # Create user
        user_id = str(uuid.uuid4())
        hashed_password = get_password_hash(user_data.password)
        
        # Include all fields for the updated schema
        user_dict = {
            "id": user_id,
            "email": user_data.email,
            "username": user_data.username,
            "first_name": user_data.first_name,
            "last_name": user_data.last_name,
            "password": hashed_password,
            "created_at": datetime.utcnow().isoformat(),
            "auth_provider": "email",
            "is_active": True
        }
        
        result = db.table('users').insert(user_dict).execute()
        
        # Create empty profile
        profile_data = {
            "user_id": user_id,
            "dark_mode_enabled": False,
            "notifications_enabled": True,
            "email_notifications_enabled": True,
            "pinterest_connected": False,
            "preferred_activities": []
        }
        
        # Uncomment this if you have a user_profiles table
        # db.table('user_profiles').insert(profile_data).execute()
        
        created_user = UserResponse(
            id=user_id,
            email=user_data.email,
            username=user_data.username,
            first_name=user_data.first_name,
            last_name=user_data.last_name,
            created_at=datetime.utcnow(),
            is_active=True
        )
        
        return created_user

async def authenticate_user(username_or_email: str, password: str) -> Optional[UserResponse]:
    """Authenticate a user with username/email and password"""
    async with get_db_client() as db:
        # Try to find user by email
        email_query = db.table('users').select('*').eq('email', username_or_email)
        email_result = email_query.execute()
        
        # If no result by email, try by username
        if not email_result.data:
            username_query = db.table('users').select('*').eq('username', username_or_email)
            result = username_query.execute()
        else:
            result = email_result
        
        if not result.data:
            return None
        
        user_dict = result.data[0]
        
        # Verify password
        if not verify_password(password, user_dict["password"]):
            return None
        
        # Use values from the updated schema
        return UserResponse(
            id=user_dict["id"],
            email=user_dict["email"],
            username=user_dict.get("username", user_dict["email"].split('@')[0]),  # Fallback if username not yet set
            first_name=user_dict.get("first_name"),
            last_name=user_dict.get("last_name"),
            created_at=datetime.fromisoformat(user_dict["created_at"]),
            is_active=user_dict.get("is_active", True)  # Default to True if field is not set
        )

async def get_current_user(token: str = Depends(oauth2_scheme)) -> UserResponse:
    """Get current user from JWT token"""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        payload = jwt.decode(
            token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM]
        )
        user_id: str = payload.get("sub")
        
        if user_id is None:
            raise credentials_exception
        
    except JWTError:
        raise credentials_exception
    
    async with get_db_client() as db:
        result = db.table('users').select('*').eq('id', user_id).execute()
        
        if not result.data:
            raise credentials_exception
        
        user_dict = result.data[0]
        
        # Use values from the updated schema
        return UserResponse(
            id=user_dict["id"],
            email=user_dict["email"],
            username=user_dict.get("username", user_dict["email"].split('@')[0]),  # Fallback if username not yet set
            first_name=user_dict.get("first_name"),
            last_name=user_dict.get("last_name"),
            created_at=datetime.fromisoformat(user_dict["created_at"]),
            is_active=user_dict.get("is_active", True)  # Default to True if field is not set
        )

async def verify_refresh_token(refresh_token: str) -> Optional[str]:
    """Verify refresh token and return user_id if valid"""
    try:
        payload = jwt.decode(
            refresh_token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM]
        )
        user_id: str = payload.get("sub")
        is_refresh = payload.get("refresh", False)
        
        if user_id is None or not is_refresh:
            return None
        
        return user_id
        
    except JWTError:
        return None

async def request_password_reset(email: str) -> None:
    """Request password reset for a user"""
    async with get_db_client() as db:
        # Check if user exists
        result = db.table('users').select('id').eq('email', email).execute()
        
        if not result.data:
            # Don't reveal if email exists or not for security
            return
        
        user_id = result.data[0]["id"]
        
        # Generate reset token
        reset_token = create_access_token(
            data={"sub": user_id, "reset": True},
            expires_delta=timedelta(hours=1)
        )
        
        # Store token in database with expiry
        token_data = {
            "user_id": user_id,
            "token": reset_token,
            "expires_at": (datetime.utcnow() + timedelta(hours=1)).isoformat(),
            "created_at": datetime.utcnow().isoformat()
        }
        
        db.table('password_reset_tokens').insert(token_data).execute()
        
        # In a real app, send email with reset link
        # For this sample, we just return successfully
        print(f"Password reset token for {email}: {reset_token}")

async def reset_password(token: str, new_password: str) -> bool:
    """Reset password using a reset token"""
    try:
        # Verify token
        payload = jwt.decode(
            token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM]
        )
        user_id: str = payload.get("sub")
        is_reset = payload.get("reset", False)
        
        if user_id is None or not is_reset:
            return False
        
        async with get_db_client() as db:
            # Check if token exists in database
            result = db.table('password_reset_tokens').select('*').eq('token', token).execute()
            
            if not result.data:
                return False
            
            token_data = result.data[0]
            expires_at = datetime.fromisoformat(token_data["expires_at"])
            
            if datetime.utcnow() > expires_at:
                # Token expired
                return False
            
            # Update password
            hashed_password = get_password_hash(new_password)
            
            db.table('users').update(
                {"password": hashed_password}
            ).eq('id', user_id).execute()
            
            # Delete used token
            db.table('password_reset_tokens').delete().eq('token', token).execute()
            
            return True
            
    except JWTError:
        return False 