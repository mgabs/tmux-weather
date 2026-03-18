#!/usr/bin/env bash

PATH="/usr/local/bin:$PATH:/usr/sbin"

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/helpers.sh"

get_coordinates() {
  local dynamic_location=$(get_tmux_option "@tmux-weather-dynamic-location" "false")
  local location=$(get_tmux_option "@tmux-weather-location")
  local lat=""
  local lon=""

  if [ "$dynamic_location" = "true" ] || [ -z "$location" ]; then
    # Use ip-api.com for coordinates (reliable and returns both lat/lon)
    local coords=$(curl -s --max-time 2 "http://ip-api.com/line/?fields=lat,lon")
    lat=$(echo "$coords" | sed -n '1p')
    lon=$(echo "$coords" | sed -n '2p')
  else
    # Use Open-Meteo Geocoding API for static location
    local search_name=$(echo "$location" | sed 's/ /+/g')
    local geo_json=$(curl -s --max-time 2 "https://geocoding-api.open-meteo.com/v1/search?name=$search_name&count=1&language=en&format=json")
    lat=$(echo "$geo_json" | grep -o '"latitude":[0-9.-]*' | head -1 | cut -d: -f2)
    lon=$(echo "$geo_json" | grep -o '"longitude":[0-9.-]*' | head -1 | cut -d: -f2)
  fi
  
  if [[ -n "$lat" ]] && [[ -n "$lon" ]]; then
    echo "$lat,$lon"
  else
    echo ""
  fi
}

get_weather_desc() {
  case $1 in
    0) echo "☀️";;
    1|2|3) echo "⛅";;
    45|48) echo "🌫️";;
    51|53|55) echo "🌦️";;
    61|63|65) echo "🌧️";;
    71|73|75|77|85|86) echo "❄️";;
    80|81|82) echo "🌦️";;
    95|96|99) echo "⛈️";;
    *) echo "❓";;
  esac
}

get_weather() {
  local coords=$(get_coordinates)
  if [ -z "$coords" ]; then
    return 1
  fi
  
  local lat=$(echo "$coords" | cut -d, -f1)
  local lon=$(echo "$coords" | cut -d, -f2)
  local units=$(get_tmux_option "@tmux-weather-units" "m")
  
  local temp_unit="celsius"
  local wind_unit="kmh"
  local t_suffix="°C"
  local w_suffix="km/h"
  
  if [ "$units" = "u" ]; then
    temp_unit="fahrenheit"
    wind_unit="mph"
    t_suffix="°F"
    w_suffix="mph"
  fi

  local api_url="https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&daily=weather_code,temperature_2m_max,temperature_2m_min,wind_speed_10m_max&timezone=auto&temperature_unit=$temp_unit&wind_speed_unit=$wind_unit"

  local json=$(curl -s --max-time 5 "$api_url")
  
  local code=$(echo "$json" | grep -o '"weather_code":\[[^]]*' | cut -d[ -f2 | cut -d, -f1)
  local max_temp=$(echo "$json" | grep -o '"temperature_2m_max":\[[^]]*' | cut -d[ -f2 | cut -d, -f1)
  local min_temp=$(echo "$json" | grep -o '"temperature_2m_min":\[[^]]*' | cut -d[ -f2 | cut -d, -f1)
  local wind=$(echo "$json" | grep -o '"wind_speed_10m_max":\[[^]]*' | cut -d[ -f2 | cut -d, -f1)

  if [ -n "$max_temp" ] && [ -n "$min_temp" ] && [ -n "$code" ]; then
    local desc=$(get_weather_desc "$code")
    # Format: Emoji Hi/Lo Wind
    echo "$desc ${max_temp}/${min_temp}${t_suffix} ${wind}${w_suffix}"
    return 0
  fi
  return 1
}

main() {
  local update_interval=$((60 * $(get_tmux_option "@tmux-weather-interval" 15)))
  local current_time=$(date "+%s")
  local previous_update=$(get_tmux_option "@weather-previous-update-time" "0")
  local previous_value=$(get_tmux_option "@weather-previous-value")
  local delta=$((current_time - previous_update))

  # Refresh if interval passed or previous value was an error/default
  if [ -z "$previous_update" ] || [ "$previous_update" -eq 0 ] || [ $delta -ge $update_interval ] || [ -z "$previous_value" ] || [[ "$previous_value" == "Probably Cold!" ]]; then
    local value=$(get_weather)
    if [ "$?" -eq 0 ]; then
      set_tmux_option "@weather-previous-update-time" "$current_time"
      set_tmux_option "@weather-previous-value" "$value"
      previous_value="$value"
    fi
  fi

  if [ -z "$previous_value" ]; then
    previous_value="Probably Cold!"
  fi

  echo -n "$previous_value"
}

main
