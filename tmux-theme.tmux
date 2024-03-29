#!/bin/bash

if [[ "$(cat ~/.theme_mode)" != "light" ]]; then
	color_primary="#BF4B4B"
	color_secondary="#252636"
	color_terceary="#1a1b26"
	color_background="#16161E"

	color_fg_dark="#16161E"
	color_fg_light="#7AA2F7"
	color_fg_base="white"

else
	color_primary="#BF4B4B"
	color_secondary="#cccccc"
	color_terceary="#b3b1b1"
	color_background="#f0f0f2"

	color_fg_dark="#16161E"
	color_fg_light="#4567b0"
	color_fg_base="black"
fi

function is_wsl() {
	version="$(cat /proc/version)"

	if [[ "$version" == *"Microsoft"* || "$version" == *"microsoft"* ]]; then
		return 0
	fi

	return 1
}

function battery_status() {
	function command_exists() {
		command -v "$1" &>/dev/null
	}

	if is_wsl; then
		battery=$(find /sys/class/power_supply/*/status | tail -n1)

		awk '{print tolower($0);}' "$battery"

	elif command_exists "pmset"; then
		pmset -g batt | awk -F '; *' 'NR==2 { print $2 }'

	elif command_exists "acpi"; then
		acpi -b | awk '{gsub(/,/, ""); print tolower($3); exit}'

	elif command_exists "upower"; then
		battery=$(upower -e | grep -E 'battery|DisplayDevice' | tail -n1)

		upower -i "$battery" | awk '/state/ {print $2}'

	elif command_exists "termux-battery-status"; then
		termux-battery-status | jq -r '.status' | awk '{printf("%s%", tolower($1))}'

	elif command_exists "apm"; then
		battery=$(apm -a)

		if [[ "$battery" == 0 ]]; then
			echo "discharging"
		elif [[ "$battery" == 1 ]]; then
			echo "charging"
		fi
	fi
}

function get() {
	option_value="$(tmux show-option -gqv "$1")"

	if [[ "$option_value" == "" ]]; then
		echo "$2"
	else
		echo "$option_value"
	fi
}

# status
tmux set-option -gq "status" "on"
tmux set-option -gq "status-justify" "left"

tmux set-option -gq "status-attr" "none"

tmux set-option -gq "status-bg" "$color_background"
tmux set-option -gq "status-fg" "$color_fg_light"

# status left
tmux set-option -gq "status-left-attr" "none"
tmux set-option -gq "status-left-length" "100"

tmux set-option -gq "status-left" \
	"#[bg=$color_primary, fg=$color_fg_dark, bold] #S "

tmux set-option -gq "window-status-format" \
	"#[bg=default, fg=$color_fg_light] #I ┃ #[fg=$color_fg_base, nobold]#W #[fg=$color_fg_light,bold]#F "

tmux set-option -gq "window-status-current-format" \
	"#[bg=$color_secondary, fg=$color_fg_light, bold] #I ┃ #[fg=$color_fg_base, nobold]#W #[fg=$color_fg_light,bold]#F "

# status right
username="$(whoami)"
right_length="$((42 + ${#username}))"

tmux set-option -gq "status-right-attr" "none"
tmux set-option -gq "status-right-length" "$right_length"

status_widgets=$(get "@my_widgets" "")
time_format="%I:%M:%S %p"
date_format=$(get "@my_date_format" "%d/%m/%Y")

if [[ "$(battery_status)" != "" ]]; then
	tmux set-option -gq "status-right" \
		"#[bg=$color_terceary, fg=$color_fg_light, bold]  ${time_format} ┃  ${date_format} #[bg=$color_secondary, fg=$color_fg_light] ${status_widgets} #[bg=$color_primary, fg=$color_fg_dark] #h "
else
	tmux set-option -gq "status-right" \
		"#[bg=$color_terceary, fg=$color_fg_light, bold]  ${time_format} ┃  ${date_format} #[bg=$color_primary, fg=$color_fg_dark] #h "
fi

# borders
if [[ "$(cat ~/.theme_mode)" != "light" ]]; then
	tmux set-option -gq "pane-active-border-style" "bg=default, fg=$color_primary"
	tmux set-option -gq "pane-border-style" "bg=default, fg=$color_fg_light"
else
	tmux set-option -gq "pane-active-border-style" "bg=default, fg=$color_primary"
	tmux set-option -gq "pane-border-style" "bg=default, fg=$color_fg_light"
fi
