# ESP32 Firmware Build Automation

## Overview

This project provides a Docker-based automated build system for ESP32 firmware using ESP-IDF. The build environment is managed using Docker and integrated with Jenkins for continuous integration. This setup allows you to fetch, build, and manage artifacts for different versions (branches, tags, commits) of your ESP32 project hosted on GitHub.

## Structure
```bash
.
├── artifacts # Directory for storing build artifacts
├── docker # Docker-related files
│ ├── Dockerfile # Dockerfile for building the ESP32 environment
│ ├── jenkins-agent.jar # Optional file for Jenkins agent setup
│ ├── scripts # Scripts used by the Docker container
│ │ ├── artifacts # Directory for storing build artifacts inside the container
│ │ ├── build\_project.sh # Main script for building the project
│ │ ├── fetch.sh # Script to fetch code from GitHub
│ │ └── jenkins-build.sh # Script used by Jenkins for building
│ └── start-jenkins-node.sh # Script to start Jenkins node in Docker
├── docker-compose.yml # Docker Compose file for managing services
├── install.sh # Optional install script
├── Jenkinsfile # Jenkins pipeline configuration
├── README.md # Project documentation
└── scripts # Host-side scripts
└── build.sh # Main build script for running builds on the host  
```  
  
  
Requirements

-   Docker
-   Docker Compose
-   Git
-   Bash (for running shell scripts)
    

## Usage

### 1\. Cloning the Repository

Clone the project repository to your local machine:

git clone https://github.com/BuzzVerse/lora\_esp32\_firmware_ci.git  
cd lora\_esp32\_firmware_ci  
  
2\. Building the ESP32 Firmware

To build the project, use the `build.sh` script located in the `scripts` directory. This script allows you to specify a branch, tag, or commit from the GitHub repository to build.

Example usage:
```
./scripts/build.sh -b main # Build the latest code from the "main" branch

./scripts/build.sh -t v1.0 # Build from a specific tag

./scripts/build.sh -c 1234567 # Build from a specific commit  
```
3\. Fetching the Code

The `fetch.sh` script is responsible for fetching the code from the repository based on the provided branch, tag, or commit hash. This script is automatically invoked by `build.sh`.

### 4\. Running the Docker Container

The `docker-compose.yml` file is used to manage the Docker container that performs the actual build process. It mounts the necessary directories and executes the build script inside the container.

To start the container and begin the build process:
```
docker-compose up -–build  
```
This command will:

-   Pull the latest version of the repository
    
-   Build the ESP32 firmware inside the Docker container
    
-   Copy the build artifacts to the `artifacts` directory on your host machine
    

### 5\. Jenkins Integration

The project can be integrated with Jenkins for automated builds. A `Jenkinsfile` is included to define the build pipeline. To configure the Jenkins node, use the `start-jenkins-node.sh` script.

### 6\. Artifacts

After a successful build, the resulting artifacts will be stored in the `artifacts` directory. These artifacts can be used to flash the firmware onto an ESP32 device.

### 7\. Clean Up

Once the build is complete, you can stop and remove the Docker container using:
```
docker-compose down  
```
Customization

### Docker Image

The Docker image used for building is defined in the `docker/Dockerfile`. You can customize this file if you need to add additional tools or dependencies.

### Environment Variables

The `docker-compose.yml` file sets environment variables such as `ESP_IDF_PATH` for the ESP-IDF framework. You can modify these environment variables if necessary.

### Volume Mounting

The `docker-compose.yml` mounts the following directories into the Docker container:

-   `./scripts`: Contains scripts for building and managing the project
    
-   `./artifacts`: Directory for storing build artifacts
    
-   `./docker/scripts/tmp`: Directory for storing the project being built
    

## Troubleshooting

-   **Docker Compose not found**: Ensure you have Docker Compose installed and configured properly.
    
-   **Git errors**: Check your network connection and repository access.
    
-   **Build failures**: Review the build logs stored in `build_logs.txt` to diagnose issues.
    
