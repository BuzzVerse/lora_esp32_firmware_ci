# ----------------------------------------
# Base Image: Jenkins Inbound Agent
# ----------------------------------------
# Use the official Jenkins inbound agent as the base image
FROM jenkins/inbound-agent:latest

# ----------------------------------------
# Switch to root user for installation
# ----------------------------------------
USER root

# ----------------------------------------
# Install Docker CLI
# ----------------------------------------
RUN apt-get update && \
    apt-get install -y \
        ca-certificates \
        curl \
        gnupg && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | \
    gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    chmod a+r /etc/apt/keyrings/docker.gpg && \
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
    bullseye stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce-cli

# ----------------------------------------
# Add Jenkins User to Docker Group
# ----------------------------------------
RUN groupadd -g 999 docker && \
    usermod -aG docker jenkins

# ----------------------------------------
# Switch back to Jenkins user
# ----------------------------------------
USER jenkins
