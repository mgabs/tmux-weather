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
    esac
  fi
}

# Mock curl command
curl() {
  for arg in "$@"; do
    if [[ "$arg" == *"geocoding-api.open-meteo.com/v1/search?name=New+York"* ]]; then
      echo '{"results":[{"latitude":40.7128,"longitude":-74.006}]}'
      return 0
    elif [[ "$arg" == *"api.open-meteo.com/v1/forecast?latitude=40.7128&longitude=-74.006"* ]]; then
      echo '{"daily":{"weather_code":[0],"temperature_2m_max":[20.5],"temperature_2m_min":[10.2],"wind_speed_10m_max":[15.3]}}'
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
    *) tmux show-option -gqv "$1" "$2";;
  esac
}
set_tmux_option() {
  :
}

source "scripts/weather.sh"

output=$(get_weather)

if [[ "$output" == "☀️ 20.5/10.2°C 15.3km/h" ]]; then
  echo "Test 1 passed!"
else
  echo "Test 1 failed! Output: $output"
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
      "@tmux-weather-location") echo "";;
      "@tmux-weather-units") echo "m";;
      "@tmux-weather-dynamic-location") echo "true";;
      "@weather-previous-update-time") echo "0";;
      "@weather-previous-value") echo "";;
      "@tmux-weather-interval") echo 15;;
    esac
  fi
}

# Mock curl command
curl() {
  for arg in "$@"; do
    if [[ "$arg" == *"ip-api.com/line/?fields=lat,lon"* ]]; then
      printf "51.5074\n-0.1278\n"
      return 0
    elif [[ "$arg" == *"api.open-meteo.com/v1/forecast?latitude=51.5074&longitude=-0.1278"* ]]; then
      echo '{"daily":{"weather_code":[3],"temperature_2m_max":[15.2],"temperature_2m_min":[8.4],"wind_speed_10m_max":[12.1]}}'
      return 0
    fi
  done
}

export -f tmux
export -f curl

source "scripts/weather.sh"

output=$(get_weather)

if [[ "$output" == "⛅ 15.2/8.4°C 12.1km/h" ]]; then
  echo "Test 2 passed!"
else
  echo "Test 2 failed! Output: $output"
  exit 1
fi
