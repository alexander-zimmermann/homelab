#!/bin/bash
# ==============================================================================
# Omni Bootstrap Script (Consolidated)
# ==============================================================================
# Automates Omni setup, including Repo Clone, Certificates, GPG, and Data persistence.
#
# Prerequisites:
# - git, lego, gpg installed.
# - Environment files in /usr/local/etc/omni/.env/

set -euo pipefail

# Load environment files
source /usr/local/etc/omni/.env/bootstrap || die "Failed to load bootstrap environment variables."
source /usr/local/etc/omni/.env/docker || die "Failed to load docker environment variables."
source /usr/local/etc/omni/.env/lego || die "Failed to load lego environment variables."

# ==============================================================================
# Helper: Logging functions
# ==============================================================================
info() {
  printf "[INFO]  %s\n" "${1}"
}

die() {
  printf "[ERROR] %s\n" "${1}"
  exit 1
}

# ==============================================================================
# Helper: SSL Certificates
# ==============================================================================
setup_certificates() {
  local local_cert_file="${OMNI_LOCAL_CERT_DIR}/${PRIMARY_DOMAIN}.crt"
  local backup_cert_file="${OMNI_BACKUP_CERT_DIR}/${PRIMARY_DOMAIN}.crt"

  mkdir -p "${OMNI_LOCAL_CERT_DIR}"
  mkdir -p "${OMNI_BACKUP_CERT_DIR}"

  # Check if certificates exist in local cert directory
  if [[ -f "${local_cert_file}" ]]; then
    info "Certificates found in local cert directory. Skipping generation."
    return 0
  fi

  # Check if backup exists and copy if found
  if [[ -f "${backup_cert_file}" ]]; then
    info "Restoring certificates from backup directory..."
    cp "${OMNI_BACKUP_CERT_DIR}/"* "${OMNI_LOCAL_CERT_DIR}"
    return 0
  fi

  # Construct domain flags for running lego
  local domain_flags="--domains=${PRIMARY_DOMAIN}"
  IFS=',' read -ra domains_arr <<< "${SAN_DOMAINS:-}"
  for domain in "${domains_arr[@]}"; do
    domain_flags="${domain_flags} --domains=${domain}"
  done

  # No backup found, generate new certificates
  info "Certificates not found in backup. Generating new certificates..."
  CLOUDFLARE_DNS_API_TOKEN="${CF_DNS_API_TOKEN}" \
  CLOUDFLARE_EMAIL="${CF_API_EMAIL}" \
  lego \
    --email="${CF_API_EMAIL}" \
    --dns="cloudflare" \
    --accept-tos \
    ${domain_flags} \
    run

  # Copy certificates into local cert directory
  info "Copying new certificates to ${OMNI_LOCAL_CERT_DIR}..."
  cp "${LEGO_CERT_DIR}/"* "${OMNI_LOCAL_CERT_DIR}"

  # Backup new certificates
  info "Backing up new certificates to ${OMNI_BACKUP_CERT_DIR}..."
  cp "${LEGO_CERT_DIR}/"* "${OMNI_BACKUP_CERT_DIR}"

  # Set permissions
  chown -R "${OWNER}" "${OMNI_LOCAL_CERT_DIR}"
  chown -R "${OWNER}" "${OMNI_BACKUP_CERT_DIR}"
}

# ==============================================================================
# Helper: GPG Keys
# ==============================================================================
setup_gpg() {
  local local_key_file="${OMNI_LOCAL_KEY_DIR}/${OMNI_PRIVATE_KEY}"
  local backup_key_file="${OMNI_BACKUP_KEY_DIR}/${OMNI_PRIVATE_KEY}"
  local backup_keyring="${OMNI_BACKUP_KEY_DIR}/.gnupg"

  mkdir -p "${OMNI_LOCAL_KEY_DIR}"
  mkdir -p "${OMNI_BACKUP_KEY_DIR}"

  # Check if GPG key exists in local key directory
  if [[ -f "${local_key_file}" ]]; then
    info "GPG key found in local key directory. Skipping generation."
    return 0
  fi

  # Check if backup exists and copy if found
  if [[ -f "${backup_key_file}" ]]; then
    info "Restoring GPG key and keyring from backup..."
    cp "${backup_key_file}" "${OMNI_LOCAL_KEY_DIR}/"
    cp -r "${backup_keyring}" "${OMNI_LOCAL_KEY_DIR}/"
    return 0
  fi

  # No backup found, generate GPG encrypted key
  info "Generating new primary GPG key (RSA 4096)..."
  gpg \
    --batch \
    --quiet \
    --passphrase '' \
    --pinentry-mode loopback \
    --quick-generate-key "Omni (Used for etcd data encryption) <${OMNI_EMAIL_ADDRESS}>" \
    rsa4096 \
    cert \
    never || die "Failed to generate primary key."
  info "Primary key generated successfully"

  # Get key fingerprint
  info "Retrieving GPG key fingerprint..."
  local list_keys=$(gpg --quiet --list-secret-keys --with-colons "${OMNI_EMAIL_ADDRESS}")
  local key_fingerprint=$(echo "${list_keys}" | grep '^fpr:' | head -n1 | cut -d: -f10)
  info "GPG key fingerprint: ${key_fingerprint}"

  # Add encryption subkey
  info "Adding encryption subkey..."
  gpg \
    --batch \
    --quiet \
    --passphrase '' \
    --pinentry-mode loopback \
    --quick-add-key "${key_fingerprint}" \
    rsa4096 \
    encr \
    never || die "Failed to add encryption subkey."
  info "Encryption subkey added successfully!"

  # Display GPG key information
  info "Verifying GPG key configuration..."
  gpg \
    --quiet \
    --list-secret-keys \
    --with-subkey-fingerprint "${OMNI_EMAIL_ADDRESS}" || die "Failed to list secret keys."

  # Export GPG key
  info "Exporting GPG key to file..."
  gpg \
    --quiet \
    --export-secret-key \
    --armor "${OMNI_EMAIL_ADDRESS}" > "${local_key_file}" || die "Failed to export key."

  # Backup new GPG encryption key and keyring
  info "Backing up new GPG key..."
  cp "${local_key_file}" "${OMNI_BACKUP_KEY_DIR}"
  cp -r "${GPG_KEYRING_DIR}" "${OMNI_BACKUP_KEY_DIR}"

  # Set permissions
  chown -R "${OWNER}" "${OMNI_LOCAL_KEY_DIR}"
  chown -R "${OWNER}" "${OMNI_BACKUP_KEY_DIR}"
}

# ==============================================================================
# Helper: Data Persistence
# ==============================================================================
setup_data() {
  mkdir -p "${OMNI_LOCAL_DATA_DIR}"
  mkdir -p "${OMNI_BACKUP_DATA_DIR}"

  # Check if Omni data locally exists
  if [[ -n "$(ls -A "${OMNI_LOCAL_DATA_DIR}")" ]]; then
    info "Omni data found locally. Skipping restore."
    return 0
  fi

  # Check if Omni data backup exists
  if [[ -n "$(ls -A "${OMNI_BACKUP_DATA_DIR}")" ]]; then
    info "Omni data found in backup. Restoring..."
    cp -r "${OMNI_BACKUP_DATA_DIR}/"* "${OMNI_LOCAL_DATA_DIR}/"
    return 0
  fi

  info "Backup data directory not found or empty. Skipping restore."
}

# ==============================================================================
# Main Script
# ==============================================================================
info "===================================="
info "  Omni Bootstrap "
info "===================================="

# Clone git repository
info "Cloning repository..."
git clone --quiet "${GITHUB_REPO_URL}" "${LOCAL_REPO_DIR}" || die "Failed to clone repository."

# Restore or generate new certificates
info "Checking for certificate state to restore..."
setup_certificates

# Restore or generate new GPG keys
info "Checking for GPG state to restore..."
setup_gpg

# Restore Omni data if exists
info "Checking for Omni data state to restore..."
setup_data

# Set Ownership
info "Fixing ownership..."
chown -R "${OWNER}" "${LOCAL_REPO_DIR}"
chmod -R g+w "${LOCAL_REPO_DIR}"

# Deploy with Docker Compose
info "Deploying Omni via docker compose..."
ln -sf "${ENV_DOCKER}" "${OMNI_REPO_DIR}/.env"
cd "${OMNI_REPO_DIR}"
docker compose up -d > /dev/null || die "Failed to deploy docker compose."

info "Bootstrap complete!"
