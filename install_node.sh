#!/bin/bash

# Defining variables
JENKINS_KEY="jenkins_node_secret"

#Check if the 'jenkins' user exists
if id "jenkins" &>/dev/null; then
    echo "User 'jenkins' already exists."
else
    #Add the 'jenkins' user if it doesn't exist
    echo "User 'jenkins' does not exist. Adding user 'jenkins'..."
    sudo useradd -m -s /bin/bash jenkins
fi

#Check if the 'docker' group exists
if getent group docker &>/dev/null; then
    echo "Group 'docker' already exists."
else
    #Create the 'docker' group if it doesn't exist
    echo "Group 'docker' does not exist. Creating group 'docker'..."
    sudo groupadd docker
fi

#Check if the 'jenkins' user belongs to the 'docker' group
if groups jenkins | grep &>/dev/null "\bdocker\b"; then
    echo "User 'jenkins' already belongs to the 'docker' group."
else
    #Add the 'jenkins' user to the 'docker' group if not a member
    echo "Adding user 'jenkins' to the 'docker' group..."
    sudo usermod -aG docker jenkins
fi

#Change group ownership of all files in PWD to 'docker'
echo "Changing group ownership of all files in $(pwd) to 'docker'..."
chown -R :docker "$(pwd)"

echo "All steps completed."

#Asking to change the Jenkins Node key
read -p "Do you want to change the Jenkins Node key? (y/n): " change_key
if [[ $change_key == "y" || $change_key == "Y" ]]; then
  read -p "Enter the new Jenkins Node key: " new_jenkins_key
  JENKINS_KEY=$new_jenkins_key
  echo "The Jenkins Node key has been updated."
  #Replacing the key in the docker-compose.yml file
  if [ -f "$COMPOSE_FILE" ]; then
    sed -i "s|<jenkins_encryption_key>|$JENKINS_KEY|g" "$COMPOSE_FILE"
    echo "The $COMPOSE_FILE file has been updated with the new Jenkins Node key."
  else
    echo "$COMPOSE_FILE file does not exist."
  fi
fi

docker build -t jenkins_node:latest -f Dockerfile_jenkins_node .

#Change group ownership of all files in PWD to 'docker'
echo "Changing group ownership of all files in $(pwd) to 'docker'..."
chown -R :docker "$(pwd)"