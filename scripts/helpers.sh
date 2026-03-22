#!/usr/bin/env bash

#!/usr/bin/env bash

get_tmux_option() {
  local option_value=$(tmux show-option -gqv "$1")
  printf "%s" "${option_value:-$2}"
}

set_tmux_option() {
  local option_name="$1"
  local option_value="$2"
  tmux set-option -gq "$option_name" "$option_value"
}


