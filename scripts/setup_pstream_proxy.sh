#!/usr/bin/env bash
set -euo pipefail

echo "Installing Simple Proxy For P-Stream"

# List of environment variables to check
ENV_VARS=("PSTREAM_PROXY_DIR" "PSTREAM_PROXY_REPO_URL" "GITREPO_DIR")

for var_name in "${ENV_VARS[@]}"; do
  if [[ -z "$var_name" ]]; then
    echo "Environment variable '$var_name' is NOT set."
    exit 1
  fi
done

# installing node 22, copied from https://nodejs.org/en/download
echo "Installing Node 22"
# Download and install nvm:
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

# in lieu of restarting the shell
\. "$HOME/.nvm/nvm.sh"

# Download and install Node.js:
nvm install 22

# install pnpm 10
echo "Installing pnpm 10"
npm install -g pnpm@latest-10

# Install simple-proxy for pstream
echo "Install simple-proxy for pstream"

# make the gitrepo folder if it does not exist yet
mkdir -p "$GITREPO_DIR"

if [ -d "$PSTREAM_PROXY_DIR" ] && [ -d "$PSTREAM_PROXY_DIR/.git" ]; then
  echo "Repository already exists, pulling latest changes..."
  echo "Repo Directory $PSTREAM_PROXY_DIR"
  cd "$PSTREAM_PROXY_DIR"
  git pull
else
  echo "Repository does not exist, cloning..."
  echo "Repo Directory $PSTREAM_PROXY_DIR"
  git clone "$PSTREAM_PROXY_REPO_URL" "$PSTREAM_PROXY_DIR"
  cd "$PSTREAM_PROXY_DIR"
fi

pnpm i
pnpm build

# Wait for health check endpoint (timeout after 10s)
echo "Start pstream proxy server in detached screen pstream-proxy"
screen -dmS pstream-proxy pnpm start
counter=0
max_counter=10
sleep_sec=5


echo "Checking if proxy server is alive..."
until curl -s -f http://localhost:3000/ > /dev/null; do

  if [[ $counter -ge $max_counter ]]; then
    echo "Server failed to start"
    screen -S pstream-proxy -X quit
    exit 1
  fi

  ((counter++))
  echo "Not ready yet, retrying($counter/$max_counter)... "
  sleep $sleep_sec

done

echo "P-Stream Proxy is up!"