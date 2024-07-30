#!/bin/bash

EXCLUDED_THEMES=("bgrt" "details" "fade-in" "glow" "script" "solar" "spinfinity" "spinner" "text" "tribar")

#Ensure the script is run with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo."
    exec sudo "$0" "$@"
fi


function list_themes ()
{
    for theme in /usr/share/plymouth/themes/*/*.plymouth; do
	[ -f $theme ] || continue;
	echo "$(basename "$theme" .plymouth)"
    done
}

function list_custom_themes ()
{
    for theme in /usr/share/plymouth/themes/*/*.plymouth; do
	[ -f $theme ] || continue;
	theme_name=$(basename "$theme" .plymouth)

	for exclude_theme in "${EXCLUDED_THEMES[@]}"; do
	    if [[ "$theme_name" == "$exclude_theme" ]]; then
                continue 2 # Skip the inner loop and move to the next theme
            fi
        done

        echo "$theme_name"
    done
}

function select_random_theme ()
{
    local themes=($(list_custom_themes))

    local random_index=$((RANDOM % ${#themes[@]}))

    echo ${themes[$random_index]}
}

function get_current_theme()
{
    local theme=$(sed -n '3p' /etc/plymouth/plymouthd.conf | awk -F '=' '{print $2}')
    echo "$theme"
}

echo "The current theme is : $(get_current_theme)"

NEW_THEME=$(select_random_theme)

echo "The new theme will be : $NEW_THEME"

/usr/bin/plymouth-set-default-theme $NEW_THEME

dracut --force --hostonly --no-hostonly-cmdline /boot/initramfs-linux-zen.img
