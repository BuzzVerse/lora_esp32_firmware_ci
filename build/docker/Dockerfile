# ----------------------------------------
# Base Image: Ubuntu 20.04
# ----------------------------------------
FROM ubuntu:20.04

# ----------------------------------------
# Argument for non-interactive apt installs
# ----------------------------------------
ARG DEBIAN_FRONTEND=noninteractive

# ----------------------------------------
# Update and Install Basic Tools
# ----------------------------------------
RUN apt-get update && \
    apt-get install -y \
        apt-utils \
        ca-certificates \
        curl \
        wget \
        unzip \
        xz-utils \
        zip

# ----------------------------------------
# Install Build Tools
# ----------------------------------------
RUN apt-get install -y \
        make \
        ninja-build \
        git \
        ccache \
        bison \
        flex

# ----------------------------------------
# Install System Libraries and Dependencies
# ----------------------------------------
RUN apt-get install -y \
        libffi-dev \
        libncurses-dev \
        libpython2.7 \
        libusb-1.0-0-dev

# ----------------------------------------
# Install Development Tools
# ----------------------------------------
RUN apt-get install -y \
        check \
        gperf \
        lcov

# ----------------------------------------
# Install Python, pip, and venv
# ----------------------------------------
RUN apt-get install -y \
        python3 \
        python3-pip \
        python3-venv && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3 10 && \
    python -m pip install --upgrade pip virtualenv

# ----------------------------------------
# Clone ESP-IDF Repository
# ----------------------------------------
ARG IDF_CLONE_URL=https://github.com/espressif/esp-idf.git
ARG IDF_CLONE_BRANCH_OR_TAG=master
ARG IDF_CHECKOUT_REF=

ENV IDF_PATH=/opt/esp/idf
ENV IDF_TOOLS_PATH=/opt/esp

RUN echo "IDF_CHECKOUT_REF=$IDF_CHECKOUT_REF" "IDF_CLONE_BRANCH_OR_TAG=$IDF_CLONE_BRANCH_OR_TAG" && \
    git clone --recursive \
      ${IDF_CLONE_BRANCH_OR_TAG:+-b $IDF_CLONE_BRANCH_OR_TAG} \
      $IDF_CLONE_URL $IDF_PATH && \
    if [ -n "$IDF_CHECKOUT_REF" ]; then \
      cd $IDF_PATH && \
      git checkout $IDF_CHECKOUT_REF && \
      git submodule update --init --recursive; \
    fi

# ----------------------------------------
# Install Required ESP-IDF Tools
# ----------------------------------------
RUN update-ca-certificates --fresh && \
    $IDF_PATH/tools/idf_tools.py --non-interactive install required && \
    $IDF_PATH/tools/idf_tools.py --non-interactive install cmake && \
    $IDF_PATH/tools/idf_tools.py --non-interactive install-python-env && \
    rm -rf $IDF_TOOLS_PATH/dist

# ----------------------------------------
# Enable ccache by Default
# ----------------------------------------
ENV IDF_CCACHE_ENABLE=1
