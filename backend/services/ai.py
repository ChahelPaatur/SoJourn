from typing import List, Dict, Any, Optional
from datetime import datetime
import uuid
import json
import asyncio
from openai import AsyncOpenAI

from models.ai import (
    AiModel, 
    TripGenerationRequest, 
    TripGenerationResponse,
    ActivityRecommendationRequest,
    ActivityRecommendationResponse,
    ActivityRecommendation,
    ChatRequest,
    ChatResponse,
    BudgetOptimizationRequest,
    BudgetOptimizationResponse,
    TripAnalysisRequest,
    TripAnalysisResponse
)
from models.trip import Trip, Activity, Location, TripStatus, WeatherData, ActivityType
from services.trips import get_trip_by_id
from services.weather import get_weather_forecast
from services.expedia import search_activities, search_hotels
from config.settings import settings
from database.connection import get_db_client

# Initialize AI client
openai_client = AsyncOpenAI(api_key=settings.OPENAI_API_KEY)

async def generate_trip(request: TripGenerationRequest, user_id: str) -> TripGenerationResponse:
    """Generate a trip using AI"""
    # Get destination information from API or database
    destination_info = await get_destination_info(request.destination)
    
    # Get weather forecast for the trip dates
    weather_info = await get_weather_forecast(
        latitude=destination_info.get("latitude"),
        longitude=destination_info.get("longitude"),
        start_date=request.start_date,
        end_date=request.end_date
    )
    
    # Prepare context for AI
    prompt = create_trip_generation_prompt(
        destination=request.destination,
        start_date=request.start_date,
        end_date=request.end_date,
        preferences=request.preferences,
        budget_level=request.budget_level,
        accommodation_type=request.accommodation_type,
        activity_preferences=request.activity_preferences,
        dietary_restrictions=request.dietary_restrictions,
        accessibility_needs=request.accessibility_needs,
        pace_preference=request.pace_preference,
        destination_info=destination_info,
        weather_info=weather_info
    )
    
    # Use ChatGPT exclusively
    response_text = await generate_with_openai(prompt, AiModel.GPT4)
    
    # Parse AI response
    try:
        trip_data = parse_trip_generation_response(response_text)
    except Exception as e:
        print(f"Error parsing AI response: {str(e)}")
        # Fallback to a simpler parsing approach
        trip_data = simple_parse_trip_response(response_text, request)
    
    # Create trip in database as a draft
    trip_dict = {
        "title": trip_data.get("title", f"Trip to {request.destination}"),
        "destination": request.destination,
        "start_date": request.start_date,
        "end_date": request.end_date,
        "notes": trip_data.get("notes", ""),
        "status": TripStatus.DRAFT,
        "is_archived": False,
        "is_draft": True,
        "is_shared": False,
        "owner_id": user_id,
        "created_at": datetime.utcnow().isoformat(),
        "updated_at": datetime.utcnow().isoformat(),
        "published_at": None
    }
    
    async with get_db_client() as db:
        trip_id = str(uuid.uuid4())
        trip_dict["id"] = trip_id
        
        # Insert trip
        db.table('trips').insert(trip_dict).execute()
        
        # Insert activities
        activities = trip_data.get("activities", [])
        if activities:
            activities_dict = []
            for activity in activities:
                activity_id = str(uuid.uuid4())
                location_data = None
                
                if activity.get("location"):
                    location_id = str(uuid.uuid4())
                    location_data = {
                        "id": location_id,
                        "name": activity["location"].get("name", ""),
                        "address": activity["location"].get("address"),
                        "latitude": activity["location"].get("latitude"),
                        "longitude": activity["location"].get("longitude"),
                        "place_id": activity["location"].get("place_id")
                    }
                    
                    # Insert location
                    db.table('locations').insert(location_data).execute()
                
                # Create activity dict
                activity_dict = {
                    "id": activity_id,
                    "trip_id": trip_id,
                    "title": activity.get("title", ""),
                    "description": activity.get("description"),
                    "start_datetime": activity.get("start_datetime", request.start_date.isoformat()),
                    "end_datetime": activity.get("end_datetime"),
                    "all_day": activity.get("all_day", False),
                    "location_id": location_data["id"] if location_data else None,
                    "notes": activity.get("notes"),
                    "activity_type": activity.get("activity_type", ActivityType.OTHER.value),
                    "cost": activity.get("cost"),
                    "currency": activity.get("currency", "USD"),
                    "reservation_info": activity.get("reservation_info"),
                    "weather_data": activity.get("weather_data"),
                    "images": activity.get("images", []),
                    "created_at": datetime.utcnow().isoformat(),
                    "updated_at": datetime.utcnow().isoformat()
                }
                
                activities_dict.append(activity_dict)
            
            if activities_dict:
                db.table('activities').insert(activities_dict).execute()
        
        # Insert trip generation metadata
        metadata = {
            "trip_id": trip_id,
            "generated_at": datetime.utcnow().isoformat(),
            "model_used": request.model.value,
            "destination": request.destination,
            "preferences": request.model_dump(),
            "suggestions": trip_data.get("suggestions", []),
            "estimated_costs": trip_data.get("estimated_costs", {})
        }
        
        db.table('trip_generations').insert(metadata).execute()
    
    # Get the created trip
    trip = await get_trip_by_id(trip_id, user_id)
    
    # Create response
    return TripGenerationResponse(
        trip_id=trip_id,
        title=trip.title,
        destination=trip.destination,
        start_date=trip.start_date,
        end_date=trip.end_date,
        activities=trip.activities,
        suggestions=trip_data.get("suggestions", []),
        estimated_costs=trip_data.get("estimated_costs", {}),
        generated_at=datetime.utcnow(),
        model_used=request.model
    )

async def recommend_activities(request: ActivityRecommendationRequest, user_id: str) -> ActivityRecommendationResponse:
    """Recommend activities for a trip using AI"""
    # Get the trip
    trip = await get_trip_by_id(request.trip_id, user_id)
    
    # Prepare prompt
    prompt = create_activity_recommendation_prompt(
        trip=trip.model_dump(),
        activity_type=request.activity_type,
        date=request.date,
        count=request.count
    )
    
    # Use ChatGPT exclusively
    response_text = await generate_with_openai(prompt, AiModel.GPT4)
    
    # Parse AI response
    recommendations = parse_activity_recommendations(response_text, count=request.count)
    
    # Create response
    return ActivityRecommendationResponse(
        trip_id=trip.id,
        recommendations=recommendations,
        generated_at=datetime.utcnow(),
        model_used=AiModel.GPT4
    )

async def chat_with_ai(request: ChatRequest, user_id: str) -> ChatResponse:
    """Chat with AI about a trip"""
    # Get the trip
    trip = await get_trip_by_id(request.trip_id, user_id)
    
    # Get chat history if it exists
    chat_history = []
    if request.chat_history_id:
        async with get_db_client() as db:
            result = db.table('chat_messages').select('*').eq('chat_history_id', request.chat_history_id).order('created_at', desc=False).execute()
            chat_history = result.data
    
    # Prepare prompt
    prompt = create_chat_prompt(
        trip=trip.model_dump(),
        message=request.message,
        chat_history=chat_history
    )
    
    # Use ChatGPT exclusively
    response_text = await generate_with_openai(prompt, AiModel.GPT4)
    
    # Save message and response to database
    chat_history_id = request.chat_history_id or str(uuid.uuid4())
    message_id = str(uuid.uuid4())
    
    async with get_db_client() as db:
        # Save user message
        user_message = {
            "id": str(uuid.uuid4()),
            "chat_history_id": chat_history_id,
            "trip_id": request.trip_id,
            "user_id": user_id,
            "message": request.message,
            "is_ai": False,
            "created_at": datetime.utcnow().isoformat()
        }
        
        # Save AI response
        ai_message = {
            "id": message_id,
            "chat_history_id": chat_history_id,
            "trip_id": request.trip_id,
            "user_id": None,
            "message": response_text,
            "is_ai": True,
            "model_used": request.model.value,
            "created_at": datetime.utcnow().isoformat()
        }
        
        db.table('chat_messages').insert([user_message, ai_message]).execute()
    
    # Create response
    return ChatResponse(
        trip_id=request.trip_id,
        message_id=message_id,
        response=response_text,
        model_used=request.model,
        generated_at=datetime.utcnow()
    )

async def optimize_budget(request: BudgetOptimizationRequest, user_id: str) -> BudgetOptimizationResponse:
    """Optimize trip budget using AI"""
    # Get the trip
    trip = await get_trip_by_id(request.trip_id, user_id)
    
    # Calculate total budget and current spend
    total_budget = request.budget or 0
    current_spend = sum(activity.cost or 0 for activity in trip.activities)
    
    # Prepare prompt
    prompt = create_budget_optimization_prompt(
        trip=trip.model_dump(),
        budget=total_budget,
        current_spend=current_spend,
        priorities=request.priorities,
        must_keep_activities=request.must_keep_activities
    )
    
    # Use ChatGPT exclusively
    response_text = await generate_with_openai(prompt, AiModel.GPT4)
    
    # Parse AI response
    try:
        optimization_data = json.loads(extract_json_from_text(response_text))
    except Exception as e:
        print(f"Error parsing optimization response: {str(e)}")
        optimization_data = {
            "optimized_total": current_spend,
            "recommendations": {
                "general": ["Unable to parse AI response."]
            },
            "activity_changes": {}
        }
    
    # Create response
    return BudgetOptimizationResponse(
        trip_id=trip.id,
        original_total=current_spend,
        optimized_total=optimization_data["optimized_total"],
        currency="USD",
        recommendations=optimization_data["recommendations"],
        activity_changes=optimization_data["activity_changes"],
        generated_at=datetime.utcnow(),
        model_used=AiModel.GPT4
    )

async def analyze_trip(request: TripAnalysisRequest, user_id: str) -> TripAnalysisResponse:
    """Analyze a trip using AI"""
    # Get the trip
    trip = await get_trip_by_id(request.trip_id, user_id)
    
    # Prepare prompt
    prompt = create_trip_analysis_prompt(
        trip=trip.model_dump(),
        aspects=request.aspects
    )
    
    # Use ChatGPT exclusively
    response_text = await generate_with_openai(prompt, AiModel.GPT4)
    
    # Parse AI response
    try:
        analysis_data = parse_trip_analysis_response(response_text)
    except Exception as e:
        print(f"Error parsing analysis response: {str(e)}")
        analysis_data = {
            "summary": "Unable to parse AI response",
            "analysis": {},
            "recommendations": []
        }
    
    # Create response
    return TripAnalysisResponse(
        trip_id=trip.id,
        analysis=analysis_data.get("analysis", {}),
        recommendations=analysis_data.get("recommendations", []),
        summary=analysis_data.get("summary", ""),
        generated_at=datetime.utcnow(),
        model_used=AiModel.GPT4
    )

# Helper functions

async def get_destination_info(destination: str) -> Dict[str, Any]:
    """Get information about a destination"""
    # In a real implementation, this would query a database or API
    # For now, return placeholder data
    return {
        "name": destination,
        "latitude": 0.0,
        "longitude": 0.0,
        "country": "Unknown",
        "timezone": "UTC",
        "currency": "USD",
        "language": "English",
        "popular_activities": ["Sightseeing", "Museums", "Restaurants"],
        "best_seasons": ["Spring", "Summer", "Fall", "Winter"]
    }

def create_trip_generation_prompt(
    destination: str,
    start_date: datetime,
    end_date: datetime,
    preferences: Dict[str, Any],
    budget_level: Optional[str],
    accommodation_type: Optional[str],
    activity_preferences: List[str],
    dietary_restrictions: List[str],
    accessibility_needs: List[str],
    pace_preference: Optional[str],
    destination_info: Dict[str, Any],
    weather_info: Dict[str, Any]
) -> str:
    """Create a prompt for trip generation"""
    trip_days = (end_date - start_date).days + 1
    
    # Create the base prompt first
    prompt = f"""
You are a professional travel planner. Generate a detailed trip itinerary for a trip to {destination}.

Trip Details:
- Destination: {destination}
- Start Date: {start_date.strftime('%Y-%m-%d')}
- End Date: {end_date.strftime('%Y-%m-%d')}
- Duration: {trip_days} days
- Budget Level: {budget_level or 'Not specified'}
- Accommodation Type: {accommodation_type or 'Not specified'}
- Pace Preference: {pace_preference or 'Not specified'}

Traveler Preferences:
- Activity Preferences: {', '.join(activity_preferences) if activity_preferences else 'Not specified'}
- Dietary Restrictions: {', '.join(dietary_restrictions) if dietary_restrictions else 'None'}
- Accessibility Needs: {', '.join(accessibility_needs) if accessibility_needs else 'None'}

Destination Information:
- Country: {destination_info.get('country', 'Unknown')}
- Currency: {destination_info.get('currency', 'USD')}
- Language: {destination_info.get('language', 'Unknown')}
- Popular Activities: {', '.join(destination_info.get('popular_activities', []))}
- Best Seasons: {', '.join(destination_info.get('best_seasons', []))}

"""
    
    # Add weather forecast separately
    prompt += "Weather Forecast:\n"
    prompt += json.dumps(weather_info, indent=2)
    
    # Add additional preferences
    prompt += "\n\nAdditional Preferences:\n"
    prompt += json.dumps(preferences, indent=2)
    
    # Add instructions for the itinerary format
    prompt += """

Generate a day-by-day itinerary with the following structure:
1. Trip Title: A catchy title for the trip
2. Notes: Any important considerations or tips for the trip
3. Day-by-day activities:
   - Each day should have 2-4 activities with:
     - Title: Short title of the activity
     - Description: Brief description
     - Activity Type: (sightseeing, dining, accommodation, transportation, entertainment, etc.)
     - Location: Name and address if applicable
     - Estimated Cost: Approximate cost in USD
     - Duration: Estimated duration

Format your response as a JSON object with the following structure:
"""
    
    # Add JSON template separately
    prompt += """```json
{
  "title": "Trip title",
  "destination": "Destination name",
  "notes": "Important notes about the trip",
  "days": [
    {
      "day": 1,
      "date": "2023-07-01",
      "activities": [
        {
          "title": "Activity title",
          "description": "Activity description",
          "start_time": "09:00",
          "end_time": "11:00",
          "activity_type": "sightseeing",
          "location": {
            "name": "Location name",
            "address": "Location address",
            "latitude": null,
            "longitude": null
          },
          "notes": "Any additional notes",
          "activity_type": "sightseeing",
          "cost": 25.0,
          "currency": "USD"
        }
      ]
    }
  ],
  "suggestions": ["Suggestion 1", "Suggestion 2"],
  "estimated_costs": {
    "accommodation": 500,
    "food": 300,
    "activities": 200,
    "transportation": 150,
    "total": 1150
  }
}
```

Make sure all activities are appropriate for the travel dates, weather conditions, and traveler preferences.
Ensure the itinerary has a good mix of activities and reasonable timing between locations.
"""
    
    return prompt

def create_activity_recommendation_prompt(
    trip: Dict[str, Any],
    activity_type: Optional[str],
    date: Optional[datetime],
    count: int
) -> str:
    """Create a prompt for activity recommendations"""
    
    date_str = date.strftime('%Y-%m-%d') if date else "the entire trip"
    activity_type_str = activity_type if activity_type else "any type"
    
    # Create the base prompt without complex nested f-strings
    prompt = f"""
You are a professional travel guide. Recommend {count} activities for a trip to {trip['destination']}.

Trip Details:
- Destination: {trip['destination']}
- Start Date: {trip['start_date'].strftime('%Y-%m-%d')}
- End Date: {trip['end_date'].strftime('%Y-%m-%d')}
- Title: {trip['title']}
- Notes: {trip['notes']}

Recommendations should be for date: {date_str}
Activity type: {activity_type_str}

"""
    
    # Add instructions section without nesting f-strings
    prompt += f"""

Generate {count} activity recommendations that:
1. Are not duplicate of existing activities
2. Fit with the overall theme and pace of the trip
3. Are appropriate for the date and destination
4. Include relevant information for each activity

Format your response as a JSON array with the following structure:
"""

    # Add the JSON example without nesting within the f-string
    prompt += """```json
[
  {
    "title": "Activity title",
    "description": "Activity description",
    "activity_type": "sightseeing",
    "location": {
      "name": "Location name",
      "address": "Location address if available"
    },
    "estimated_duration": 2.5,
    "estimated_cost": 25.0,
    "currency": "USD",
    "reasoning": "Why this activity was recommended"
  }
]
```

Ensure your recommendations are diverse and take into account the traveler's existing plans.
"""
    
    return prompt

def create_chat_prompt(
    trip: Dict[str, Any],
    message: str,
    chat_history: List[Dict[str, Any]]
) -> str:
    """Create a prompt for AI chat about a trip"""
    
    # Extract key trip details
    destination = trip.get('destination', 'Unknown destination')
    start_date = trip.get('start_date', 'Unknown start date')
    end_date = trip.get('end_date', 'Unknown end date')
    activities = trip.get('activities', [])
    
    # Format the activities in a readable way
    activities_text = ""
    for idx, activity in enumerate(activities):
        activities_text += f"\n{idx+1}. {activity.get('title', 'Unnamed activity')}"
        if activity.get('description'):
            activities_text += f" - {activity.get('description')}"
    
    # Format previous messages
    history_text = ""
    for msg in chat_history:
        role = "User" if msg.get('is_user') else "Assistant"
        content = msg.get('content', '')
        history_text += f"\n{role}: {content}"
    
    # Create the base prompt
    prompt = f"""
You are a travel assistant for this trip to {destination} from {start_date} to {end_date}.

Trip Details:
- Destination: {destination}
- Start Date: {start_date}
- End Date: {end_date}
- Activities:{activities_text if activities_text else ' No activities planned yet.'}

Chat History:
{history_text if history_text else 'No previous messages.'}

User Query: {message}

Please provide a helpful, friendly response that takes into account the specific details of this trip.
Be conversational and personable, suggest specific activities or changes to the itinerary if relevant.
If you don't know something specific, you can offer general travel advice for {destination} instead.
"""
    
    return prompt

def create_budget_optimization_prompt(
    trip: Dict[str, Any],
    budget: float,
    current_spend: float,
    priorities: Optional[Dict[str, float]],
    must_keep_activities: List[str]
) -> str:
    """Create a prompt for budget optimization"""
    
    priorities_text = "No specific priorities provided."
    if priorities:
        priorities_text = "\n".join([f"- {k}: {v}" for k, v in priorities.items()])
    
    must_keep_text = "No specific activities that must be kept."
    if must_keep_activities:
        must_keep_activities_details = [a for a in trip['activities'] if a['id'] in must_keep_activities]
        must_keep_text = json.dumps(must_keep_activities_details, indent=2)
    
    # Create the base prompt first
    prompt = f"""
You are a travel budget optimization expert. Help optimize a trip to fit within a budget of {budget} USD.

Trip Details:
- Destination: {trip['destination']}
- Start Date: {trip['start_date'].strftime('%Y-%m-%d')}
- End Date: {trip['end_date'].strftime('%Y-%m-%d')}
- Title: {trip['title']}
- Current Total Cost: {current_spend} USD
- Target Budget: {budget} USD

"""
    
    # Add trip activities separately
    prompt += "Trip Activities:\n"
    prompt += json.dumps(trip['activities'], indent=2)
    
    # Add priorities and must-keep activities
    prompt += f"""

Priorities:
{priorities_text}

Activities that must be kept:
{must_keep_text}

Analyze the current trip and optimize it to fit within the budget while preserving the overall experience.
Suggest adjustments such as:
1. Replacing expensive activities with more affordable alternatives
2. Optimizing transportation or accommodation choices
3. Combining activities or finding discounts
4. Adjusting timing or duration of activities

Format your response as a JSON object with the following structure:
"""
    
    # Add JSON template separately
    prompt += """```json
{
  "optimized_total": 950.0,
  "recommendations": {
    "general": ["General recommendation 1", "General recommendation 2"],
    "accommodation": ["Accommodation recommendation 1"],
    "food": ["Food recommendation 1"],
    "activities": ["Activities recommendation 1"],
    "transportation": ["Transportation recommendation 1"]
  },
  "activity_changes": {
    "remove": ["Activity ID 1", "Activity ID 2"],
    "modify": [
      {
        "id": "Activity ID 3",
        "changes": "Description of changes",
        "new_cost": 15.0
      }
    ],
    "add": [
      {
        "title": "New activity",
        "description": "Description",
        "activity_type": "sightseeing",
        "cost": 10.0,
        "currency": "USD",
        "replaces": "Activity ID it replaces"
      }
    ]
  }
}
```

Ensure your recommendations are practical and maintain the essence of the trip experience.
"""
    
    return prompt

def create_trip_analysis_prompt(
    trip: Dict[str, Any],
    aspects: List[str]
) -> str:
    """Create a prompt for trip analysis"""
    
    # Create the base prompt first
    prompt = f"""
You are a travel analysis expert. Analyze a trip to {trip['destination']} focusing on the following aspects: {', '.join(aspects)}

Trip Details:
- Destination: {trip['destination']}
- Start Date: {trip['start_date'].strftime('%Y-%m-%d')}
- End Date: {trip['end_date'].strftime('%Y-%m-%d')}
- Title: {trip['title']}
- Duration: {(trip['end_date'] - trip['start_date']).days + 1} days

"""
    
    # Add trip activities separately
    prompt += "Trip Activities:\n"
    prompt += json.dumps(trip['activities'], indent=2)
    
    # Add analysis instructions
    prompt += f"""

Perform a detailed analysis of the trip focusing on the following aspects: {', '.join(aspects)}

Consider factors such as:

- For 'balance': Variety of activities, pace, mix of active vs. relaxation time
- For 'pace': Travel time between locations, activity density, risk of burnout
- For 'variety': Diversity of experiences, repetitiveness, missed opportunities
- For 'logistics': Travel distances, timing feasibility, potential bottlenecks
- For 'value': Cost vs. experience, opportunities for better value
- For 'experience': Immersion in local culture, authenticity, memorable moments

Format your response as a JSON object with the following structure:
"""
    
    # Add JSON template separately
    prompt += """```json
{
  "insights": [
    {
      "title": "Insight title",
      "description": "Detailed description of the insight",
      "severity": "high/medium/low",
      "affected_days": [1, 2]
    }
  ],
  "recommendations": [
    {
      "title": "Recommendation title",
      "description": "Detailed description of the recommendation",
      "priority": "high/medium/low",
      "affected_days": [1, 2]
    }
  ]
}
```

Provide at least 3 insights and 3 recommendations that are practical and actionable.
"""
    
    return prompt

async def generate_with_openai(prompt: str, model: AiModel = AiModel.GPT4) -> str:
    """Generate text using OpenAI's GPT-4"""
    # Always use GPT-4 for better results
    model_name = "gpt-4"
    
    try:
        response = await openai_client.chat.completions.create(
            model=model_name,
            messages=[
                {
                    "role": "system", 
                    "content": """You are an advanced travel planning assistant specializing in creating personalized itineraries.
                    
Your key responsibilities:
1. Create detailed, realistic travel plans based on user preferences
2. Suggest activities that match the user's interests and budget
3. Provide practical advice that enhances the travel experience
4. Adjust recommendations based on weather, local events, and constraints
5. Format responses in clean, structured JSON when requested

When generating itineraries:
- Prioritize activities that match stated preferences
- Balance popular attractions with unique local experiences
- Consider practical logistics like travel time between locations
- Suggest realistic timeframes for activities
- Include estimated costs in the requested currency"""
                },
                {"role": "user", "content": prompt}
            ],
            temperature=0.7,
            max_tokens=4000
        )
        
        return response.choices[0].message.content
    except Exception as e:
        print(f"Error generating with OpenAI: {str(e)}")
        return f"Error: Unable to generate content with OpenAI. {str(e)}"

def parse_trip_generation_response(response_text: str) -> Dict[str, Any]:
    """Parse the trip generation response from AI"""
    # Extract JSON from response
    try:
        # Look for JSON block
        json_match = response_text.strip()
        if "```json" in json_match:
            json_match = json_match.split("```json")[1].split("```")[0].strip()
        elif "```" in json_match:
            json_match = json_match.split("```")[1].split("```")[0].strip()
        
        # Parse JSON
        trip_data = json.loads(json_match)
        
        # Process activities
        for activity in trip_data.get("activities", []):
            # Convert datetime strings to datetime objects
            if isinstance(activity.get("start_datetime"), str):
                try:
                    activity["start_datetime"] = datetime.fromisoformat(activity["start_datetime"])
                except ValueError:
                    # If date format is incorrect, use placeholder
                    activity["start_datetime"] = datetime.utcnow()
            
            if isinstance(activity.get("end_datetime"), str) and activity["end_datetime"]:
                try:
                    activity["end_datetime"] = datetime.fromisoformat(activity["end_datetime"])
                except ValueError:
                    activity["end_datetime"] = None
        
        return trip_data
    except Exception as e:
        print(f"Error parsing trip generation response: {str(e)}")
        raise

def simple_parse_trip_response(response_text: str, request: TripGenerationRequest) -> Dict[str, Any]:
    """A simpler fallback parsing approach for trip generation"""
    # Extract title and notes using simple heuristics
    lines = response_text.strip().split('\n')
    title = request.destination
    notes = ""
    activities = []
    suggestions = []
    estimated_costs = {"total": 0}
    
    # Look for title
    for line in lines:
        if "title:" in line.lower() or "trip to" in line.lower():
            title = line.split(":", 1)[1].strip() if ":" in line else line.strip()
            break
    
    # Look for activities
    current_activity = {}
    for line in lines:
        line = line.strip()
        if "day" in line.lower() and ":" in line:
            # New day marker
            if current_activity and "title" in current_activity:
                activities.append(current_activity)
            current_activity = {}
        elif "activity:" in line.lower() or "visit:" in line.lower() or "tour:" in line.lower():
            # New activity
            if current_activity and "title" in current_activity:
                activities.append(current_activity)
            activity_title = line.split(":", 1)[1].strip() if ":" in line else line.strip()
            current_activity = {
                "title": activity_title,
                "description": "",
                "start_datetime": request.start_date,
                "activity_type": "sightseeing",
                "cost": None,
                "currency": "USD"
            }
        elif "description:" in line.lower() and current_activity:
            current_activity["description"] = line.split(":", 1)[1].strip()
        elif "cost:" in line.lower() and current_activity:
            cost_text = line.split(":", 1)[1].strip()
            try:
                cost = float(''.join(c for c in cost_text if c.isdigit() or c == '.'))
                current_activity["cost"] = cost
            except:
                pass
        elif "suggestion:" in line.lower() or "tip:" in line.lower():
            suggestion = line.split(":", 1)[1].strip() if ":" in line else line.strip()
            suggestions.append(suggestion)
    
    # Add the last activity if exists
    if current_activity and "title" in current_activity:
        activities.append(current_activity)
    
    return {
        "title": title,
        "notes": notes,
        "activities": activities,
        "suggestions": suggestions,
        "estimated_costs": estimated_costs
    }

def parse_activity_recommendations(response_text: str, count: int) -> List[ActivityRecommendation]:
    """Parse activity recommendations from AI response"""
    try:
        # Extract JSON
        json_match = response_text.strip()
        if "```json" in json_match:
            json_match = json_match.split("```json")[1].split("```")[0].strip()
        elif "```" in json_match:
            json_match = json_match.split("```")[1].split("```")[0].strip()
        
        # Parse JSON
        recommendations_data = json.loads(json_match)
        
        # Create recommendations
        recommendations = []
        for i, rec in enumerate(recommendations_data):
            if i >= count:
                break
                
            location = None
            if rec.get("location"):
                location = Location(
                    name=rec["location"].get("name", ""),
                    address=rec["location"].get("address"),
                    latitude=rec["location"].get("latitude"),
                    longitude=rec["location"].get("longitude"),
                    place_id=rec["location"].get("place_id")
                )
            
            recommendation = ActivityRecommendation(
                title=rec.get("title", ""),
                description=rec.get("description", ""),
                activity_type=rec.get("activity_type", "other"),
                location=location,
                estimated_duration=rec.get("estimated_duration"),
                estimated_cost=rec.get("estimated_cost"),
                currency=rec.get("currency", "USD"),
                reasoning=rec.get("reasoning", "")
            )
            
            recommendations.append(recommendation)
        
        return recommendations
    except Exception as e:
        print(f"Error parsing activity recommendations: {str(e)}")
        # Return empty list if error
        return []

def parse_trip_analysis_response(response_text: str) -> Dict[str, Any]:
    """Parse trip analysis response from AI"""
    try:
        # Extract JSON
        json_match = response_text.strip()
        if "```json" in json_match:
            json_match = json_match.split("```json")[1].split("```")[0].strip()
        elif "```" in json_match:
            json_match = json_match.split("```")[1].split("```")[0].strip()
        
        # Parse JSON
        analysis_data = json.loads(json_match)
        
        return analysis_data
    except Exception as e:
        print(f"Error parsing trip analysis response: {str(e)}")
        # Return default structure if error
        return {
            "insights": [
                {
                    "title": "Error parsing response",
                    "description": "Unable to parse AI analysis. Please try again.",
                    "severity": "low",
                    "affected_days": []
                }
            ],
            "recommendations": []
        }

def extract_json_from_text(text: str) -> str:
    """Extract JSON from text returned by AI models"""
    # Check for code blocks with json
    if "```json" in text:
        # Extract content between ```json and ```
        parts = text.split("```json")
        json_part = parts[1].split("```")[0].strip()
        return json_part
    
    # Check for generic code blocks
    elif "```" in text:
        # Extract content between ``` and ```
        parts = text.split("```")
        json_part = parts[1].strip()
        return json_part
    
    # Otherwise, return the whole text as it might be a direct JSON response
    return text.strip() 