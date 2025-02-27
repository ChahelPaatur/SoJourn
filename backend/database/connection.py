import os
from supabase import create_client, Client
from config.settings import settings
from contextlib import asynccontextmanager

# Global Supabase client
supabase: Client = None

async def initialize_db():
    """Initialize the Supabase client and connection"""
    global supabase
    
    if not settings.SUPABASE_URL or not settings.SUPABASE_KEY:
        raise ValueError("SUPABASE_URL and SUPABASE_KEY must be set in environment variables")
    
    # Initialize the Supabase client
    supabase = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)
    
    # Test the connection
    try:
        # Simple query to verify connection works - using simpler syntax
        response = supabase.table('users').select('*').execute()
        print(f"Successfully connected to Supabase. {len(response.data)} users retrieved.")
    except Exception as e:
        print(f"Error connecting to Supabase: {str(e)}")
        raise

async def get_supabase_client() -> Client:
    """
    Get the Supabase client instance.
    Should be called after initialize_db() has been executed.
    """
    if supabase is None:
        await initialize_db()
    return supabase

@asynccontextmanager
async def get_db_client():
    """Async context manager for getting a database client"""
    client = await get_supabase_client()
    try:
        yield client
    finally:
        # No need to close Supabase client explicitly
        pass 