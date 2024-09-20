#!/bin/bash

# Default settings - make sure the URL points to a public repository for anonymous access
REPO_URL="https://github.com/BuzzVerse/lora_esp32_firmware.git"
TARGET_DIR="./tmp"
BRANCH="main"  # Default branch is set to "main"

# Function to display usage information
usage() {
    echo "Usage: $0 [-b branch_name | -t tag | -c commit_hash]"
    exit 1
}

# Parsing options
while getopts ":b:c:t:" opt; do
  case ${opt} in
    b )
      BRANCH=$OPTARG
      TYPE="branch"
      ;;
    c )
      COMMIT=$OPTARG
      TYPE="commit"
      ;;
    t )
      TAG=$OPTARG
      TYPE="tag"
      ;;
    \? )
      usage
      ;;
  esac
done

# Debug: Show values of variables
echo "REPO_URL: $REPO_URL"
echo "TARGET_DIR: $TARGET_DIR"
[ -n "$BRANCH" ] && echo "BRANCH: $BRANCH"
[ -n "$COMMIT" ] && echo "COMMIT: $COMMIT"
[ -n "$TAG" ] && echo "TAG: $TAG"

# Ensure ownership of the tmp directory is set to the current user
if [ -d "$TARGET_DIR" ]; then
  echo "Setting ownership of $TARGET_DIR to the host user..."
  sudo chown -R $(id -u):$(id -g) "$TARGET_DIR"
fi

# Create or clean the tmp directory
if [ -d "$TARGET_DIR" ]; then
  echo "Cleaning the existing $TARGET_DIR directory..."
  rm -rf "$TARGET_DIR/"{*,.[!.]*,..?*} 2>/dev/null  # Remove the contents of the directory
else
  echo "Creating $TARGET_DIR directory..."
  mkdir -p "$TARGET_DIR"
fi



# Clone the repository
echo "Cloning repository from $REPO_URL to $TARGET_DIR..."
GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no" git clone --recurse-submodules "$REPO_URL" "$TARGET_DIR" --depth 1 2>&1
cd "$TARGET_DIR"
git submodule update --init --recursive 2>&1
if [ $? -ne 0 ]; then
  echo "Error: Failed to clone the repository from $REPO_URL."
  exit 1
fi

# Fetch all branches and tags
git fetch --all

# Handle branch, tag, or commit
case $TYPE in
  "branch")
    echo "Checking out branch '$BRANCH'..."
    git checkout "$BRANCH" || git checkout -b "$BRANCH" "origin/$BRANCH"
    ;;
  "tag")
    echo "Checking out tag '$TAG'..."
    git checkout "tags/$TAG"
    ;;
  "commit")
    echo "Checking if the commit '$COMMIT' exists..."
    if ! git cat-file -e "$COMMIT" 2>/dev/null; then
      echo "Error: Commit '$COMMIT' does not exist."
      exit 1
    fi
    echo "Checking out commit '$COMMIT'..."
    git checkout "$COMMIT"
    ;;
  *)
    echo "Error: No valid branch, tag, or commit provided."
    exit 1
    ;;
esac

echo "Repository fetched successfully into $TARGET_DIR."