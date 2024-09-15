#!/bin/bash

# Usage: build_project.sh [-b branch_name | -t tag | -c commit_hash | -p project_path]

# Check if PROJECT_DIR environment variable is set
if [ -z "$PROJECT_DIR" ]; then
  echo "Error: PROJECT_DIR environment variable is not set. Please ensure it is set by running install.sh."
  echo "Example: sudo ./install.sh"
  exit 1
fi

# Initialize variables
ESP_PROJECT_DIR=""
DEFAULT_ESP_PROJECT=${ESP_PROJECT_DIR:-$PROJECT_DIR/esp_project}

# Parse command line arguments
while getopts ":b:c:t:p:" opt; do
  case ${opt} in
    b )
      BRANCH=$OPTARG
      ;;
    c )
      COMMIT=$OPTARG
      ;;
    t )
      TAG=$OPTARG
      ;;
    p )
      ESP_PROJECT_DIR=$OPTARG
      ;;
    \? )
      echo "Invalid option: -$OPTARG" 1>&2
      exit 1
      ;;
    : )
      echo "Option -$OPTARG requires an argument." 1>&2
      exit 1
      ;;
  esac
done

# If no parameters are provided, check if ESP_PROJECT_DIR is set and use it as default
if [ -z "$BRANCH" ] && [ -z "$COMMIT" ] && [ -z "$TAG" ] && [ -z "$ESP_PROJECT_DIR" ]; then
  if [ -z "$DEFAULT_ESP_PROJECT" ]; then
    echo "No parameters provided and no default project set."
    echo "Please configure your ESP32 project path using the install script."
    echo "Example: sudo ./install.sh"
    exit 1
  else
    echo "No parameters provided, building default ESP32 project: $DEFAULT_ESP_PROJECT"
    ESP_PROJECT_DIR="$DEFAULT_ESP_PROJECT"
  fi
fi

# Check if the provided or default project path exists and is a valid ESP32 project
if [ -n "$ESP_PROJECT_DIR" ]; then
  if [ ! -d "$ESP_PROJECT_DIR" ]; then
    echo "Error: The provided project directory does not exist: $ESP_PROJECT_DIR"
    exit 1
  fi

  # Check for the presence of `idf_component_register` in the CMakeLists.txt file
  CMAKE_FILE="$ESP_PROJECT_DIR/main/CMakeLists.txt"
  if [ ! -f "$CMAKE_FILE" ] || ! grep -q "idf_component_register" "$CMAKE_FILE"; then
    echo "Error: The project in $ESP_PROJECT_DIR is not a valid ESP32 project."
    echo "Missing 'idf_component_register' in $CMAKE_FILE"
    exit 1
  fi
fi

# Save the current directory to return to it later
CURRENT_DIR=$(pwd)

# Change to the project directory
echo "Changing to project directory: $ESP_PROJECT_DIR"
cd "$ESP_PROJECT_DIR"

# Define paths relative to PROJECT_DIR
FETCH_SCRIPT="$PROJECT_DIR/scripts/fetch.sh"
DOCKER_COMPOSE_FILE="$PROJECT_DIR/docker-compose.yml"
CONTAINER_NAME="esp32_builder"
ARTIFACTS_DIR="$PROJECT_DIR/artifacts"
BUILD_LOGS="$PROJECT_DIR/build_logs.txt"

# Run the fetch_code.sh script with the same arguments
echo "Running fetch_code.sh to pull the desired version of the repository..."
bash "$FETCH_SCRIPT" "$@"
if [ $? -ne 0 ]; then
  echo "Error: Failed to fetch code."
  cd "$CURRENT_DIR"
  exit 1
fi

# Check if the docker-compose file exists
if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
  echo "Error: Docker Compose file ($DOCKER_COMPOSE_FILE) not found."
  cd "$CURRENT_DIR"
  exit 1
fi

# Ensure ownership of the tmp directory is set to the current user
if [ -d "$ARTIFACTS_DIR" ]; then
  echo "Setting ownership of $ARTIFACTS_DIR to the host user..."
  sudo chown -R $(id -u):$(id -g) "$ARTIFACTS_DIR"
fi

# Prepare the ARTIFACTS_DIR
if [ -d "$ARTIFACTS_DIR" ]; then
  echo "Cleaning existing artifacts directory: $ARTIFACTS_DIR"
  rm -rf "$ARTIFACTS_DIR/"{*,.[!.]*,..?*} 2>/dev/null
else
  echo "Creating artifacts directory: $ARTIFACTS_DIR"
  mkdir -p "$ARTIFACTS_DIR"
fi

# Start the Docker container
echo "Starting Docker container..."
docker-compose -f "$DOCKER_COMPOSE_FILE" up --build -d

# Wait a few seconds to ensure the container is running
sleep 5

# Run the build.sh script inside the container
echo "Running build.sh script inside the container..."
docker exec -it "$CONTAINER_NAME" /bin/bash -c "/usr/local/scripts/build.sh"

BUILD_STATUS=$?

# Fetch build logs from the container (optional, if you need logs saved)
echo "Fetching build logs..."
docker logs "$CONTAINER_NAME" | tee "$BUILD_LOGS"

if [ $BUILD_STATUS -eq 0 ]; then
  echo "Build succeeded!"

  # Copy build artifacts from the container to the ARTIFACTS_DIR
  echo "Copying build artifacts from container to $ARTIFACTS_DIR..."
  docker cp "$CONTAINER_NAME:/usr/local/build" "$ARTIFACTS_DIR"

  echo "Artifacts copied to $ARTIFACTS_DIR."
else
  echo "Build failed. Check build logs in $BUILD_LOGS."
fi

# Stop and remove the Docker container
echo "Stopping and removing the Docker container..."
docker-compose -f "$DOCKER_COMPOSE_FILE" down

# Notify about the result
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