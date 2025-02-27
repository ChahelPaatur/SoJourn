from fastapi import APIRouter

from api.v1.auth.router import router as auth_router
from api.v1.users.router import router as users_router
from api.v1.trips.router import router as trips_router
from api.v1.activities.router import router as activities_router
from api.v1.ai.router import router as ai_router
from api.v1.social.router import router as social_router
# API tokens are available as placeholders in the .env file
from api.v1.weather import router as weather_router
from api.v1.maps import router as maps_router
from api.v1.photos.router import router as photos_router
from api.v1.media.router import router as media_router
from api.v1.expedia.router import router as expedia_router

# Main API router
api_router = APIRouter()

# Include all routers
api_router.include_router(auth_router, prefix="/auth", tags=["Authentication"])
api_router.include_router(users_router, prefix="/users", tags=["Users"])
api_router.include_router(trips_router, prefix="/trips", tags=["Trips"])
api_router.include_router(activities_router, prefix="/activities", tags=["Activities"])
api_router.include_router(ai_router, prefix="/ai", tags=["AI"])
api_router.include_router(social_router, prefix="/social", tags=["Social"])
# API tokens are available as placeholders in the .env file
api_router.include_router(weather_router, prefix="/weather", tags=["Weather"])
api_router.include_router(maps_router, prefix="/maps", tags=["Maps"])
api_router.include_router(photos_router, prefix="/photos", tags=["Photos"])
api_router.include_router(media_router, prefix="/media", tags=["Media"])
api_router.include_router(expedia_router, prefix="/expedia", tags=["Expedia"]) 