-- Add username column (if it doesn't exist)
ALTER TABLE users ADD COLUMN IF NOT EXISTS username TEXT UNIQUE;

-- Add first_name column (if it doesn't exist)
ALTER TABLE users ADD COLUMN IF NOT EXISTS first_name TEXT;

-- Add last_name column (if it doesn't exist)
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_name TEXT;

-- Add is_active column with default value of true (if it doesn't exist)
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;

-- For existing rows, set username to the first part of the email if username is NULL
UPDATE users
SET username = SPLIT_PART(email, '@', 1)
WHERE username IS NULL;

-- Update is_active to true for all existing rows where it's NULL
UPDATE users
SET is_active = TRUE
WHERE is_active IS NULL; 