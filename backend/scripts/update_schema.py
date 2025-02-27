import os
import sys
import asyncio
from supabase import create_client

# Adding parent directory to path to import our config
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from config.settings import settings
from database.connection import initialize_db, get_supabase_client

async def update_users_schema():
    """
    Update the users table schema to add missing columns required by the application.
    This adds:
    - username
    - first_name
    - last_name
    - is_active (with default value of true)
    """
    print("Initializing database connection...")
    await initialize_db()
    
    # Get the Supabase client
    supabase = await get_supabase_client()
    
    print("Connected to Supabase. Updating users table schema...")
    
    # Use Supabase's PostgreSQL function to alter the table
    # This requires the RPC function to be enabled in Supabase
    try:
        # Execute SQL statements via RPC
        # We'll use pgSQL to add the columns
        rpc_response = supabase.rpc(
            'execute_sql', 
            {
                'sql_query': """
                -- Add username column (if it doesn't exist)
                DO $$ 
                BEGIN 
                    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'username') THEN
                        ALTER TABLE users ADD COLUMN username TEXT UNIQUE;
                    END IF;
                END $$;

                -- Add first_name column (if it doesn't exist)
                DO $$ 
                BEGIN 
                    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'first_name') THEN
                        ALTER TABLE users ADD COLUMN first_name TEXT;
                    END IF;
                END $$;

                -- Add last_name column (if it doesn't exist)
                DO $$ 
                BEGIN 
                    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'last_name') THEN
                        ALTER TABLE users ADD COLUMN last_name TEXT;
                    END IF;
                END $$;

                -- Add is_active column with default value of true (if it doesn't exist)
                DO $$ 
                BEGIN 
                    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'is_active') THEN
                        ALTER TABLE users ADD COLUMN is_active BOOLEAN DEFAULT TRUE;
                    END IF;
                END $$;
                """
            }
        ).execute()
        
        print("Schema update successful. Added missing columns to the users table.")
        print("- username (TEXT, UNIQUE)")
        print("- first_name (TEXT)")
        print("- last_name (TEXT)")
        print("- is_active (BOOLEAN, DEFAULT TRUE)")
        
        # Check if the RPC function doesn't exist
        if 'error' in rpc_response and 'function execute_sql does not exist' in str(rpc_response.get('error')):
            print("\nERROR: The 'execute_sql' RPC function doesn't exist in your Supabase instance.")
            print("Alternative approach: You need to manually execute the following SQL in the Supabase SQL editor:")
            print("""
-- Add username column (if it doesn't exist)
ALTER TABLE users ADD COLUMN IF NOT EXISTS username TEXT UNIQUE;

-- Add first_name column (if it doesn't exist)
ALTER TABLE users ADD COLUMN IF NOT EXISTS first_name TEXT;

-- Add last_name column (if it doesn't exist)
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_name TEXT;

-- Add is_active column with default value of true (if it doesn't exist)
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;
            """)
    except Exception as e:
        print(f"Error updating schema: {str(e)}")
        print("\nManual alternative: Execute the following SQL in the Supabase SQL editor:")
        print("""
-- Add username column (if it doesn't exist)
ALTER TABLE users ADD COLUMN IF NOT EXISTS username TEXT UNIQUE;

-- Add first_name column (if it doesn't exist)
ALTER TABLE users ADD COLUMN IF NOT EXISTS first_name TEXT;

-- Add last_name column (if it doesn't exist)
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_name TEXT;

-- Add is_active column with default value of true (if it doesn't exist)
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;
        """)

if __name__ == "__main__":
    asyncio.run(update_users_schema()) 