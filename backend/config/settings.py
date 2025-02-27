import os
from typing import List
from pydantic_settings import BaseSettings
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

class Settings(BaseSettings):
    # Application settings
    APP_NAME: str = "SoJourn"
    DEBUG: bool = os.getenv("DEBUG", "False").lower() == "true"
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development")
    
    # API Keys and Credentials
    # PhotoKit Apple API
    PHOTOKIT_API_KEY: str = os.getenv("PHOTOKIT_API_KEY", "")
    
    # Weather API (replaces WeatherKit)
    WEATHER_API_KEY: str = os.getenv("WEATHER_API_KEY", "")
    WEATHER_API_BASE_URL: str = os.getenv("WEATHER_API_BASE_URL", "https://api.weatherapi.com/v1")
    
    # Expedia API
    EXPEDIA_API_KEY: str = os.getenv("EXPEDIA_API_KEY", "")
    EXPEDIA_SECRET: str = os.getenv("EXPEDIA_SECRET", "")
    
    # OpenAI API (Used for ChatGPT functionality)
    OPENAI_API_KEY: str = os.getenv("OPENAI_API_KEY", "")
    
    # Pinterest API
    PINTEREST_API_KEY: str = os.getenv("PINTEREST_API_KEY", "")
    PINTEREST_APP_ID: str = os.getenv("PINTEREST_APP_ID", "")
    PINTEREST_APP_SECRET: str = os.getenv("PINTEREST_APP_SECRET", "")
    
    # Supabase
    SUPABASE_URL: str = os.getenv("SUPABASE_URL", "")
    SUPABASE_KEY: str = os.getenv("SUPABASE_KEY", "")
    SUPABASE_JWT_SECRET: str = os.getenv("SUPABASE_JWT_SECRET", "")
    
    # Storage
    STORAGE_URL: str = os.getenv("STORAGE_URL", "https://storage.sojourn.app")
    
    # Apple Maps API
    APPLE_MAPS_TOKEN: str = os.getenv("APPLE_MAPS_TOKEN", "")
    APPLE_MAPS_TEAM_ID: str = os.getenv("APPLE_MAPS_TEAM_ID", "")
    APPLE_MAPS_KEY_ID: str = os.getenv("APPLE_MAPS_KEY_ID", "")
    
    # CORS settings
    ALLOWED_ORIGINS: List[str] = [
        "http://localhost:8000",
        "http://localhost:3000",
        # Add iOS app identifier later if needed
    ]
    
    # JWT settings
    JWT_SECRET_KEY: str = os.getenv("JWT_SECRET_KEY", "your-super-secret-key-change-in-production")
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 1 week
    
    # Database settings (using Supabase)
    DB_HOST: str = os.getenv("DB_HOST", "")
    DB_PORT: str = os.getenv("DB_PORT", "5432")
    DB_USER: str = os.getenv("DB_USER", "")
    DB_PASSWORD: str = os.getenv("DB_PASSWORD", "")
    DB_NAME: str = os.getenv("DB_NAME", "")
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True


# Create settings instance
settings = Settings()

# API key validation functions
def validate_api_keys():
    """Validate that required API keys are set"""
    missing_keys = []
    
    # Check core required API keys (add/remove as needed)
    if not settings.SUPABASE_URL or not settings.SUPABASE_KEY:
        missing_keys.append("Supabase (SUPABASE_URL, SUPABASE_KEY)")
    
    if not settings.OPENAI_API_KEY:
        missing_keys.append("OpenAI (OPENAI_API_KEY)")
        
    if not settings.WEATHER_API_KEY:
        missing_keys.append("Weather API (WEATHER_API_KEY)")
    
    if missing_keys:
        print("WARNING: The following API keys are missing or invalid:")
        for key in missing_keys:
            print(f" - {key}")
        print("Please add these keys to your .env file.")
        
    return len(missing_keys) == 0 