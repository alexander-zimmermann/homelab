#!/usr/bin/env bash
###############################################################################
## Omni Infra Provider Key Rotation Script
###############################################################################
## Renews infra provider key and updates the local key file
##
## Prerequisites:
## - omnictl installed
## - Environment file in /etc/omni/omni-rotate-ip-key.env

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
## Perform key rotation
info "Rotating infra provider '${OMNI_IP_NAME}' key..."
output=$(\
  OMNI_ENDPOINT="${OMNI_API_ENDPOINT}" \
  OMNI_SERVICE_ACCOUNT_KEY="$(< "${OMNI_IP_KEY_PATH}")" \
  omnictl ip renewkey "${OMNI_IP_NAME}" \
    --ttl 720h \
    --insecure-skip-tls-verify
) || die "Failed to renew infra provider '${OMNI_IP_NAME}'."

## Extract new key from output
new_key=$(echo "${output}" | grep '^OMNI_SERVICE_ACCOUNT_KEY=' | cut -d= -f2-)

## Validate that new key was extracted
if [[ -z "${new_key}" ]]; then
    die "Failed to extract OMNI_SERVICE_ACCOUNT_KEY from omnictl output '${output}'."
fi

## Update key file
echo "${new_key}" > "${OMNI_IP_KEY_PATH}"
chown "${OMNI_OWNER}" "${OMNI_IP_KEY_PATH}"

success "InfraProvider '${OMNI_IP_NAME}' key renewed and updated at ${OMNI_IP_KEY_PATH}."
