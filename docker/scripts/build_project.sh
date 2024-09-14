#!/bin/bash

# Usage: build_project.sh [-b branch_name | -t tag | -c commit_hash]

# Check if PROJECT_DIR environment variable is set
if [ -z "$PROJECT_DIR" ]; then
  echo "Error: PROJECT_DIR environment variable is not set. Please ensure it is set by running install.sh."
  exit 1
fi

# Check if the directory stored in PROJECT_DIR exists
if [ ! -d "$PROJECT_DIR" ]; then
  echo "Error: Directory set in PROJECT_DIR does not exist: $PROJECT_DIR"
  exit 1
fi

# Save the current directory to return to it later
CURRENT_DIR=$(pwd)

# Change to the project directory stored in PROJECT_DIR
echo "Changing to project directory: $PROJECT_DIR"
cd "$PROJECT_DIR"

# Define paths relative to PROJECT_DIR
FETCH_SCRIPT="$PROJECT_DIR/docker/scripts/fetch.sh"
DOCKER_COMPOSE_FILE="$PROJECT_DIR/docker-compose.yml"
CONTAINER_NAME="esp32_builder"
ARTIFACTS_DIR="$PROJECT_DIR/artifacts"
BUILD_LOGS="$PROJECT_DIR/build_logs.txt"

# 1. Run the fetch_code.sh script with the same arguments
echo "Running fetch_code.sh to pull the desired version of the repository..."
bash "$FETCH_SCRIPT" "$@"
if [ $? -ne 0 ]; then
  echo "Error: Failed to fetch code."
  cd "$CURRENT_DIR"
  exit 1
fi

# 2. Check if the docker-compose file exists
if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
  echo "Error: Docker Compose file ($DOCKER_COMPOSE_FILE) not found."
  cd "$CURRENT_DIR"
  exit 1
fi

# 3. Prepare the ARTIFACTS_DIR
if [ -d "$ARTIFACTS_DIR" ]; then
  echo "Cleaning existing artifacts directory: $ARTIFACTS_DIR"
  rm -rf "$ARTIFACTS_DIR/*"
else
  echo "Creating artifacts directory: $ARTIFACTS_DIR"
  mkdir -p "$ARTIFACTS_DIR"
fi

# 4. Start the Docker container and build the project
echo "Starting Docker container and building the project..."
docker-compose -f "$DOCKER_COMPOSE_FILE" up --build  # Use the correct docker-compose.yml file

# 5. Build the project inside the container
echo "Building project inside container..."
docker exec -it "$CONTAINER_NAME" /bin/bash -c "cd /tmp && idf.py build"
BUILD_STATUS=$?

# 6. Fetch build logs from the container (optional, if you need logs saved)
echo "Fetching build logs..."
docker logs "$CONTAINER_NAME" | tee "$BUILD_LOGS"

if [ $BUILD_STATUS -eq 0 ]; then
  echo "Build succeeded!"

  # 7. Copy build artifacts from the container to the ARTIFACTS_DIR
  echo "Copying build artifacts from container to $ARTIFACTS_DIR..."
  docker cp "$CONTAINER_NAME:/tmp/project/build" "$ARTIFACTS_DIR"

  echo "Artifacts copied to $ARTIFACTS_DIR."
else
  echo "Build failed. Check build logs in $BUILD_LOGS."
fi

# 8. Stop and remove the Docker container
echo "Stopping and removing the Docker container..."
docker-compose -f "$DOCKER_COMPOSE_FILE" down

# 9. Notify about the result
if [ $BUILD_STATUS -eq 0 ]; then
  echo "Build process completed successfully."
else
  echo "Build process failed."
  cd "$CURRENT_DIR"
  exit 1
fi

# Return to the original directory
echo "Returning to the original directory: $CURRENT_DIR"
cd "$CURRENT_DIR"

# Confirm we are back in the original directory
echo "Now in original directory: $(pwd)"