#!/bin/bash
# Weather script for waybar
CITY="YourCity"
API_KEY="your_api_key"

response=$(curl -s "http://api.openweathermap.org/data/2.5/weather?q=$CITY&appid=$API_KEY&units=metric")
temp=$(echo $response | jq -r '.main.temp')
desc=$(echo $response | jq -r '.weather[0].description')

echo "🌤️ ${temp}°C"