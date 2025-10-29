#!/usr/bin/env bash

# Test 1: Static location

# Mock tmux command
tmux() {
  if [ "$1" = "show-option" ]; then
    case "$3" in
      "@tmux-weather-location") echo "New York";;
      "@tmux-weather-format") echo 1;;
      "@tmux-weather-units") echo "m";;
      "@tmux-weather-dynamic-location") echo "false";;
      "@weather-previous-update-time") echo "";;
      "@weather-previous-value") echo "";;
    esac
  fi
}

# Mock curl command
curl() {
  if [ "$2" = "https://wttr.in/New York?m&format=1" ]; then
    echo "? 20C"
  fi
}

export -f tmux
export -f curl

source "scripts/weather.sh"

output=$(get_weather)

if [[ "$output" == *"20C"* ]]; then
  echo "Test 1 passed!"
else
  echo "Test 1 failed!"
  exit 1
fi

# Test 2: Dynamic location

# Unset the functions to redefine them
unset -f tmux
unset -f curl

# Mock tmux command
tmux() {
  if [ "$1" = "show-option" ]; then
    case "$3" in
      "@tmux-weather-location") echo "New York";;
      "@tmux-weather-format") echo 1;;
      "@tmux-weather-units") echo "m";;
      "@tmux-weather-dynamic-location") echo "true";;
      "@weather-previous-update-time") echo "";;
      "@weather-previous-value") echo "";;
      "@tmux-weather-location-api") echo "freegeoip.app";;
    esac
  fi
}

# Mock curl command
curl() {
  if [ "$1" = "-s" ] && [ "$2" = "https://freegeoip.app/json/" ]; then
    echo '{"city":"London"}'
  elif [ "$1" = "-s" ] && [ "$2" = "https://wttr.in/London?m&format=1" ]; then
    echo "? 15C"
  fi
}

export -f tmux
export -f curl

source "scripts/weather.sh"

output=$(get_weather)

if [[ "$output" == *"15C"* ]]; then
  echo "Test 2 passed!"
else
  echo "Test 2 failed!"
  exit 1
fi
