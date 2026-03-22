#!/usr/bin/env bash

PATH="/usr/local/bin:$PATH:/usr/sbin"

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/helpers.sh"

get_coordinates() {
  local cached=$(get_tmux_option "@weather-cached-coords")
  local cached_time=$(get_tmux_option "@weather-cached-coords-time" 0)
  local current_time=$(date "+%s")
  local delta=$((current_time - cached_time))
  
  # Cache for 24 hours (86400 seconds)
  if [ -n "$cached" ] && [ $delta -lt 86400 ]; then
    echo "$cached"
    return 0
  fi

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
    local new_coords="$lat,$lon"
    set_tmux_option "@weather-cached-coords" "$new_coords"
    set_tmux_option "@weather-cached-coords-time" "$current_time"
    echo "$new_coords"
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
  local t_suffix="°C"
  
  if [ "$units" = "u" ]; then
    temp_unit="fahrenheit"
    t_suffix="°F"
  fi

  local api_url="https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=weather_code,temperature_2m,apparent_temperature&timezone=auto&temperature_unit=$temp_unit"

  local json=$(curl -s --max-time 5 "$api_url")
  
  # Parse current weather object using awk in one pass
  local data=$(echo "$json" | awk -F'"current":{' '{print $2}' | awk -F'[,}]' '{for(i=1;i<=NF;i++){if($i~/"weather_code"/){split($i,a,":");c=a[2]}if($i~/"temperature_2m"/){split($i,a,":");t=a[2]}if($i~/"apparent_temperature"/){split($i,a,":");f=a[2]}}} END{print c, t, f}')
  local code=$(echo "$data" | awk '{print $1}')
  local temp=$(echo "$data" | awk '{print $2}')
  local feel=$(echo "$data" | awk '{print $3}')

  if [ -n "$temp" ] && [ -n "$feel" ] && [ -n "$code" ]; then
    local desc=$(get_weather_desc "$code")
    # Format: Emoji Temp (Feels RealFeel)
    echo "$desc ${temp}${t_suffix} (Feels ${feel}${t_suffix})"
    return 0
  fi
  return 1
}

main() {
  local update_interval=$((60 * $(get_tmux_option "@tmux-weather-interval" 120)))
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
