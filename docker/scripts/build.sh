#!/bin/bash

# Load ESP-IDF environment
source /opt/esp/idf/export.sh

# Build the project with verbose logging
echo "Building ESP project with verbose logging"
cd /usr/local/build

# Execute the build command
idf.py -v build

# Check if the build was successful
if [ $? -ne 0 ]; then
  echo "Build failed. Check logs for more details."
  exit 1
else
  echo "Build succeeded."
fi