#!/usr/bin/env bash

# Mock tmux command
tmux() {
  if [ "$1" = "show-option" ]; then
    case "$3" in
      "@tmux-weather-location") echo "New York";;
      "@tmux-weather-units") echo "m";;
      "@tmux-weather-dynamic-location") echo "false";;
      "@weather-previous-update-time") echo "0";;
      "@weather-previous-value") echo "";;
      "@tmux-weather-interval") echo 15;;
      "@tmux-weather-rain-threshold") echo 15;;
    esac
  fi
}

# Mock curl command
curl() {
  # Log to stderr to avoid polluting output
  # echo "curl called with: $@" >&2
  for arg in "$@"; do
    if [[ "$arg" == *"geocoding-api.open-meteo.com/v1/search?name=New+York"* ]]; then
      echo '{"results":[{"latitude":40.7128,"longitude":-74.006}]}'
      return 0
    elif [[ "$arg" == *"api.open-meteo.com/v1/forecast?latitude=40.7128&longitude=-74.006"* ]]; then
      # Return the value stored in a temporary file if it exists, otherwise default
      if [ -f "/tmp/weather_mock_resp" ]; then
        cat "/tmp/weather_mock_resp"
      else
        echo '{"current":{"weather_code":0,"temperature_2m":20.5,"apparent_temperature":18.2,"wind_speed_10m":15.3,"precipitation_probability":20}}'
      fi
      return 0
    fi
  done
}

export -f tmux
export -f curl

# Override source to avoid running main
get_tmux_option() {
  case "$1" in
    "@tmux-weather-interval") echo 15;;
    "@tmux-weather-rain-threshold") echo 15;;
    *) tmux show-option -gqv "$1" "$2";;
  esac
}
export -f get_tmux_option

set_tmux_option() {
  :
}
export -f set_tmux_option

# Source weather.sh
source "scripts/weather.sh"

# Test 1: Standard output with rain (20% > 15% threshold)
rm -f /tmp/weather_mock_resp
output=$(get_weather)
expected="☀️ 20.5°C(18.2°C) 💨 15.3km/h ☔ 20%"

if [[ "$output" == "$expected" ]]; then
  echo "Test 1 passed!"
else
  echo "Test 1 failed! Expected: $expected, Output: $output"
  exit 1
fi

# Test 2: No rain indicator (10% < 15% threshold)
echo '{"current":{"weather_code":0,"temperature_2m":20.5,"apparent_temperature":18.2,"wind_speed_10m":15.3,"precipitation_probability":10}}' > /tmp/weather_mock_resp

output=$(get_weather)
expected="☀️ 20.5°C(18.2°C) 💨 15.3km/h"

if [[ "$output" == "$expected" ]]; then
  echo "Test 2 passed!"
else
  echo "Test 2 failed! Expected: $expected, Output: $output"
  # Try to see if curl is working
  # curl "api.open-meteo.com/v1/forecast?latitude=40.7128&longitude=-74.006"
  exit 1
fi

echo "All tests passed!"
rm -f /tmp/weather_mock_resp
