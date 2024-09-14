#!/bin/bash

cd /usr/local/build

ls -a

source /opt/esp/idf/export.sh
idf.py set-target esp32
idf.py build monitor


# Wait for the process to complete
if [ $? -ne 0 ]; then
  echo "Build failed. Check logs for more details."
  exit 1
else
  echo "Build succeeded."
fi
