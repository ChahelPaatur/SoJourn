from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from api.router import api_router
from config.settings import settings
from database.connection import initialize_db

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Initialize database connection on startup
    await initialize_db()
    yield
    # Cleanup tasks on shutdown (if needed)
    pass

app = FastAPI(
    title="SoJourn API",
    description="Backend API for SoJourn Travel Application",
    version="1.0.0",
    lifespan=lifespan
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include all API routes
app.include_router(api_router, prefix="/api")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True) 