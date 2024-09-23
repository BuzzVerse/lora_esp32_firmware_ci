#!/bin/bash

export ESP_PROJECT_DIR=${ESP_PROJECT_DIR:-./}

# Starting the container with docker-compose
docker compose up -d

# Checking if the container is running
container_name="esp32_builder"
if [ "$(docker ps -q -f name=$container_name)" ]; then
    echo "Container $container_name is running, generating SSH key..."

    # Executing the command inside the container: generating SSH key
    docker exec -it $container_name bash -c "ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ''"

    # Retrieving the public key from the container
    docker exec -it $container_name bash -c "cat ~/.ssh/id_rsa.pub"
else
    echo "Container $container_name is not running!"
    exit 1
fi