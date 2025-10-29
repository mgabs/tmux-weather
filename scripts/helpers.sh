#!/usr/bin/env bash

#!/usr/bin/env bash

get_tmux_option() {
  local option_name="$1"
  local default_value="$2"
  local option_value=$(tmux show-option -gqv "$option_name")

  if [ -z "$option_value" ]; then
    printf "%s" "$default_value"
  else
    printf "%s" "$option_value"
  fi
}

set_tmux_option() {
  local option_name="$1"
  local option_value="$2"
  tmux set-option -gq "$option_name" "$option_value"
}


