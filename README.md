# Weather plugin for tmux
[![GitHub](https://img.shields.io/github/license/xamut/tmux-weather)](https://opensource.org/licenses/MIT)

Shows weather in the status line, data provided by [Open-Meteo](https://open-meteo.com)

![tmux-weather](./assets/tmux-preview.png)

## Installation
### Requirements
* curl
* sed
* grep
* awk

### With Tmux Plugin Manager
Add the plugin in `.tmux.conf`:
```
set -g @plugin 'xamut/tmux-weather'
```
Press `prefix + I` to fetch the plugin and source it. Done.

### Manual
Clone the repo somewhere. Add `run-shell` in the end of `.tmux.conf`:

```
run-shell PATH_TO_REPO/tmux-weather.tmux
```
NOTE: this line should be placed after `set-option -g status-right ...`.

Press `prefix + :` and type `source-file ~/.tmux.conf`. Done.

## Usage
Add `#{weather}` somewhere in the right status line:
```
set-option -g status-right "#{weather}"
```
then you will see the weather in the status line: `☀️ 20.5°C (Feels 10.2°C) 💨 15.3km/h`

## Customization
The plugin could be customized with:
* `set-option -g @tmux-weather-interval 15` - Set up the update interval in minutes, by default it is 15 minutes.
* `set-option -g @tmux-weather-dynamic-location "true"` - Set to "true" to enable dynamic location based on IP address via `ip-api.com`. Defaults to "false".
* `set-option -g @tmux-weather-location "New York"` - Set your location manually. This is used when `@tmux-weather-dynamic-location` is set to "false". Coordinates are automatically looked up via Open-Meteo Geocoding API.
* `set-option -g @tmux-weather-units "m"` - Set up weather units (`m` - for Metric/Celsius/kmh, `u` - for USCS/Fahrenheit/mph), by default used metric units.

## Other plugins
* [tmux-network-bandwidth](https://github.com/xamut/tmux-network-bandwidth)
* [tmux-spotify](https://github.com/xamut/tmux-spotify)

## License
tmux-weather plugin is released under the [MIT License](https://opensource.org/licenses/MIT).
