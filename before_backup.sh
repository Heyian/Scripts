#!/bin/bash

saildir="{Change this to project dir}"
homedir="{Change this to your home dir}"
echo "Stopping project docker container"
$saildir/vendor/bin/sail -f $saildir/docker-compose.yml down

echo "Closing thunar instances"
thunar -q

echo "Closing zellij sessions"
zellij kill-all-sessions -y

echo "Unmounting SSHFS"
fusermount3 -u $homedir/sshfs



# Define the folder path
folder_path="$homedir/sshfs/"

# Check if the folder is empty
if [ -z "$(ls -A "$folder_path")" ]; then
    folder_empty=true
else
    folder_empty=false
fi

# Check if there are no Docker containers running
if [ -z "$(docker ps -q)" ]; then
    no_containers_running=true
else
    no_containers_running=false
fi

# Check if both conditions are true
if [ "$folder_empty" = true ] && [ "$no_containers_running" = true ]; then
    echo "Folder is empty and no Docker containers are running."
    exit 0
else
    echo "Conditions not met:"
    [ "$folder_empty" = false ] && echo "- Folder is not empty"
    [ "$no_containers_running" = false ] && echo "- Docker containers are running"
    exit 1
fi
