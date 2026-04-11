# Design Spec: Rain Possibility (Threshold-based Suffix)

Add rain probability to the tmux-weather status bar, appearing only when it exceeds a defined threshold.

## 1. Requirements

- Fetch `precipitation_probability` from the Open-Meteo API.
- Display probability using a rain emoji (☔) followed by the percentage.
- Only show the rain indicator if the probability is >= a configurable threshold.
- Default threshold: 15%.
- Maintain existing weather information (description, temperature, feels-like, wind).

## 2. Architecture & Data Flow

### 2.1 API Update
Modify the `get_weather` function in `scripts/weather.sh` to update the Open-Meteo API URL:
`https://api.open-meteo.com/v1/forecast?...&current=weather_code,temperature_2m,apparent_temperature,wind_speed_10m,precipitation_probability`

### 2.2 Configuration
New tmux option:
- `@tmux-weather-rain-threshold`: Integer (default: `15`).

### 2.3 Logic (scripts/weather.sh)
1. Retrieve `@tmux-weather-rain-threshold` using `get_tmux_option`.
2. Parse `precipitation_probability` from the API JSON response using `awk`.
3. If `probability` >= `threshold`:
   - Set `rain_suffix=" ☔ ${probability}%"`
4. Else:
   - Set `rain_suffix=""`
5. Append `rain_suffix` to the final output string.

## 3. Implementation Plan

1. **Update Helpers:** Ensure `get_tmux_option` and `set_tmux_option` in `scripts/helpers.sh` are robust. (Already verified).
2. **Modify weather.sh:**
   - Update `api_url` in `get_weather`.
   - Update the `awk` command to capture the 5th field (`precipitation_probability`).
   - Implement the threshold check.
   - Update the final `echo` statement.
3. **Update README.md:** Document the new option `@tmux-weather-rain-threshold`.

## 4. Verification & Testing

- **Unit Test:** Add a test case to `tests/simple_test.sh` (or create a new test) that mocks the API response with varying precipitation probabilities.
- **Manual Test:** Temporarily set `@tmux-weather-rain-threshold` to `0` in `.tmux.conf` to force the indicator to show.
- **Edge Case:** Ensure the script handles missing or null probability values gracefully.
