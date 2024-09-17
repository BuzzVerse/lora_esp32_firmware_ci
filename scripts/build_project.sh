#!/bin/bash

# Usage: build_project.sh [-b branch_name | -t tag | -c commit_hash | -p project_path]

# Initialize variables
CURRENT_ESP_PROJECT_DIR=""
CONTAINER_NAME="esp32_builder"
IS_LOCAL_BUILD=false

# Use SCRIPT_DIR if ESP_CI_PROJECT_DIR is not set
ESP_CI_PROJECT_DIR="${ESP_CI_PROJECT_DIR:-$SCRIPT_DIR}"

cd "$ESP_CI_PROJECT_DIR"

# Define paths relative to PROJECT_DIR
FETCH_SCRIPT="$ESP_CI_PROJECT_DIR/scripts/fetch.sh"
DOCKER_COMPOSE_FILE="$ESP_CI_PROJECT_DIR/docker-compose.yml"
CONTAINER_NAME="esp32_builder"
ARTIFACTS_DIR="$ESP_CI_PROJECT_DIR/artifacts"
BUILD_LOGS="$ESP_CI_PROJECT_DIR/build_logs.txt"

# Parse command line arguments first
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
      IS_LOCAL_BUILD=true
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

# Now check if any arguments are passed
if [ $# -eq 0 ]; then
  # No parameters passed, check if LOCAL_ESP_PROJECT_PATH is set
  if [ -z "$LOCAL_ESP_PROJECT_PATH" ]; then
    echo "Error: No parameters provided and LOCAL_ESP_PROJECT_PATH is not set."
    echo "Provide a project path with -p option or set LOCAL_ESP_PROJECT_PATH environment variable."
    exit 1
  else
    # Use LOCAL_ESP_PROJECT_PATH if no parameters are passed but the environment variable is set
    echo "No parameters provided, using default: $LOCAL_ESP_PROJECT_PATH"
    ESP_PROJECT_DIR="$LOCAL_ESP_PROJECT_PATH"
    IS_LOCAL_BUILD=true  # Treat it as a local build if no parameters provided
  fi
fi

# If ESP_PROJECT_DIR is still not set, use default /tmp directory
if [ -z "$ESP_PROJECT_DIR" ]; then
  ESP_PROJECT_DIR="$ESP_CI_PROJECT_DIR/tmp"
fi

# Check if the provided or default project path exists and is a valid ESP32 project
if [ ! -d "$ESP_PROJECT_DIR" ]; then
  echo "Error: The project directory does not exist: $ESP_PROJECT_DIR"
  exit 1
fi

# Check for the presence of `idf_component_register` in the CMakeLists.txt file
CMAKE_FILE="$ESP_PROJECT_DIR/main/CMakeLists.txt"
if [ ! -f "$CMAKE_FILE" ] || ! grep -q "idf_component_register" "$CMAKE_FILE"; then
  echo "Error: The project in $ESP_PROJECT_DIR is not a valid ESP32 project."
  echo "Missing 'idf_component_register' in $CMAKE_FILE"
  exit 1
fi

# Save the current directory to return to it later
CURRENT_DIR=$(pwd)

# Change to the project directory
echo "Changing to CI project directory: $ESP_CI_PROJECT_DIR"
# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Only run fetch_code.sh if we are not doing a local build
if [ "$IS_LOCAL_BUILD" = false ]; then
  # Run the fetch_code.sh script with the same arguments
  echo "Running fetch_code.sh to pull the desired version of the repository..."
  bash "$FETCH_SCRIPT" "$@" 2>&1 | tee -a "$BUILD_LOGS"
  if [ $? -ne 0 ]; then
    echo "Error: Failed to fetch code." | tee -a "$BUILD_LOGS"
    cd "$CURRENT_DIR"
    exit 1
  fi
fi

# Check if the docker-compose file exists
if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
  echo "Error: Docker Compose file ($DOCKER_COMPOSE_FILE) not found." | tee -a "$BUILD_LOGS"
  cd "$CURRENT_DIR"
  exit 1
fi

if [ "$IS_LOCAL_BUILD" = false ]; then
  # Ensure ownership of the tmp directory is set to the current user
  if [ -d "$ARTIFACTS_DIR" ]; then
    echo "Setting ownership of $ARTIFACTS_DIR to the host user..." | tee -a "$BUILD_LOGS"
    sudo chown -R $(id -u):$(id -g) "$ARTIFACTS_DIR"
  fi
fi

# If not a local build, prepare artifacts directory
if [ "$IS_LOCAL_BUILD" = false ]; then
  if [ -d "$ARTIFACTS_DIR" ]; then
    echo "Cleaning existing artifacts directory: $ARTIFACTS_DIR" | tee -a "$BUILD_LOGS"
    rm -rf "$ARTIFACTS_DIR/"{*,.[!.]*,..?*} 2>/dev/null
  else
    echo "Creating artifacts directory: $ARTIFACTS_DIR" | tee -a "$BUILD_LOGS"
    mkdir -p "$ARTIFACTS_DIR"
  fi
fi

# Start the Docker container
echo "Starting Docker container..." | tee -a "$BUILD_LOGS"
export ESP_PROJECT_DIR
docker-compose -f "$DOCKER_COMPOSE_FILE" up --build -d 2>&1 | tee -a "$BUILD_LOGS"

# Wait a few seconds to ensure the container is running
sleep 10

if [ "$IS_LOCAL_BUILD" = true ]; then
  echo "Launching menuconfig for ESP-IDF project at: $ESP_PROJECT_DIR" | tee -a "$BUILD_LOGS"
  docker exec -it "$CONTAINER_NAME" /bin/bash -c "cd /usr/local/build && idf.py build"
else
  echo "Running build.sh script inside the container..." | tee -a "$BUILD_LOGS"
  docker exec -it "$CONTAINER_NAME" /bin/bash -c "/usr/local/scripts/build.sh" 2>&1 | tee -a "$BUILD_LOGS"
fi

BUILD_STATUS=$?

if [ "$IS_LOCAL_BUILD" = false ]; then
  # Fetch build logs from the container
  if [ $BUILD_STATUS -ne 0 ]; then
    echo "Build failed. Fetching container logs..." | tee -a "$BUILD_LOGS"
    docker logs "$CONTAINER_NAME" | tee -a "$BUILD_LOGS"
  else
    echo "Build succeeded!" | tee -a "$BUILD_LOGS"

    # Copy build artifacts from the container to the ARTIFACTS_DIR
    echo "Copying build artifacts from container to $ARTIFACTS_DIR..." | tee -a "$BUILD_LOGS"
    docker cp "$CONTAINER_NAME:/usr/local/build" "$ARTIFACTS_DIR"
  fi
fi

# Stop and remove the Docker container
echo "Stopping and removing the Docker container..." | tee -a "$BUILD_LOGS"
docker-compose -f "$DOCKER_COMPOSE_FILE" down 2>&1 | tee -a "$BUILD_LOGS"

# Return to the original directory
echo "Returning to the original directory: $CURRENT_DIR" | tee -a "$BUILD_LOGS"
cd "$CURRENT_DIR"
