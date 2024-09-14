# ----------------------------------------
# Services
# ----------------------------------------
services:
  # --------------------------------------
  # ESP32 Build Service
  # --------------------------------------
  esp32_build:
    build:
      context: ../../build/docker/  # Path to the directory containing the Dockerfile
    container_name: esp32_build
    stdin_open: true                # Enables stdin for interactive processes
    tty: true                       # Enables interactive terminal
    user: root
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock         # Mount Docker socket for communication with Docker daemon
      - ../../build/scripts:/usr/local/scripts            # Mount the scripts directory
      - ../../build/artifacts:/usr/local/artifacts        # Mount the artifacts directory
      - ./build:/usr/local/build                          # Dynamic mount location for build project
      - ./ssh:/home/jenkins/.ssh                          # Mount SSH directory (unified path)
    environment:
      - ESP_IDF_PATH=/opt/esp/idf                         # Environment variable for ESP-IDF
    working_dir: /workspace                               # Default working directory inside the container
    entrypoint:
      - /bin/bash
      - -c
      - |
        chown -R jenkins:jenkins /home/jenkins/.ssh /home/jenkins/agent
        [ -f /home/jenkins/.ssh/id_rsa ] && chmod 600 /home/jenkins/.ssh/id_rsa
        [ -f /home/jenkins/.ssh/id_rsa.pub ] && chmod 644 /home/jenkins/.ssh/id_rsa.pub
        [ -f /home/jenkins/.ssh/config ] && chmod 644 /home/jenkins/.ssh/config
    networks:
      - jenkins

  # --------------------------------------
  # Jenkins Node Service
  # --------------------------------------
  jenkins-node:
    build:
      context: .                              # Context for the build - the same directory as docker-compose.yml
    container_name: jenkins-node
    user: root
    stdin_open: true
    tty: true
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock         # Mount Docker socket for communication with Docker daemon
      - ./agent:/home/jenkins/agent                       # Mount the Jenkins agent directory
      - ./ssh:/home/jenkins/.ssh                          # Mount SSH directory (unified path)
    environment:
      - JENKINS_URL=http://192.168.22.7:8082              # Jenkins server URL
      - JENKINS_SECRET=<jenkins_encryption_key>           # Jenkins agent secret
      - JENKINS_AGENT_NAME=Test                           # Jenkins agent name
    entrypoint:
      - /bin/sh
      - -c
      - |
        groupadd -f docker
        usermod -aG docker jenkins
        chown -R jenkins:jenkins /home/jenkins/.ssh /home/jenkins/agent
        [ -f /home/jenkins/.ssh/id_rsa ] && chmod 600 /home/jenkins/.ssh/id_rsa
        [ -f /home/jenkins/.ssh/id_rsa.pub ] && chmod 644 /home/jenkins/.ssh/id_rsa.pub
        [ -f /home/jenkins/.ssh/config ] && chmod 644 /home/jenkins/.ssh/config
        su jenkins -c '/usr/local/bin/jenkins-agent -url $${JENKINS_URL} -workDir /home/jenkins/agent -secret $${JENKINS_SECRET} -name $${JENKINS_AGENT_NAME}'
    networks:
      - jenkins
