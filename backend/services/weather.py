from datetime import datetime, timedelta
from typing import Dict, Any, List, Optional
import json
import httpx
from fastapi import HTTPException, status
import random
import math

from config.settings import settings
from models.trip import WeatherData

async def get_weather_forecast(
    latitude: float, 
    longitude: float, 
    start_date: datetime, 
    end_date: datetime
) -> Dict[str, Any]:
    """
    Get weather forecast for a location and date range using WeatherAPI.com.
    
    If WeatherAPI credentials are not available, returns placeholder data.
    """
    # Check if WeatherAPI credentials are available
    if not settings.WEATHER_API_KEY or settings.WEATHER_API_KEY == "your-weather-api-key":
        print("WeatherAPI.com credentials not available. Using placeholder data.")
        return generate_placeholder_weather(start_date, end_date)
    
    # If we have credentials, use the WeatherAPI.com
    try:
        # Calculate date range (WeatherAPI.com accepts up to 14 days for forecast)
        days_diff = min(14, (end_date - start_date).days + 1)
        
        # Build WeatherAPI.com URL
        url = f"{settings.WEATHER_API_BASE_URL}/forecast.json"
        
        # Set up query parameters
        params = {
            "key": settings.WEATHER_API_KEY,
            "q": f"{latitude},{longitude}",
            "days": days_diff,
            "aqi": "no",
            "alerts": "no"
        }
        
        # Make API request
        async with httpx.AsyncClient() as client:
            response = await client.get(url, params=params)
            
            if response.status_code == 200:
                data = response.json()
                return format_weather_data(data, start_date, end_date)
            else:
                print(f"WeatherAPI.com error: {response.status_code}, {response.text}")
                return generate_placeholder_weather(start_date, end_date)
                
    except Exception as e:
        print(f"Error getting weather forecast: {str(e)}")
        return generate_placeholder_weather(start_date, end_date)

def format_weather_data(data: Dict[str, Any], start_date: datetime, end_date: datetime) -> Dict[str, Any]:
    """
    Format WeatherAPI.com response into our app's format
    """
    days = []
    
    if "forecast" in data and "forecastday" in data["forecast"]:
        for day_data in data["forecast"]["forecastday"]:
            day_date = datetime.strptime(day_data["date"], "%Y-%m-%d")
            
            # Skip if outside our requested range
            if day_date < start_date or day_date > end_date:
                continue
            
            # Map weather condition codes to match existing format
            condition_code = map_condition_code(day_data["day"]["condition"]["text"], day_data["day"]["condition"]["code"])
                
            formatted_day = {
                "date": day_data["date"],
                "temperature": {
                    "min": day_data["day"]["mintemp_c"],
                    "max": day_data["day"]["maxtemp_c"],
                    "morning": day_data["hour"][9]["temp_c"] if len(day_data["hour"]) > 9 else None,
                    "afternoon": day_data["hour"][15]["temp_c"] if len(day_data["hour"]) > 15 else None,
                    "evening": day_data["hour"][19]["temp_c"] if len(day_data["hour"]) > 19 else None,
                    "overnight": day_data["hour"][3]["temp_c"] if len(day_data["hour"]) > 3 else None
                },
                "condition": condition_code,
                "precipitation": {
                    "probability": day_data["day"]["daily_chance_of_rain"],
                    "amount": day_data["day"]["totalprecip_mm"]
                },
                "humidity": day_data["day"]["avghumidity"],
                "wind": {
                    "speed": day_data["day"]["maxwind_kph"],
                    "direction": day_data["hour"][12]["wind_degree"] if len(day_data["hour"]) > 12 else 0
                },
                "sunrise": day_data["astro"]["sunrise"],
                "sunset": day_data["astro"]["sunset"]
            }
            
            days.append(formatted_day)
    
    return {
        "location": {
            "latitude": data["location"]["lat"],
            "longitude": data["location"]["lon"],
            "name": data["location"]["name"]
        },
        "days": days
    }

def map_condition_code(condition_text: str, condition_code: int) -> str:
    """
    Map WeatherAPI.com condition to a format compatible with the existing app
    """
    # Mapping of WeatherAPI condition texts to our app's format
    condition_mapping = {
        "Sunny": "clear",
        "Clear": "clear",
        "Partly cloudy": "partlyCloudy",
        "Cloudy": "cloudy",
        "Overcast": "mostlyCloudy",
        "Mist": "fog",
        "Patchy rain possible": "rain",
        "Patchy snow possible": "snow",
        "Patchy sleet possible": "sleet",
        "Patchy freezing drizzle possible": "sleet",
        "Thundery outbreaks possible": "thunderstorms",
        "Blowing snow": "snow",
        "Blizzard": "snow",
        "Fog": "fog",
        "Freezing fog": "fog",
        "Patchy light drizzle": "drizzle",
        "Light drizzle": "drizzle",
        "Freezing drizzle": "sleet",
        "Heavy freezing drizzle": "sleet",
        "Patchy light rain": "rain",
        "Light rain": "rain",
        "Moderate rain at times": "rain",
        "Moderate rain": "rain",
        "Heavy rain at times": "rain",
        "Heavy rain": "rain",
        "Light freezing rain": "sleet",
        "Moderate or heavy freezing rain": "sleet",
        "Light sleet": "sleet",
        "Moderate or heavy sleet": "sleet",
        "Patchy light snow": "snow",
        "Light snow": "snow",
        "Patchy moderate snow": "snow",
        "Moderate snow": "snow",
        "Patchy heavy snow": "snow",
        "Heavy snow": "snow",
        "Ice pellets": "sleet",
        "Light rain shower": "sunShowers",
        "Moderate or heavy rain shower": "sunShowers",
        "Torrential rain shower": "rain",
        "Light sleet showers": "sleet",
        "Moderate or heavy sleet showers": "sleet",
        "Light snow showers": "sunFlurries",
        "Moderate or heavy snow showers": "snow",
        "Light showers of ice pellets": "sleet",
        "Moderate or heavy showers of ice pellets": "sleet",
        "Patchy light rain with thunder": "thunderstorms",
        "Moderate or heavy rain with thunder": "thunderstorms",
        "Patchy light snow with thunder": "thunderstorms",
        "Moderate or heavy snow with thunder": "thunderstorms"
    }
    
    return condition_mapping.get(condition_text, "partlyCloudy")

def generate_placeholder_weather(start_date: datetime, end_date: datetime) -> Dict[str, Any]:
    """
    Generate placeholder weather data for development or when API is unavailable
    """
    days = []
    current_date = start_date
    
    # Common weather conditions
    conditions = [
        "clear", "mostlyClear", "partlyCloudy", "mostlyCloudy", 
        "cloudy", "rain", "sunShowers", "sunFlurries"
    ]
    
    # Generate a day of placeholder data for each day in the range
    while current_date <= end_date:
        # Randomize weather but keep it somewhat realistic and consistent
        temp_base = 15 + 10 * (0.5 + 0.5 * math.sin((current_date - start_date).days / 7 * math.pi))
        temp_min = temp_base - random.uniform(3, 7)
        temp_max = temp_base + random.uniform(5, 10)
        
        # Pick a condition based on the date (with some randomness but consistency)
        condition_index = (current_date.day + current_date.month) % len(conditions)
        if random.random() < 0.3:  # 30% chance to pick another condition
            condition_index = (condition_index + random.randint(1, 3)) % len(conditions)
            
        condition = conditions[condition_index]
        
        # Precipitation probability higher for rain conditions
        precip_prob = 0.7 if "rain" in condition else random.uniform(0, 0.3)
        
        day_data = {
            "date": current_date.strftime("%Y-%m-%d"),
            "temperature": {
                "min": round(temp_min, 1),
                "max": round(temp_max, 1),
                "morning": round(temp_min + random.uniform(1, 3), 1),
                "afternoon": round(temp_max - random.uniform(0, 2), 1),
                "evening": round(temp_min + random.uniform(3, 6), 1),
                "overnight": round(temp_min - random.uniform(0, 2), 1)
            },
            "condition": condition,
            "precipitation": {
                "probability": round(precip_prob * 100, 1),
                "amount": round(random.uniform(0, 5) * precip_prob, 1) if precip_prob > 0.2 else 0
            },
            "humidity": round(random.uniform(50, 90), 1),
            "wind": {
                "speed": round(random.uniform(2, 15), 1),
                "direction": random.randint(0, 359)
            },
            "sunrise": "06:30",
            "sunset": "19:45"
        }
        
        days.append(day_data)
        current_date += timedelta(days=1)
    
    return {
        "location": {
            "latitude": 0,
            "longitude": 0,
            "name": "Placeholder Location"
        },
        "days": days,
        "note": "This is placeholder data as WeatherAPI.com is not configured."
    }

async def get_weather_data_for_activity(
    latitude: float, 
    longitude: float, 
    activity_date: datetime
) -> Optional[WeatherData]:
    """
    Get weather data for a specific activity date and location
    Returns a WeatherData object or None if not available
    """
    # Get forecast for the activity day
    end_date = activity_date + timedelta(days=1)
    forecast = await get_weather_forecast(latitude, longitude, activity_date, end_date)
    
    # Find the matching day
    activity_date_str = activity_date.strftime("%Y-%m-%d")
    for day in forecast.get("days", []):
        if day["date"] == activity_date_str:
            # Map forecast data to WeatherData model
            temp_data = day["temperature"]
            condition = day["condition"]
            precip = day["precipitation"]
            
            # Parse sunrise and sunset strings to datetime objects
            try:
                sunrise_time = datetime.strptime(f"{activity_date_str} {day['sunrise']}", "%Y-%m-%d %I:%M %p")
                sunset_time = datetime.strptime(f"{activity_date_str} {day['sunset']}", "%Y-%m-%d %I:%M %p")
            except ValueError:
                # Handle potential parsing issues
                sunrise_time = None
                sunset_time = None
            
            return WeatherData(
                temperature=(temp_data["max"] + temp_data["min"]) / 2,
                temperature_min=temp_data["min"],
                temperature_max=temp_data["max"],
                condition=condition,
                precipitation_probability=precip["probability"],
                humidity=day["humidity"],
                wind_speed=day["wind"]["speed"],
                wind_direction=str(day["wind"]["direction"]),
                cloud_cover=None,  # Not available in our current data structure
                sunrise=sunrise_time,
                sunset=sunset_time,
                forecast_timestamp=datetime.now()
            )
    
    return None 