#!/usr/bin/env bash
###############################################################################
## PBS bootstrap script
###############################################################################
## Automates Proxmox Backup Server initial setup, including datastore configuration.
##
## Prerequisites:
## - proxmox-backup-server installed.
## - Data disk mounted at /mnt/datastore-01

set -euo pipefail

###############################################################################
## Helper: Logging functions
###############################################################################
info() {
  printf "[INFO]  %s\n" "${1}"
}

success() {
  printf "[SUCCESS] %s\n" "${1}"
}

die() {
  printf "[ERROR] %s\n" "${1}"
  exit 1
}

###############################################################################
## Main Script
###############################################################################
info "===================================="
info " Proxmox Backup Server Bootstrap "
info "===================================="

## Define datastore settings
DATASTORE_NAME="datastore-01"
DATASTORE_PATH="/mnt/datastore-01"

## Create datastore directory if missing (ensure correct ownership)
if [ ! -d "${DATASTORE_PATH}" ]; then
  info "Creating datastore directory: ${DATASTORE_PATH}"
  mkdir -p "${DATASTORE_PATH}"
  chown backup:backup "${DATASTORE_PATH}"
fi

## Check if datastore is already configured in PBS
if proxmox-backup-manager datastore list | grep -q "${DATASTORE_NAME}"; then
  info "Datastore ${DATASTORE_NAME} already exists in PBS configuration."
else
  info "Initializing datastore ${DATASTORE_NAME} at ${DATASTORE_PATH}..."
  proxmox-backup-manager datastore create "${DATASTORE_NAME}" "${DATASTORE_PATH}" || die "Failed to create datastore."
  success "Datastore ${DATASTORE_NAME} created successfully."
fi

success "===================================="
success " PBS Bootstrap complete!"
success "===================================="
