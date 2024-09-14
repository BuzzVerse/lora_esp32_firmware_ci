#!/bin/bash

# Ustawienia domyślne
REPO_URL="git@github.com:BuzzVerse/lora_esp32_firmware.git"  # Zmieniono na SSH URL
TARGET_DIR="./tmp"
BRANCH="main"  # Domyślna gałąź to "main"

# Funkcja do wyświetlania informacji o użyciu
usage() {
    echo "Usage: $0 [-b branch_name | -t tag | -c commit_hash]"
    exit 1
}

# Parsowanie opcji
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

# Debug: Wyświetlenie wartości zmiennych
echo "REPO_URL: $REPO_URL"
echo "TARGET_DIR: $TARGET_DIR"
[ -n "$BRANCH" ] && echo "BRANCH: $BRANCH"
[ -n "$COMMIT" ] && echo "COMMIT: $COMMIT"
[ -n "$TAG" ] && echo "TAG: $TAG"

# Tworzenie lub czyszczenie katalogu tmp
if [ -d "$TARGET_DIR" ]; then
  echo "Czyszczenie istniejącego katalogu $TARGET_DIR..."
  rm -R "$TARGET_DIR"
fi

mkdir -p "$TARGET_DIR"

# Klonowanie repozytorium za pomocą klucza SSH
echo "Klonowanie repozytorium z $REPO_URL do $TARGET_DIR..."
GIT_SSH_COMMAND="ssh -i /home/jenkins/.ssh/id_rsa -o StrictHostKeyChecking=no" git clone --recurse-submodules "$REPO_URL" "$TARGET_DIR" --depth 1
if [ $? -ne 0 ]; then
  echo "Błąd: Nie udało się sklonować repozytorium z $REPO_URL."
  exit 1
fi

cd "$TARGET_DIR"

# Aktualizacja submodułów
git submodule update --init --recursive 2>&1
if [ $? -ne 0 ]; then
  echo "Błąd: Nie udało się zaktualizować submodułów."
  exit 1
fi

# Pobranie wszystkich gałęzi i tagów
git fetch --all

# Obsługa gałęzi, tagów lub commitów
case $TYPE in
  "branch")
    echo "Przełączanie na gałąź '$BRANCH'..."
    git checkout "$BRANCH" || git checkout -b "$BRANCH" "origin/$BRANCH"
    ;;
  "tag")
    echo "Przełączanie na tag '$TAG'..."
    git checkout "tags/$TAG"
    ;;
  "commit")
    echo "Sprawdzanie, czy commit '$COMMIT' istnieje..."
    if ! git cat-file -e "$COMMIT" 2>/dev/null; then
      echo "Błąd: Commit '$COMMIT' nie istnieje."
      exit 1
    fi
    echo "Przełączanie na commit '$COMMIT'..."
    git checkout "$COMMIT"
    ;;
  *)
    echo "Błąd: Nie podano poprawnej gałęzi, tagu ani commita."
    exit 1
    ;;
esac

echo "Repozytorium zostało pomyślnie pobrane do $TARGET_DIR."
