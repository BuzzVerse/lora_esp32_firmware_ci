#!/bin/bash

# Ensure the script is run with root privileges when necessary (for system-wide changes)
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with sudo to modify system-wide settings."
  exit 1
fi

# Path to the project directory (where install.sh is being run from)
PROJECT_DIR="$(pwd)"

# Save the project directory path in a system-wide environment variable file
echo "Setting up project directory environment variable in /etc/profile.d/..."
echo "export PROJECT_DIR=\"$PROJECT_DIR\"" > /etc/profile.d/project_env.sh

# Ensure that the environment variable is written successfully
if [ $? -ne 0 ]; then
  echo "Error: Failed to write environment variable to /etc/profile.d/project_env.sh"
  exit 1
fi

# Set the path to the build_project.sh script
BUILD_SCRIPT_PATH="$PROJECT_DIR/docker/scripts/build_project.sh"

# Ensure that build_project.sh exists
if [ ! -f "$BUILD_SCRIPT_PATH" ]; then
  echo "Error: build_project.sh not found in docker/scripts/"
  exit 1
fi

# Set execute permissions on all scripts in the docker/scripts directory
SCRIPTS_DIR="$PROJECT_DIR/docker/scripts"
echo "Setting execute permissions on all scripts in $SCRIPTS_DIR..."
chmod +x "$SCRIPTS_DIR"/*.sh

# Check if permission change was successful
if [ $? -eq 0 ]; then
  echo "Permissions set successfully on all scripts."
else
  echo "Error: Failed to set permissions on scripts."
  exit 1
fi

# Create a symbolic link to build_project.sh in /usr/local/bin
# This allows the script to be called globally as "build_project"
echo "Creating symlink for build_project.sh in /usr/local/bin..."
ln -sf "$BUILD_SCRIPT_PATH" /usr/local/bin/build_project

# Check if the symlink was created successfully
if [ $? -eq 0 ]; then
  echo "Installation successful. You can now run 'build_project' from anywhere."
else
  echo "Error: Failed to create symlink."
  exit 1
fi

# Now run non-root operations to set PROJECT_DIR for the current user session
echo "Reloading PROJECT_DIR environment variable for the current user..."

# Add PROJECT_DIR to ~/.bashrc to make it persistent in the user session
echo "export PROJECT_DIR=\"$PROJECT_DIR\"" >> /home/$SUDO_USER/.bashrc

# Set the variable in the current session
sudo -u $SUDO_USER bash -c "source /home/$SUDO_USER/.bashrc"

echo "Installation completed. PROJECT_DIR is set to $PROJECT_DIR."
echo "Please run 'source ~/.bashrc' or restart the terminal for changes to take effect."