#!/usr/bin/env bash
###############################################################################
## Omni SSL Renewal Script
###############################################################################
## Runs lego renew with a hook to reload Omni
##
## Prerequisites:
## - lego installed
## - Environment files in /etc/omni/omni-renew-cert.env

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
## Construct domain flags for running lego
info "Configuring domains..."
domain_flags=("--domains=${PRIMARY_DOMAIN}")
IFS=',' read -ra domains_arr <<< "${SAN_DOMAINS:-}"
for domain in "${domains_arr[@]}"; do
  domain_flags+=("--domains=${domain}")
done

## Define Renew Hook. It copies the new certs to the destination and restarts Omni
hook_cmd="cp \"${LEGO_CERT_DIR}/\"* \"${OMNI_CERT_DIR}\" && \
          chown -R \"${OMNI_OWNER}\" \"${OMNI_CERT_DIR}\" && \
          docker restart omni || true"

## Run lego renew. This runs ONLY if the certificate is actually renewed
info "Checking for SSL renewal..."
CLOUDFLARE_DNS_API_TOKEN="${CF_DNS_API_TOKEN}" \
CLOUDFLARE_EMAIL="${CF_API_EMAIL}" \
lego \
  --email="${CF_API_EMAIL}" \
  --dns="cloudflare" \
  --accept-tos \
  "${domain_flags[@]}" \
  renew \
  --renew-hook "${hook_cmd}" || die "Failed to renew SSL certificate for ${PRIMARY_DOMAIN}."

success "SSL renewal check completed."
