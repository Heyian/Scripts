#!/bin/bash

# Define the file path
file_path="/usr/share/sddm/themes/Sweet/theme.conf.user"

# Use sed to replace the line
sed -i 's/^Background=.*/Background="assets\/gBSxkyX.jpeg"/' "$file_path"

