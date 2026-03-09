#!/bin/bash
###############################################################################
## Omni Bootstrap Script
###############################################################################
## Automates Omni setup, including Repo Clone, Certificates, GPG, and Data persistence.
##
## Prerequisites:
## - git, lego, gpg installed.
## - Environment files in /opt/omni/.env/{bootstrap,docker,lego}

set -euo pipefail

## Set environment files
ENV_BOOTSTRAP="/opt/omni/.bootstrap"
ENV_DOCKER="/opt/omni/.env"
ENV_LEGO="/opt/omni/.lego"

###############################################################################
## Helper: Logging functions
###############################################################################
info() {
  printf "[INFO]  %s\n" "${1}"
}

die() {
  printf "[ERROR] %s\n" "${1}"
  exit 1
}

###############################################################################
## Helper: SSL Certificates
###############################################################################
setup_certificates() {
  local local_cert_file="${OMNI_LOCAL_CERT_DIR}/${PRIMARY_DOMAIN}.crt"
  mkdir -p "${OMNI_LOCAL_CERT_DIR}"

  ## Check if certificates exist locally (either from backup extraction or previous run)
  if [[ -f "${local_cert_file}" ]]; then
    info "Certificates found in local cert directory. Skipping generation."
    return 0
  fi

  ## Construct domain flags for running lego
  local domain_flags="--domains=${PRIMARY_DOMAIN}"
  IFS=',' read -ra domains_arr <<< "${SAN_DOMAINS:-}"
  for domain in "${domains_arr[@]}"; do
    domain_flags="${domain_flags} --domains=${domain}"
  done

  info "Certificates not found. Generating new certificates via Let's Encrypt..."
  CLOUDFLARE_DNS_API_TOKEN="${CF_DNS_API_TOKEN}" \
  CLOUDFLARE_EMAIL="${CF_API_EMAIL}" \
  lego \
    --email="${CF_API_EMAIL}" \
    --dns="cloudflare" \
    --accept-tos \
    ${domain_flags} \
    run

  ## Copy certificates into local cert directory
  info "Copying new certificates to ${OMNI_LOCAL_CERT_DIR}..."
  cp "${LEGO_CERT_DIR}/"* "${OMNI_LOCAL_CERT_DIR}"
}

###############################################################################
## Helper: GPG Keys
###############################################################################
setup_gpg() {
  local local_key_file="${OMNI_LOCAL_KEY_DIR}/${OMNI_PRIVATE_KEY}"
  mkdir -p "${OMNI_LOCAL_KEY_DIR}"

  ## Check if GPG key exists locally (either from backup extraction or previous run)
  if [[ -f "${local_key_file}" ]]; then
    info "GPG key found in local key directory. Skipping generation."
    return 0
  fi

  info "GPG key not found. Generating new primary GPG key (RSA 4096)..."
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

  ## Get key fingerprint
  info "Retrieving GPG key fingerprint..."
  local list_keys=$(gpg --quiet --list-secret-keys --with-colons "${OMNI_EMAIL_ADDRESS}")
  local key_fingerprint=$(echo "${list_keys}" | grep '^fpr:' | head -n1 | cut -d: -f10)
  info "GPG key fingerprint: ${key_fingerprint}"

  ## Add encryption subkey
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

  ## Verifying GPG key configuration
  info "Verifying GPG key configuration..."
  gpg \
    --quiet \
    --list-secret-keys \
    --with-subkey-fingerprint "${OMNI_EMAIL_ADDRESS}" || die "Failed to list secret keys."

  ## Export GPG key
  info "Exporting GPG key to file..."
  gpg \
    --quiet \
    --export-secret-key \
    --armor "${OMNI_EMAIL_ADDRESS}" > "${local_key_file}" || die "Failed to export key."
}

###############################################################################
## Helper: Central Backup Restore
###############################################################################
restore_from_backup() {
  local latest_backup=$(ls -t "${OMNI_BACKUP_DIR}"/omni-backup-*.tar.gz 2>/dev/null | head -n 1 || true)

  ## Check if Omni data already exists locally (db file is a good marker)
  if [[ -f "${OMNI_LOCAL_DATA_DIR}/omni.db" ]]; then
    info "Omni database found locally. Skipping full backup restore."
    return 0
  fi

  if [[ -n "${latest_backup}" ]]; then
    info "Found Omni multi-volume backup: ${latest_backup}. Extracting..."
    mkdir -p "${OMNI_PERSISTENCE_DATA_DIR}"
    tar -xzf "${latest_backup}" -C "${OMNI_PERSISTENCE_DATA_DIR}/" --strip-components=1
    info "Backup extraction successful."
    return 0
  fi

  info "No backup archive found in ${OMNI_BACKUP_DIR}. Proceeding as fresh setup."
}

###############################################################################
## Main Script
###############################################################################
info "===================================="
info "  Omni Bootstrap "
info "===================================="

## Load environment files
info "Loading environment files..."
source ${ENV_BOOTSTRAP} || die "Failed to load bootstrap environment variables."
source ${ENV_DOCKER} || die "Failed to load docker environment variables."
source ${ENV_LEGO} || die "Failed to load lego environment variables."

## Restore all data from the latest tarball (if on a fresh node)
info "Checking for Omni backup archive to restore..."
restore_from_backup

## Restore or generate new certificates
info "Ensuring certificates are present..."
setup_certificates

## Restore or generate new GPG keys
info "Ensuring GPG state is present..."
setup_gpg

##Set permissions & ownership
chown -R "${OWNER}" "${OMNI_LOCAL_CERT_DIR}"
chown -R "${OWNER}" "${OMNI_BACKUP_CERT_DIR}"
chown -R "${OWNER}" "${OMNI_LOCAL_KEY_DIR}"
chown -R "${OWNER}" "${OMNI_BACKUP_KEY_DIR}"

## Deploy with Docker Compose
info "Deploying Omni via docker compose..."
cd "${OMNI_LOCAL_DIR}"
docker compose up -d > /dev/null || die "Failed to deploy docker compose."

info "Bootstrap complete!"
