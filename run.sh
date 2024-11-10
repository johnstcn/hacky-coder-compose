#!/usr/bin/env bash

set -o pipefail
set -e

CONCURRENCY="${CONCURRENCY:-3}"
NUM_WORKSPACES="${NUM_WORKSPACES:-10}"
CODER_IMAGE="${CODER_IMAGE:-ghcr.io/coder/coder:latest}"
VERBOSE="${VERBOSE:-}"
set -u

if [ -n "${VERBOSE}" ]; then
  set -x
fi

# Ensure we have the required tools: docker, jq, and curl
if ! command -v docker &> /dev/null; then
  echo "docker is required but not installed"
  exit 1
fi

if ! docker info &> /dev/null; then
  echo "docker is required but not running"
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echo "jq is required but not installed"
  exit 1
fi

if ! command -v curl &> /dev/null; then
  echo "curl is required but not installed"
  exit 1
fi

if ! command -v terraform &> /dev/null; then
  echo "terraform is required but not installed"
  exit 1
fi

# Bring up the docker-compose stack in the background
CODER_IMAGE="${CODER_IMAGE}" CODER_PROVISIONER_DAEMONS="${CONCURRENCY}" docker compose up -d

# Wait for the coder server to be ready
while ! curl -s -f http://localhost:7080/api/v2/buildinfo; do
  echo "Waiting for coder server to be ready..."
  sleep 1
done

CODER_CONFIG_DIR="$(pwd)/.coder"
CODER_BIN="${CODER_CONFIG_DIR}/bin/coder"

# Fetch the Coder binary
if [ ! -x "${CODER_BIN}" ]; then
    echo "Fetching the Coder binary..."
    mkdir -p "$(dirname "${CODER_BIN}")"
    curl -fsSL http://localhost:7080/bin/coder-linux-amd64 -o "${CODER_BIN}"
    chmod +x "${CODER_BIN}"
fi
if ! "${CODER_BIN}" version >/dev/null; then
  echo "Failed to fetch the Coder binary"
  exit 1
fi

# Ensure we're logged in
if ! CODER_CONFIG_DIR="${CODER_CONFIG_DIR}" "${CODER_BIN}" whoami; then
    # Login to the Coder server
    mkdir -p .coder
    CODER_CONFIG_DIR="${CODER_CONFIG_DIR}" "${CODER_BIN}" login http://localhost:7080 \
    --first-user-email=admin@coder.com \
    --first-user-password='SomeSecurePassword!' \
    --first-user-full-name='Admin User' \
    --first-user-username='admin' \
    --first-user-trial="false"
fi

# Run the terraform init so we have a lockfile
( cd ./docker-template && terraform init -upgrade )

# Create and push template
CODER_CONFIG_DIR="${CODER_CONFIG_DIR}" "${CODER_BIN}" templates push docker -d ./docker-template --yes

# Create some workspaces
seq 1 "${NUM_WORKSPACES}" | xargs -I {} -P "${CONCURRENCY}" bash -c \
  "CODER_CONFIG_DIR=${CODER_CONFIG_DIR} ${CODER_BIN} create ws{} --template docker --yes --start-at 8am --stop-after 1h"
