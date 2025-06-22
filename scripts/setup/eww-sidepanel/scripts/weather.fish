#!/usr/bin/env fish
# Weather script for EWW sidebar (Fish Shell)
# Uses wttr.in service (no API key required)

# Configuration
set CITY "Stockholm"  # Change this to your city
set CACHE_FILE "/tmp/eww_weather_cache"
set CACHE_DURATION 1800  # 30 minutes in seconds

# Function to get weather data
function get_weather_data
    # Try to get weather data from wttr.in
    set weather_data (curl -s "wttr.in/$CITY?format=j1" 2>/dev/null)
    
    if test $status -eq 0; and test -n "$weather_data"
        echo $weather_data > $CACHE_FILE
        date +%s > "$CACHE_FILE.timestamp"
        echo $weather_data
    else
        # Fallback: try simple format
        set simple_weather (curl -s "wttr.in/$CITY?format=3" 2>/dev/null)
        if test $status -eq 0; and test -n "$simple_weather"
            # Create simple JSON structure
            set temp (echo $simple_weather | grep -o '[+-]\?[0-9]\+°C' | head -1)
            set desc (echo $simple_weather | sed 's/.*°C //' | sed 's/[[:space:]]*$//')
            set temp_num (string replace '°C' '' $temp)
            echo "{\"current_condition\":[{\"temp_C\":\"$temp_num\",\"weatherDesc\":[{\"value\":\"$desc\"}]}]}"
        else
            echo ""
        end
    end
end

# Check if cache exists and is recent
if test -f $CACHE_FILE; and test -f "$CACHE_FILE.timestamp"
    set cache_time (cat "$CACHE_FILE.timestamp")
    set current_time (date +%s)
    
    if test (math $current_time - $cache_time) -lt $CACHE_DURATION
        set weather_data (cat $CACHE_FILE)
    else
        set weather_data (get_weather_data)
    end
else
    set weather_data (get_weather_data)
end

# Parse weather data based on requested information
switch $argv[1]
    case "temp"
        if test -n "$weather_data"
            set temp (echo $weather_data | jq -r '.current_condition[0].temp_C // empty' 2>/dev/null)
            if test -n "$temp"; and not string match -q "null" $temp
                echo "$temp°C"
            else
                echo "N/A"
            end
        else
            echo "N/A"
        end
    
    case "desc"
        if test -n "$weather_data"
            set desc (echo $weather_data | jq -r '.current_condition[0].weatherDesc[0].value // empty' 2>/dev/null)
            if test -n "$desc"; and not string match -q "null" $desc
                echo $desc
            else
                echo "Unknown"
            end
        else
            echo "Unknown"
        end
    
    case "icon"
        if test -n "$weather_data"
            set desc (echo $weather_data | jq -r '.current_condition[0].weatherDesc[0].value // empty' 2>/dev/null)
            
            # Map weather descriptions to emojis
            set desc_lower (string lower $desc)
            if string match -q "*sunny*" $desc_lower; or string match -q "*clear*" $desc_lower
                echo "☀️"
            else if string match -q "*partly*cloudy*" $desc_lower; or string match -q "*partly*cloud*" $desc_lower
                echo "⛅"
            else if string match -q "*cloudy*" $desc_lower; or string match -q "*cloud*" $desc_lower; or string match -q "*overcast*" $desc_lower
                echo "☁️"
            else if string match -q "*rain*" $desc_lower; or string match -q "*drizzle*" $desc_lower; or string match -q "*shower*" $desc_lower
                echo "🌧️"
            else if string match -q "*snow*" $desc_lower; or string match -q "*blizzard*" $desc_lower
                echo "❄️"
            else if string match -q "*thunder*" $desc_lower; or string match -q "*storm*" $desc_lower
                echo "⛈️"
            else if string match -q "*fog*" $desc_lower; or string match -q "*mist*" $desc_lower
                echo "🌫️"
            else if string match -q "*wind*" $desc_lower
                echo "💨"
            else
                echo "🌤️"
            end
        else
            echo "🌤️"
        end
    
    case "humidity"
        if test -n "$weather_data"
            set humidity (echo $weather_data | jq -r '.current_condition[0].humidity // empty' 2>/dev/null)
            if test -n "$humidity"; and not string match -q "null" $humidity
                echo "$humidity%"
            else
                echo "N/A"
            end
        else
            echo "N/A"
        end
    
    case "feels_like"
        if test -n "$weather_data"
            set feels_like (echo $weather_data | jq -r '.current_condition[0].FeelsLikeC // empty' 2>/dev/null)
            if test -n "$feels_like"; and not string match -q "null" $feels_like
                echo "$feels_like°C"
            else
                echo "N/A"
            end
        else
            echo "N/A"
        end
    
    case "wind"
        if test -n "$weather_data"
            set wind_speed (echo $weather_data | jq -r '.current_condition[0].windspeedKmph // empty' 2>/dev/null)
            set wind_dir (echo $weather_data | jq -r '.current_condition[0].winddir16Point // empty' 2>/dev/null)
            if test -n "$wind_speed"; and not string match -q "null" $wind_speed
                echo "$wind_speed km/h $wind_dir"
            else
                echo "N/A"
            end
        else
            echo "N/A"
        end
    
    case "*"
        echo "Usage: $argv[0] {temp|desc|icon|humidity|feels_like|wind}"
        echo "Available options:"
        echo "  temp       - Current temperature"
        echo "  desc       - Weather description"
        echo "  icon       - Weather emoji icon"
        echo "  humidity   - Humidity percentage"
        echo "  feels_like - Feels like temperature"
        echo "  wind       - Wind speed and direction"
        exit 1
end