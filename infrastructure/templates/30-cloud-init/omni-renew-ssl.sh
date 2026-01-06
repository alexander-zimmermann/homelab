#!/bin/bash
# ==============================================================================
# Omni SSL Renewal Script
# ==============================================================================
# Runs lego renew with a hook to reload Omni
#
# Prerequisites:
# - lego installed.
# - Environment files in /usr/local/etc/omni/.env/

set -euo pipefail

# Load environments
source /usr/local/etc/omni/.env/lego
source /usr/local/etc/omni/.env/bootstrap

# ==============================================================================
# Main Script
# ==============================================================================
# Construct domain flags for running lego
local domain_flags="--domains=${PRIMARY_DOMAIN}"
IFS=',' read -ra domains_arr <<< "${SAN_DOMAINS:-}"
for domain in "${domains_arr[@]}"; do
  domain_flags="${domain_flags} --domains=${domain}"
done

# Define Renew Hook
# This runs ONLY if the certificate is actually renewed.
# It copies the new certs to the destination and restarts Omni.
HOOK_CMD="cp \"${LEGO_CERT_DIR}/\"* \"${OMNI_LOCAL_CERT_DIR}\" && \
          cp \"${LEGO_CERT_DIR}/\"* \"${OMNI_CERT_BACKUP_DIR}\" && \
          chown -R "${OWNER}" \"${OMNI_LOCAL_CERT_DIR}\" && \
          chown -R "${OWNER}" \"${OMNI_CERT_BACKUP_DIR}\" && \
          docker restart omni || true"

CLOUDFLARE_DNS_API_TOKEN="${CF_DNS_API_TOKEN}" \
CLOUDFLARE_EMAIL="${CF_API_EMAIL}" \
/usr/local/bin/lego \
  --email="${CF_API_EMAIL}" \
  --dns="cloudflare" \
  --accept-tos \
  ${domain_flags} \
  renew \
  --renew-hook "${HOOK_CMD}"
