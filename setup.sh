#!/usr/bin/env bash
# failed on undefined variable
set -u

# Set working directory to the script's location
SCRIPT_DIR="$(dirname "$0")"
cd "$SCRIPT_DIR" || exit 1

# Load variables from .env (must be in same directory as setup.sh)
set -o allexport
source "$SCRIPT_DIR/.env"
set +o allexport

# redirect stdout & stderr to a log file
mkdir -p ./logs
LOG_FILE="./logs/setup_logs_$(date +%Y-%m-%dT%H:%M:%S).log"
echo "Logging output to $LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1  

# Keep sudo alive in background
sudo -v

# Refresh sudo timestamp until this script finishes
keep_sudo_alive() {
  while true; do
    sudo -v
    sleep 60
  done
}
keep_sudo_alive &
SUDO_PID=$!

# run cleanup on script exit
cleanup() {
  kill "$SUDO_PID"
}
trap cleanup EXIT

# Run setup scripts
SCRIPTS=(
  # "scripts/setup_packages.sh"
  # "scripts/setup_docker.sh"
  # "./scripts/setup_ufw.sh"
  "./scripts/setup_nginx.sh"
)

declare -A RESULTS

echo "Running system setup..."
echo

for script in "${SCRIPTS[@]}"; do
  if [[ -f "$script" ]]; then
    echo " --- Running $script --- "
    if bash "$script"; then
      RESULTS["$script"]="SUCCESS"
    else
      RESULTS["$script"]="FAILED"
    fi
  else
    RESULTS["$script"]="MISSING"
  fi
  echo
done

# --- Summary grouped by result ---
echo "======================"
echo " Setup Summary"
echo "======================"

print_group() {
  local status=$1
  local header=$2
  echo
  echo "--- $header ---"
  for script in "${SCRIPTS[@]}"; do
    if [[ "${RESULTS[$script]}" == "$status" ]]; then
      printf "  %s\n" "$script"
    fi
  done
}

print_group "SUCCESS" "Successful"
print_group "FAILED"  "Failed"
print_group "MISSING" "Missing / Not Executable"