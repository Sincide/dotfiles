#!/bin/bash

# Simple weather script for waybar - no dependencies version
LOCATION="Skellefteå"

# Weather data
get_weather() {
    # Use wttr.in's simple format that doesn't require jq
    WEATHER_INFO=$(curl -s "https://wttr.in/$LOCATION?format=%c|%t|%h")
    
    if [ -n "$WEATHER_INFO" ] && [ "$WEATHER_INFO" != "Unknown location" ]; then
        # Parse the simple format (condition|temperature|humidity)
        IFS="|" read -r CONDITION TEMP HUMIDITY <<< "$WEATHER_INFO"
        
        # Format for output
        echo "{\"text\": \"$CONDITION $TEMP\", \"tooltip\": \"$LOCATION: $TEMP\nHumidity: $HUMIDITY\", \"class\": \"custom-weather\"}"
    else
        # Return error
        echo "{\"text\": \"󰖪\", \"tooltip\": \"Weather data unavailable\", \"class\": \"error\"}"
    fi
}

# Call the function
get_weather

exit 0 