from datetime import datetime, timedelta
from typing import Dict, Any, List, Optional
import jwt
import time
import httpx
from fastapi import HTTPException, status
import json
import random
import string
import math

from config.settings import settings
from models.trip import Location

async def search_locations(
    query: str, 
    latitude: Optional[float] = None, 
    longitude: Optional[float] = None, 
    locale: str = "en-US"
) -> List[Location]:
    """
    Search for locations using query string.
    Provides placeholder data if Apple Maps API is not configured.
    """
    # Check if Apple Maps credentials are available
    if not all([
        settings.APPLE_MAPS_TOKEN,
        settings.APPLE_MAPS_TEAM_ID,
        settings.APPLE_MAPS_KEY_ID
    ]) or settings.APPLE_MAPS_TOKEN == "your-apple-maps-token":
        print("Apple Maps API credentials not available. Using placeholder data.")
        return generate_placeholder_locations(query, 5)
    
    try:
        # Generate token
        token = generate_maps_token()
        
        # Build URL for Apple Maps Geocoding API
        url = "https://maps-api.apple.com/v1/search"
        
        # Prepare parameters
        params = {
            "q": query,
            "lang": locale
        }
        
        # Add coordinates if provided (for location biasing)
        if latitude is not None and longitude is not None:
            params["userLocation"] = f"{latitude},{longitude}"
        
        # Set up headers
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }
        
        # Make API request
        async with httpx.AsyncClient() as client:
            response = await client.get(url, params=params, headers=headers)
            
            if response.status_code == 200:
                data = response.json()
                return parse_location_results(data)
            else:
                print(f"Apple Maps API error: {response.status_code}, {response.text}")
                return generate_placeholder_locations(query, 3)
                
    except Exception as e:
        print(f"Error searching locations: {str(e)}")
        return generate_placeholder_locations(query, 3)

async def get_place_details(place_id: str, locale: str = "en-US") -> Optional[Dict[str, Any]]:
    """
    Get detailed information about a place using its place_id.
    Provides placeholder data if Apple Maps API is not configured.
    """
    # Check if Apple Maps credentials are available
    if not all([
        settings.APPLE_MAPS_TOKEN,
        settings.APPLE_MAPS_TEAM_ID,
        settings.APPLE_MAPS_KEY_ID
    ]) or settings.APPLE_MAPS_TOKEN == "your-apple-maps-token":
        print("Apple Maps API credentials not available. Using placeholder data.")
        return generate_placeholder_place_details(place_id)
    
    try:
        # Generate token
        token = generate_maps_token()
        
        # Build URL for Apple Maps Places API
        url = f"https://maps-api.apple.com/v1/places/{place_id}"
        
        # Prepare parameters
        params = {
            "lang": locale
        }
        
        # Set up headers
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }
        
        # Make API request
        async with httpx.AsyncClient() as client:
            response = await client.get(url, params=params, headers=headers)
            
            if response.status_code == 200:
                data = response.json()
                return process_place_details(data)
            else:
                print(f"Apple Maps API error: {response.status_code}, {response.text}")
                return generate_placeholder_place_details(place_id)
                
    except Exception as e:
        print(f"Error getting place details: {str(e)}")
        return generate_placeholder_place_details(place_id)

async def get_directions(
    origin_lat: float,
    origin_lng: float,
    destination_lat: float,
    destination_lng: float,
    mode: str = "DRIVING", # DRIVING, WALKING, TRANSIT
    departure_time: Optional[datetime] = None,
    locale: str = "en-US"
) -> Optional[Dict[str, Any]]:
    """
    Get directions between two points.
    Provides placeholder data if Apple Maps API is not configured.
    """
    # Check if Apple Maps credentials are available
    if not all([
        settings.APPLE_MAPS_TOKEN,
        settings.APPLE_MAPS_TEAM_ID,
        settings.APPLE_MAPS_KEY_ID
    ]) or settings.APPLE_MAPS_TOKEN == "your-apple-maps-token":
        print("Apple Maps API credentials not available. Using placeholder data.")
        return generate_placeholder_directions(origin_lat, origin_lng, destination_lat, destination_lng, mode)
    
    try:
        # Generate token
        token = generate_maps_token()
        
        # Map our mode values to Apple Maps values
        mode_mapping = {
            "DRIVING": "Car",
            "WALKING": "Pedestrian",
            "TRANSIT": "Transit"
        }
        apple_mode = mode_mapping.get(mode.upper(), "Car")
        
        # Build URL for Apple Maps Directions API
        url = "https://maps-api.apple.com/v1/directions"
        
        # Prepare parameters
        params = {
            "origin": f"{origin_lat},{origin_lng}",
            "destination": f"{destination_lat},{destination_lng}",
            "transportType": apple_mode,
            "lang": locale
        }
        
        # Add departure time if provided
        if departure_time:
            params["departureDate"] = departure_time.isoformat()
        
        # Set up headers
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }
        
        # Make API request
        async with httpx.AsyncClient() as client:
            response = await client.get(url, params=params, headers=headers)
            
            if response.status_code == 200:
                data = response.json()
                return process_directions_response(data)
            else:
                print(f"Apple Maps API error: {response.status_code}, {response.text}")
                return generate_placeholder_directions(origin_lat, origin_lng, destination_lat, destination_lng, mode)
                
    except Exception as e:
        print(f"Error getting directions: {str(e)}")
        return generate_placeholder_directions(origin_lat, origin_lng, destination_lat, destination_lng, mode)

async def geocode_address(address: str, locale: str = "en-US") -> Optional[Location]:
    """
    Convert address to coordinates.
    Uses the search_locations function with the address as query.
    """
    locations = await search_locations(address, locale=locale)
    return locations[0] if locations else None

async def reverse_geocode(latitude: float, longitude: float, locale: str = "en-US") -> Optional[Location]:
    """
    Convert coordinates to address.
    Provides placeholder data if Apple Maps API is not configured.
    """
    # Check if Apple Maps credentials are available
    if not all([
        settings.APPLE_MAPS_TOKEN,
        settings.APPLE_MAPS_TEAM_ID,
        settings.APPLE_MAPS_KEY_ID
    ]) or settings.APPLE_MAPS_TOKEN == "your-apple-maps-token":
        print("Apple Maps API credentials not available. Using placeholder data.")
        return generate_placeholder_reverse_geocode(latitude, longitude)
    
    try:
        # Generate token
        token = generate_maps_token()
        
        # Build URL for Apple Maps Reverse Geocoding API
        url = "https://maps-api.apple.com/v1/reverseGeocode"
        
        # Prepare parameters
        params = {
            "loc": f"{latitude},{longitude}",
            "lang": locale
        }
        
        # Set up headers
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }
        
        # Make API request
        async with httpx.AsyncClient() as client:
            response = await client.get(url, params=params, headers=headers)
            
            if response.status_code == 200:
                data = response.json()
                
                if "results" in data and data["results"]:
                    result = data["results"][0]
                    
                    # Extract address components
                    address_components = {}
                    if "addressDictionary" in result:
                        address_components = result["addressDictionary"]
                    
                    # Construct the address string
                    address = construct_address_from_components(address_components)
                    
                    return Location(
                        name=address,
                        address=address,
                        latitude=latitude,
                        longitude=longitude,
                        place_id=result.get("mapItemId")
                    )
                else:
                    return generate_placeholder_reverse_geocode(latitude, longitude)
            else:
                print(f"Apple Maps API error: {response.status_code}, {response.text}")
                return generate_placeholder_reverse_geocode(latitude, longitude)
                
    except Exception as e:
        print(f"Error reverse geocoding: {str(e)}")
        return generate_placeholder_reverse_geocode(latitude, longitude)

def generate_maps_token() -> str:
    """
    Generate JWT token for Apple Maps API
    """
    current_time = int(time.time())
    
    # Create JWT payload
    payload = {
        "iss": settings.APPLE_MAPS_TEAM_ID,  # Team ID
        "iat": current_time,
        "exp": current_time + 3600,  # 1 hour expiry
        "sub": settings.APPLE_MAPS_KEY_ID  # Maps Key ID
    }
    
    # Create and sign JWT
    token = jwt.encode(
        payload=payload,
        key=settings.APPLE_MAPS_TOKEN,  # Private key
        algorithm="ES256"
    )
    
    return token

def parse_location_results(data: Dict[str, Any]) -> List[Location]:
    """
    Parse Apple Maps search results into a list of Location objects
    """
    locations = []
    
    if "results" in data:
        for result in data["results"]:
            # Extract main details
            location = Location(
                name=result.get("displayName", "Unknown"),
                address=result.get("formattedAddress", ""),
                latitude=result.get("coordinate", {}).get("latitude"),
                longitude=result.get("coordinate", {}).get("longitude"),
                place_id=result.get("mapItemId")
            )
            locations.append(location)
    
    return locations

def process_place_details(data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Process Apple Maps place details into our app's format
    """
    result = {}
    
    if "result" in data:
        place = data["result"]
        
        result = {
            "id": place.get("mapItemId"),
            "name": place.get("displayName", "Unknown"),
            "address": place.get("formattedAddress", ""),
            "location": {
                "latitude": place.get("coordinate", {}).get("latitude"),
                "longitude": place.get("coordinate", {}).get("longitude")
            },
            "types": place.get("categories", []),
            "phone": place.get("phoneNumbers", [{}])[0].get("number") if place.get("phoneNumbers") else None,
            "website": place.get("urls", [{}])[0].get("value") if place.get("urls") else None,
            "hours": process_opening_hours(place.get("hours", {})),
            "rating": place.get("rating", {}).get("value") if place.get("rating") else None,
            "reviews_count": place.get("rating", {}).get("reviewCount") if place.get("rating") else None,
            "photos": [],
            "note": "This is placeholder data as Apple Maps API is not configured."
        }
    
    return result

def process_directions_response(data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Process Apple Maps directions response into our app's format
    """
    result = {
        "routes": [],
        "status": "OK"
    }
    
    if "routes" in data:
        for route_data in data["routes"]:
            route = {
                "summary": route_data.get("summary", ""),
                "distance": {
                    "value": route_data.get("distance", 0),
                    "text": f"{route_data.get('distance', 0)} meters"
                },
                "duration": {
                    "value": route_data.get("duration", 0),
                    "text": f"{route_data.get('duration', 0) // 60} mins"
                },
                "legs": []
            }
            
            # Process route legs (journey sections)
            if "legs" in route_data:
                for leg_data in route_data["legs"]:
                    leg = {
                        "distance": {
                            "value": leg_data.get("distance", 0),
                            "text": f"{leg_data.get('distance', 0)} meters"
                        },
                        "duration": {
                            "value": leg_data.get("duration", 0),
                            "text": f"{leg_data.get('duration', 0) // 60} mins"
                        },
                        "start_address": leg_data.get("origin", {}).get("address", ""),
                        "end_address": leg_data.get("destination", {}).get("address", ""),
                        "start_location": {
                            "lat": leg_data.get("origin", {}).get("coordinate", {}).get("latitude"),
                            "lng": leg_data.get("origin", {}).get("coordinate", {}).get("longitude")
                        },
                        "end_location": {
                            "lat": leg_data.get("destination", {}).get("coordinate", {}).get("latitude"),
                            "lng": leg_data.get("destination", {}).get("coordinate", {}).get("longitude")
                        },
                        "steps": []
                    }
                    
                    # Process steps (navigation instructions)
                    if "steps" in leg_data:
                        for step_data in leg_data["steps"]:
                            step = {
                                "instruction": step_data.get("instructions", ""),
                                "distance": {
                                    "value": step_data.get("distance", 0),
                                    "text": f"{step_data.get('distance', 0)} meters"
                                },
                                "duration": {
                                    "value": step_data.get("duration", 0),
                                    "text": f"{step_data.get('duration', 0) // 60} mins"
                                }
                            }
                            leg["steps"].append(step)
                    
                    route["legs"].append(leg)
            
            result["routes"].append(route)
    
    return result

def construct_address_from_components(components: Dict[str, Any]) -> str:
    """
    Construct a formatted address from address components
    """
    parts = []
    
    # Add street number and name
    street = ""
    if "SubThoroughfare" in components:
        street += components["SubThoroughfare"] + " "
    if "Thoroughfare" in components:
        street += components["Thoroughfare"]
    
    if street:
        parts.append(street.strip())
    
    # Add city/locality
    if "City" in components:
        parts.append(components["City"])
    elif "Locality" in components:
        parts.append(components["Locality"])
    
    # Add state/region and postal code
    region_postal = ""
    if "State" in components:
        region_postal += components["State"]
    elif "AdministrativeArea" in components:
        region_postal += components["AdministrativeArea"]
    
    if "PostalCode" in components:
        if region_postal:
            region_postal += " " + components["PostalCode"]
        else:
            region_postal = components["PostalCode"]
    
    if region_postal:
        parts.append(region_postal)
    
    # Add country
    if "Country" in components:
        parts.append(components["Country"])
    
    # Join all parts with commas
    return ", ".join(parts)

# Placeholder data functions for when API is unavailable

def generate_placeholder_locations(query: str, count: int = 3) -> List[Location]:
    """Generate placeholder location results for development or when API is unavailable"""
    locations = []
    
    # Use the query as part of the location names to make it seem relevant
    for i in range(count):
        # Generate a random place ID
        place_id = ''.join(random.choices(string.ascii_uppercase + string.digits, k=16))
        
        # Create a location with variations
        location = Location(
            name=f"{query.title()} {['Place', 'Spot', 'Location', 'Area', 'Center'][i % 5]} {i+1}",
            address=f"{i+1} {query.title()} Street, Sample City, 12345",
            latitude=random.uniform(-90, 90),
            longitude=random.uniform(-180, 180),
            place_id=place_id
        )
        locations.append(location)
    
    return locations

def generate_placeholder_place_details(place_id: str) -> Dict[str, Any]:
    """Generate placeholder place details for development or when API is unavailable"""
    # Extract some characters from the place_id to make results consistent for the same ID
    place_seed = sum(ord(c) for c in place_id) if place_id else 0
    random.seed(place_seed)
    
    place_types = ["restaurant", "cafe", "hotel", "attraction", "park", "museum"]
    place_type = place_types[place_seed % len(place_types)]
    
    details = {
        "id": place_id,
        "name": f"Sample {place_type.title()} {place_seed % 100}",
        "address": f"{(place_seed % 500) + 1} Example Street, Sample City, 12345",
        "location": {
            "latitude": (place_seed % 180) - 90,
            "longitude": (place_seed % 360) - 180
        },
        "types": [place_type],
        "phone": f"+1 (555) {place_seed % 999:03d}-{place_seed % 9999:04d}",
        "website": f"https://example.com/{place_type}/{place_id}",
        "hours": {
            "periods": [
                {"open": "09:00", "close": "17:00", "day": "Monday"},
                {"open": "09:00", "close": "17:00", "day": "Tuesday"},
                {"open": "09:00", "close": "17:00", "day": "Wednesday"},
                {"open": "09:00", "close": "17:00", "day": "Thursday"},
                {"open": "09:00", "close": "20:00", "day": "Friday"},
                {"open": "10:00", "close": "22:00", "day": "Saturday"},
                {"open": "11:00", "close": "16:00", "day": "Sunday"}
            ],
            "current_status": "open" if random.random() > 0.3 else "closed"
        },
        "rating": round(3.5 + random.random() * 1.5, 1),
        "reviews_count": random.randint(10, 500),
        "photos": [],
        "note": "This is placeholder data as Apple Maps API is not configured."
    }
    
    # Reset random seed
    random.seed()
    
    return details

def generate_placeholder_directions(
    origin_lat: float, 
    origin_lng: float, 
    destination_lat: float, 
    destination_lng: float, 
    mode: str
) -> Dict[str, Any]:
    """Generate placeholder directions data for development or when API is unavailable"""
    # Calculate a rough estimate of distance in meters (very approximate)
    lat_diff = abs(destination_lat - origin_lat)
    lng_diff = abs(destination_lng - origin_lng)
    # Rough conversion to meters (very approximate)
    distance = ((lat_diff * 111000) ** 2 + (lng_diff * 111000 * abs(math.cos(origin_lat * math.pi / 180))) ** 2) ** 0.5
    
    # Estimate duration based on mode and distance
    speed_factors = {
        "DRIVING": 0.5,  # ~30 km/h in meters/sec
        "WALKING": 0.05,  # ~3 km/h in meters/sec
        "TRANSIT": 0.3   # ~18 km/h in meters/sec
    }
    speed = speed_factors.get(mode.upper(), 0.5)
    duration = distance / speed if speed > 0 else 0
    
    # Format distance and duration
    distance_formatted = f"{round(distance / 1000, 1)} km"
    duration_formatted = f"{int(duration / 60)} mins"
    
    # Create a sample route with steps
    route = {
        "summary": f"Sample {mode.lower()} route",
        "distance": {
            "value": round(distance),
            "text": distance_formatted
        },
        "duration": {
            "value": round(duration),
            "text": duration_formatted
        },
        "legs": [
            {
                "distance": {
                    "value": round(distance),
                    "text": distance_formatted
                },
                "duration": {
                    "value": round(duration),
                    "text": duration_formatted
                },
                "start_address": "Origin Address",
                "end_address": "Destination Address",
                "start_location": {
                    "lat": origin_lat,
                    "lng": origin_lng
                },
                "end_location": {
                    "lat": destination_lat,
                    "lng": destination_lng
                },
                "steps": generate_placeholder_steps(distance, duration, mode)
            }
        ]
    }
    
    return {
        "routes": [route],
        "status": "OK",
        "note": "This is placeholder data as Apple Maps API is not configured."
    }

def generate_placeholder_steps(distance: float, duration: float, mode: str) -> List[Dict[str, Any]]:
    """Generate placeholder navigation steps"""
    # Number of steps based on distance
    num_steps = max(3, min(8, int(distance / 1000)))
    
    # Standard navigation instructions
    driving_instructions = [
        "Head north on Example Street",
        "Turn right onto Main Street",
        "Continue onto Highway 1",
        "Take the exit toward City Center",
        "Turn left onto Oak Avenue",
        "Continue straight onto Pine Road",
        "Turn right onto Destination Street",
        "Arrive at your destination"
    ]
    
    walking_instructions = [
        "Head north on Example Path",
        "Turn right onto Main Walkway",
        "Continue through Central Park",
        "Cross the intersection",
        "Turn left onto Pedestrian Street",
        "Walk straight through the plaza",
        "Turn right onto Destination Path",
        "Arrive at your destination"
    ]
    
    transit_instructions = [
        "Walk to Example Station",
        "Board the Express Line toward City Center",
        "Ride for 5 stops",
        "Transfer to the Local Line",
        "Ride for 3 stops",
        "Exit at Central Station",
        "Walk to Destination Street",
        "Arrive at your destination"
    ]
    
    # Select appropriate instructions based on mode
    if mode.upper() == "WALKING":
        instructions = walking_instructions[:num_steps]
    elif mode.upper() == "TRANSIT":
        instructions = transit_instructions[:num_steps]
    else:
        instructions = driving_instructions[:num_steps]
    
    # Ensure the last instruction is always about arriving
    if num_steps > 1 and "arrive" not in instructions[-1].lower():
        instructions[-1] = "Arrive at your destination"
    
    # Create step objects
    steps = []
    step_distance = distance / len(instructions)
    step_duration = duration / len(instructions)
    
    for i, instruction in enumerate(instructions):
        # Vary distance and duration slightly for each step
        variation = 0.8 + random.random() * 0.4  # 0.8 to 1.2
        step = {
            "instruction": instruction,
            "distance": {
                "value": round(step_distance * variation),
                "text": f"{round(step_distance * variation / 1000, 1)} km"
            },
            "duration": {
                "value": round(step_duration * variation),
                "text": f"{int(step_duration * variation / 60)} mins"
            }
        }
        steps.append(step)
    
    return steps

def generate_placeholder_reverse_geocode(latitude: float, longitude: float) -> Location:
    """Generate placeholder reverse geocode data for development or when API is unavailable"""
    # Generate a deterministic but varied address based on the coordinates
    lat_part = abs(int(latitude * 100)) % 1000
    lng_part = abs(int(longitude * 100)) % 1000
    
    address = f"{lat_part} Example Street, Sample City {lng_part}, Example Country"
    
    return Location(
        name=f"Location at {latitude:.4f}, {longitude:.4f}",
        address=address,
        latitude=latitude,
        longitude=longitude,
        place_id=f"placeholder_{int(latitude * 1000)}_{int(longitude * 1000)}"
    )

def process_opening_hours(hours_data: Dict[str, Any]) -> Dict[str, Any]:
    """Process opening hours from Apple Maps API response"""
    if not hours_data:
        return {"available": False}
    
    result = {
        "available": True,
        "periods": [],
        "current_status": hours_data.get("currentStatus", "unknown")
    }
    
    # Process weekly schedule if available
    if "regularHours" in hours_data and "days" in hours_data["regularHours"]:
        for day_data in hours_data["regularHours"]["days"]:
            day_name = day_data.get("dayOfWeek", "Unknown")
            
            # Process each open period for this day
            for period in day_data.get("hours", []):
                period_data = {
                    "day": day_name,
                    "open": period.get("startTime"),
                    "close": period.get("endTime")
                }
                result["periods"].append(period_data)
    
    return result 