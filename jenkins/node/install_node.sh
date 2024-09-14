#!/bin/bash

# Defining variables
SSH_DIR="./ssh"
AGENT_DIR="./agent"
COMPOSE_FILE="docker-compose.yml"
JENKINS_KEY="jenkins_node_secret"

# Checking if the .ssh folder exists
if [ ! -d "$SSH_DIR" ]; then
  echo "The ssh folder does not exist. Creating the folder..."
  mkdir -p "$SSH_DIR"
  echo "The folder $SSH_DIR has been created."
else
  echo "The ssh folder already exists."
fi

# Checking if the agent folder exists
if [ ! -d "$AGENT_DIR" ]; then
  echo "The agent folder does not exist. Creating the folder..."
  mkdir -p "$AGENT_DIR"
  echo "The folder $AGENT_DIR has been created."
else
  echo "The agent folder already exists."
fi

# Asking to change the Jenkins Node key
read -p "Do you want to change the Jenkins Node key? (y/n): " change_key
if [[ $change_key == "y" || $change_key == "Y" ]]; then
  read -p "Enter the new Jenkins Node key: " new_jenkins_key
  JENKINS_KEY=$new_jenkins_key
  echo "The Jenkins Node key has been updated."
fi

# Replacing the key in the docker-compose.yml file
if [ -f "$COMPOSE_FILE" ]; then
  sed -i "s|<jenkins_encryption_key>|$JENKINS_KEY|g" "$COMPOSE_FILE"
  echo "The $COMPOSE_FILE file has been updated with the new Jenkins Node key."
else
  echo "$COMPOSE_FILE file does not exist."
fi

# Checking if the SSH key exists
if [ ! -f "$SSH_DIR/id_rsa.pub" ]; then
  echo "The SSH public key does not exist. Generating a new SSH key..."
  ssh-keygen -t rsa -b 4096 -f "$SSH_DIR/id_rsa" -N ""
  echo "The SSH key has been generated."
  echo "Below is the public key that needs to be added to GitHub:"
  echo "-----------------------------------------"
  echo "      ██████                                  "
  echo "    ██    ░░████                              "
  echo "  ██  ░░░░░░░░  ████                          "
  echo "██  ░░░░██░░░░░░    ████████████████████████  "
  echo "██  ░░██  ██▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░    ██"
  echo "██░░░░██  ██▒▒░░░░░░░░░░░░░░░░░░░░░░██░░░░░░██"
  echo "██░░░░░░██░░░░░░░░░░████████████▒▒██  ██░░▒▒██"
  echo "  ██░░░░░░░░░░░░████          ██▒▒██  ██▒▒▒▒██"
  echo "    ██░░░░░░████                ██      ████  "
  echo "      ██████                                  "
  echo "-----------------------------------------"
  echo "SSH Key:"
  cat "$SSH_DIR/id_rsa.pub"
else
  echo "The SSH public key already exists."
fi

# Configuring SSH access to GitHub
echo "Configuring SSH key for GitHub..."
cat <<EOL > "$SSH_DIR/config"
Host github.com
  HostName github.com
  User git
  IdentityFile /home/jenkins/.ssh/id_rsa
  IdentitiesOnly yes
EOL
echo "GitHub SSH access configuration completed."