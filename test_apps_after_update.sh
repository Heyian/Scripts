#!/bin/bash

# Ensure the script is run with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo."
    exec sudo -E "$0" "$@"
fi

# Define variables 
LOGFILE="/var/log/test_apps_after_updates.log"
NVIMFILE="{any-file-to-open-with-nvim}"
PROJECTDIR="{your-project-dir}"

# Clear the log file
> "$LOGFILE"

# Redirect all output to the log file
exec > >(tee -a "$LOGFILE") 2>&1

# Define a list of applications to test with sudo -E
sudo_apps=("btrfs-assistant-launcher")

# Define a list of applications to test without sudo
user_apps=("vscodium" "kitty nvim $NVIMFILE")

# Define a list of applications to test without sudo and suppress output
suppress_output_apps=("firedragon" "chromium" "waypaper-engine run")

# Define the Docker containers to check
containers=("laravel.test-1" "redis-1" "mysql_testing-1" "mysql-1")

# Initialize summary variables
summary=()
success_count=0
failure_count=0

# Define color codes
green='\033[0;32m'
red='\033[0;31m'
clear='\033[0m'

# Function to send notifications to the user
send_notification() {
    local title=$1
    local message=$2
    sudo -u "$SUDO_USER" DISPLAY=":$(find /tmp/.X11-unix -type s | grep -Pom1 '/tmp/.X11-unix/X\K\d+$')" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$SUDO_USER")/bus" \
        notify-send "$title" "$message" --icon=error
}

# Function to test if an application launches
test_app() {
    local app=$1
    local use_sudo=$2
    local suppress_output=$3
    echo "Testing $app..."
    pkill -f "$app" 2>/dev/null  # Ensure the app isn't already running
    if [ "$use_sudo" = true ]; then
        if [ "$suppress_output" = true ]; then
            sudo -E $app &>/dev/null &  # Attempt to start the app with sudo, suppressing output
        else
            sudo -E $app &  # Attempt to start the app with sudo
        fi
    else
        if [ "$suppress_output" = true ]; then
            sudo -u $SUDO_USER $app &>/dev/null &  # Attempt to start the app without sudo, suppressing output
        else
            sudo -u $SUDO_USER $app &  # Attempt to start the app without sudo
        fi
    fi
    sleep 2  # Wait for the app to start
    pgrep -f "$app" > /dev/null  # Check if the app is running
    local result=$?
    pkill -SIGTERM "$app" 2>/dev/null  # Stop the app
    local resultkill=$?
    #If the app is still running, force kill it
    if [ $resultkill -ne 0 ]; then
        pkill -f "$app" 2>/dev/null
    fi
    return $result
}

# Function to test if the Docker containers are running
test_docker_containers() {
    echo "Testing Docker containers..."
    cd $PROJECTDIR || { echo "Failed to change directory"; return 1; }
    ./vendor/bin/sail up -d
    sleep 5  # Wait for the containers to start

    for container in "${containers[@]}"; do
        if ! docker ps --format '{{.Names}}' | grep -q "$container"; then
            echo "$container is not running."
            send_notification "Docker Container Failure" "$container is not running."
            ./vendor/bin/sail down
            return 1
        fi
    done

    # Check if the URL returns a 200 status code after following redirects
    status_code=$(curl -L --write-out %{http_code} --silent --output /dev/null http://127.0.0.1/app)
    if [[ "$status_code" -ne 200 ]]; then
        echo "http://127.0.0.1/app returned status code $status_code."
        send_notification "HTTP Check Failure" "http://127.0.0.1/app returned status code $status_code."
        ./vendor/bin/sail down
        return 1
    fi

    echo "All Docker containers are running and http://127.0.0.1/app returned status code 200."
    ./vendor/bin/sail down
    sleep 5
    return 0
}

# Function to test if "hyprpm update" runs without "fail" in the output
test_hyprpm_update() {
    echo "Running/Testing hyprpm update..."
    output=$(hyprpm update)
    if echo "$output" | grep -iq "fail"; then
        echo "hyprpm update failed with output: $output"
        send_notification "Hyprpm Update Failure" "hyprpm update failed with output: $output"
        return 1
    fi
    echo "hyprpm update succeeded."
    hyprpm reload -n
    return 0
}

#Function to verify if there's a Restic lock file present in /tmp/
check_lock_file() {
    local directory="/tmp/"
    local prefix="restic"
    local extension=".lock"

    for file in "$directory"/*; do
        if [[ -f "$file" && "$(basename "$file")" == $prefix* && "$file" == *$extension ]]; then
            echo "Restic lock file $file exists."
            return 1
        fi
    done
    return 0
}

# Iterate over the list of applications that need sudo and test each one
for app in "${sudo_apps[@]}"; do
    test_app "$app" true false
    if [ $? -eq 0 ]; then
        echo "$app launched successfully."
        summary+=("$app: ✅")
        ((success_count++))
    else
        echo "$app failed to launch."
        send_notification "App Failure" "$app failed to launch."
        summary+=("$app: ❌")
        ((failure_count++))
    fi
done

# Iterate over the list of applications that don't need sudo and test each one
for app in "${user_apps[@]}"; do
    test_app "$app" false false
    if [ $? -eq 0 ]; then
        echo "$app launched successfully."
        summary+=("$app: ✅")
        ((success_count++))
    else
        echo "$app failed to launch."
        send_notification "App Failure" "$app failed to launch."
        summary+=("$app: ❌")
        ((failure_count++))
    fi
done

# Iterate over the list of applications that don't need sudo and suppress output
for app in "${suppress_output_apps[@]}"; do
    test_app "$app" false true
    if [ $? -eq 0 ]; then
        echo "$app launched successfully."
        summary+=("$app: ✅")
        ((success_count++))
    else
        echo "$app failed to launch."
        send_notification "App Failure" "$app failed to launch."
        summary+=("$app: ❌")
        ((failure_count++))
    fi
done

# Test the Docker containers
test_docker_containers
if [ $? -eq 0 ]; then
    echo "Docker containers and HTTP check passed successfully."
    summary+=("Docker containers and HTTP check: ✅")
    ((success_count++))
else
    echo "Docker containers or HTTP check failed."
    summary+=("Docker containers and HTTP check: ❌")
    ((failure_count++))
fi

# Test hyprpm update
# I disabled this check because I currently don't use any hyprland plugins
# test_hyprpm_update
# if [ $? -eq 0 ]; then
#     echo "hyprpm update passed successfully."
#     summary+=("hyprpm update: ✅")
#     ((success_count++))
# else
#     echo "hyprpm update failed."
#     summary+=("hyprpm update: ❌")
#     ((failure_count++))
# fi

# Verify there's no Restic lock file
check_lock_file
if [ $? -eq 0 ]; then
    echo "No restic lock file found."
    summary+=("Restic lock file: ✅")
    ((success_count++))
else
    echo "Restic lock file found."
    summary+=("Restic lock file: ❌")
    ((failure_count++))
fi


# Print summary
echo -e "${green}----------------------------------------------------"
echo -e "${green}Summary of checks:${clear}"
for item in "${summary[@]}"; do
    echo "$item"
done
echo -e "${green}Total successful tests: $success_count"
echo -e "${red}Total failed tests: $failure_count"

