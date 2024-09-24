# Use a specific ESP-IDF version from Docker Hub (v5.0 for this example)
FROM espressif/idf:v5.0

# Set environment variable to skip interactive timezone configuration
ENV DEBIAN_FRONTEND=noninteractive

# Install additional tools needed for building
RUN apt-get update && apt-get install -y \
    git \
    cmake \
    ninja-build \
    wget \
    python3-pip \
    bash \
    tzdata \
    openssh-client && \
    ln -fs /usr/share/zoneinfo/Europe/Warsaw /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata

# Set the IDF_PATH environment variable
ENV IDF_PATH=/opt/esp/idf

# Add ESP-IDF tools to the PATH environment variable
ENV PATH="$IDF_PATH/tools:$PATH"

# Automatically source the ESP-IDF environment when the container starts
RUN echo ". $IDF_PATH/export.sh" >> ~/.bashrc

RUN ln -sf /opt/esp/idf/components/espcoredump/Kconfig /usr/bin/Kconfig

# Set the working directory
WORKDIR /workspace
