# **LoRa ESP32 Firmware CI Project**

This project provides a Docker-based continuous integration (CI) environment for building the ESP32 firmware using the ESP-IDF framework. The environment is designed to automate the build process, allowing for seamless integration with CI tools such as Jenkins. The Docker container includes a specific version of ESP-IDF, additional build tools, and custom scripts for building and managing the project.

## Table of Contents

-   Project Overview
    
-   Directory Structure
    
-   Prerequisites
    
-   Building and Running the Docker Container
    
-   Entering the Docker Container
    
-   Building the Project with Parameters
    
-   Jenkins Configuration
    
-   How to Use the Project
    
-   License
    

## Project Overview

This project automates the process of building LoRa ESP32 firmware using a Docker container that includes the ESP-IDF framework. By using a specific version of ESP-IDF (in this case, v5.0), developers can ensure consistency and reproducibility in the build process. The container also supports integration with CI tools like Jenkins for automated builds.

## Directory Structure

The project is structured as follows:
```text
lora\_esp32\_firmware\_ci/ 
├── docker/ 
│ ├── Dockerfile # Dockerfile defining the container build environment 
│ ├── start-jenkins-node.sh # Script to start the container as a Jenkins node (optional) 
│ └── jenkins-agent.jar # Jenkins agent JAR file (optional, if not dynamically downloaded) 
├── scripts/ 
│ ├── build.sh # Script to trigger the project build process 
│ ├── fetch.sh # Script to fetch the appropriate version of the project from GitHub 
│ ├── install.sh # Installation script for required tools on the system 
│ └── jenkins-build.sh # Script to initiate builds via Jenkins (optional) 
├── tmp/ # Temporary directory for downloading projects (ignored by git) 
├── docker-compose.yml # Docker Compose configuration for managing the container 
├── Jenkinsfile # Jenkins pipeline for automating the build process 
├── README.md # Project documentation 
├──.env.example # Example environment variables file (e.g., for Jenkins URLs) 
└──.gitignore # File to exclude unnecessary files and directories (e.g., tmp)
```

## Explanation of Files

-   docker/Dockerfile: Defines the Docker image, including the version of ESP-IDF, required dependencies, and build tools.
-   docker/start-jenkins-node.sh: Optional script to run the Docker container as a Jenkins agent.
-   docker/jenkins-agent.jar: Optional Jenkins agent file, used if the container needs to be part of a Jenkins CI setup.
    
-   scripts/build.sh: Script to build the ESP32 firmware.
    
-   scripts/fetch.sh: Script to fetch the required branch or commit of the project from GitHub.
    
-   scripts/install.sh: Script for installing Docker, Docker Compose, and other necessary tools.
    
-   scripts/jenkins-build.sh: Optional script to trigger builds from Jenkins.
    
-   tmp/: Temporary directory for project files during builds. This directory is ignored by .gitignore.
    
-   docker-compose.yml: Defines how to manage the Docker container with Docker Compose.
    
-   Jenkinsfile: Configuration file for Jenkins CI pipeline.
    
-   README.md: Documentation for the project.
    
-   .env.example: Example file for storing environment variables.
    
-   .gitignore: Specifies files and directories to be ignored by git.
    

## Prerequisites

Ensure you have the following installed on your system:

-   Docker: Installation Guide
    
-   Docker Compose: Installation Guide
    
-   Git: Installation Guide
    

## Building and Running the Docker Container

To build the Docker container with the ESP-IDF environment:

1.  Clone this repository:
    
```bash
git clone [https://github.com/YourUsername/lora\_esp32\_firmware\_ci.git](https://github.com/YourUsername/lora_esp32_firmware_ci.git) cd lora\_esp32\_firmware\_ci/docker
```
2.  Build the Docker image:
    
```bash
docker build -t my-esp32-image .
```
3.  Use Docker Compose to manage the container (optional):
    
```bash
docker-compose up -d
```
## Entering the Docker Container

If you need to manually access the Docker container:

1.  Run the container interactively:
    
```bash
docker run -it my-esp32-image /bin/bash
```
2.  You will be inside the container with the ESP-IDF environment ready. You can verify the ESP-IDF version by running:
    
```bash
idf.py --version
```
This should return ESP-IDF v5.0.

## Building the Project with Parameters

The build process can be controlled by passing parameters to the build scripts. You can specify which branch or commit from GitHub should be built.

1.  Build from the default branch (master):
    
```bash
./scripts/build.sh
```
2.  Build from a specific branch:
    

To build a different branch, you can pass the branch name as a parameter:
```bash
./scripts/build.sh -b <branch\_name>
```
Example:
```bash
./scripts/build.sh -b feature/new-feature
```
3.  Build from a specific commit:
    

You can also specify a commit hash to build a particular version:
```bash
./scripts/build.sh -c <commit\_hash>
```
Example:
```bash
./scripts/build.sh -c abc123def456
```
The fetch.sh script, which is called by build.sh, will download the specified branch or commit from GitHub.

## Jenkins Configuration

You can integrate this project with Jenkins to automate the build process.

1.  Set Up Jenkins Node (optional):
    

If you're running the Docker container as a Jenkins agent, you can use the provided start-jenkins-node.sh script. The Jenkins agent will be able to connect to the Jenkins master and execute builds.

Example:
```bash
./docker/start-jenkins-node.sh
```
2.  Jenkins Pipeline Configuration:
    

The provided Jenkinsfile contains the steps necessary to fetch the project, build it, and log the output.

-   Ensure Jenkins has Docker and Docker Compose installed.
    
-   Configure the Jenkinsfile to point to the correct GitHub repository.
    
-   You can customize the parameters in Jenkins for selecting branches or commits to build.
    

3.  Trigger a Jenkins Build:
    

In Jenkins, you can define parameters for each build, allowing you to select which branch or commit to build. The Jenkinsfile will handle triggering the build and logging the results.

Example of parameterized build in Jenkins:

-   GIT\_BRANCH: Specify the branch to build (default: master).
    
-   GIT\_COMMIT: Specify a commit hash (optional).
    

Jenkins will pass these parameters to the build scripts, allowing for flexible and automated builds.

## How to Use the Project

1.  To build the project inside the container:
    

-   Ensure you have the correct source files in the tmp/ directory.
    
-   Run the build.sh script to build the project:
    
```bash
./scripts/build.sh
```
2.  If you are using Jenkins for automated builds, you can configure the pipeline with the provided Jenkinsfile.
