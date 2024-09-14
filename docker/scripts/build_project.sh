#!/bin/bash

# Użycie: build_project.sh [-b branch_name | -t tag | -c commit_hash]
FETCH_SCRIPT="./fetch.sh"
DOCKER_COMPOSE_FILE="../../docker-compose.yml"
CONTAINER_NAME="esp32_builder"
ARTIFACTS_DIR="./artifacts"
BUILD_LOGS="./build_logs.txt"

# 1. Wywołanie skryptu fetch_code.sh z tymi samymi argumentami
echo "Running fetch_code.sh to pull the desired version of the repository..."
bash $FETCH_SCRIPT "$@"
if [ $? -ne 0 ]; then
  echo "Error: Failed to fetch code."
  exit 1
fi

# 2. Sprawdzenie, czy plik docker-compose istnieje
if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
  echo "Error: Docker Compose file ($DOCKER_COMPOSE_FILE) not found."
  exit 1
fi

# 3. Przygotowanie katalogu ARTIFACTS_DIR
if [ -d "$ARTIFACTS_DIR" ]; then
  echo "Cleaning existing artifacts directory: $ARTIFACTS_DIR"
  rm -rf "$ARTIFACTS_DIR/*"
else
  echo "Creating artifacts directory: $ARTIFACTS_DIR"
  mkdir -p "$ARTIFACTS_DIR"
fi

# 4. Uruchomienie kontenera i budowanie projektu
echo "Starting Docker container and building the project..."
docker-compose up --build # Remove `-d` to ensure real-time logging

# 5. Budowanie projektu w kontenerze
echo "Building project inside container..."
docker exec -it "$CONTAINER_NAME" /bin/bash -c "cd /tmp && idf.py build"
BUILD_STATUS=$?

# 6. Pobranie logów z kontenera (opcjonalne, jeśli potrzebujesz logi zapisać)
echo "Fetching build logs..."
docker logs "$CONTAINER_NAME" | tee "$BUILD_LOGS"

if [ $BUILD_STATUS -eq 0 ]; then
  echo "Build succeeded!"

  # 7. Skopiowanie artefaktów
  echo "Copying build artifacts from container to $ARTIFACTS_DIR..."
  docker cp "$CONTAINER_NAME:/tmp/project/build" "$ARTIFACTS_DIR"

  echo "Artifacts copied to $ARTIFACTS_DIR."
else
  echo "Build failed. Check build logs in $BUILD_LOGS."
fi

# 8. Wyczyszczenie kontenera
echo "Stopping and removing the Docker container..."
docker-compose down

# 9. Informowanie o wyniku
if [ $BUILD_STATUS -eq 0 ]; then
  echo "Build process completed successfully."
else
  echo "Build process failed."
  exit 1
fi