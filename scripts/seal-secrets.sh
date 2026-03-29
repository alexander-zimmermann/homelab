#!/usr/bin/env bash
###############################################################################
## Seal Secrets script
###############################################################################
## Seals all Kubernetes secrets from .secrets/base/ and .secrets/overlays/{env}/
## into the corresponding Kustomize directories using kubeseal.
##
## Secret filename must match the Kustomize directory name
## (e.g. authentik.yaml -> applications/authentik/).
##
## Prerequisites:
## - kubeseal installed.
## - kubectl context must already point to the target cluster.

set -euo pipefail

## Configuration
ENVIRONMENT="${1:-prod}"
KUBE_DIR="kubernetes"
SECRETS_DIR="${KUBE_DIR}/.secrets"

###############################################################################
## Helper: Logging functions
###############################################################################
info() {
  printf "[INFO]  %s\n" "${1}"
}

success() {
  printf "[SUCCESS] %s\n" "${1}"
}

warn() {
  printf "[WARN]  %s\n" "${1}"
}

die() {
  printf "[ERROR] %s\n" "${1}"
  exit 1
}

###############################################################################
## Helper: Format sealed secret output
###############################################################################
format_sealed_secret() {
  local file="${1}"

  ## Remove leading --- separator on first line
  sed -i '1{/^---$/d}' "${file}"

  ## Add blank line before --- separators, top-level metadata and spec blocks
  sed -i '/^---$/i\\' "${file}"
  sed -i '/^metadata:/i\\' "${file}"
  sed -i '/^spec:/i\\' "${file}"
}

###############################################################################
## Helper: Seal a single secret file
###############################################################################
seal_file() {
  local input="${1}"
  local output="${2}"

  info "Sealing: ${input} → ${output}"
  kubeseal \
    --controller-namespace sealed-secrets-controller \
    --controller-name sealed-secrets-controller \
    -f "${input}" \
    -w "${output}" || die "Failed to seal ${input}."

  format_sealed_secret "${output}"
}

###############################################################################
## Helper: Seal all base secrets
###############################################################################
seal_base_secrets() {
  info "Sealing base secrets..."
  for file in "${SECRETS_DIR}/base/"*.yaml; do
    [[ -f "${file}" ]] || continue
    local app=$(basename "${file}" .yaml)
    local target=$(find "${KUBE_DIR}/applications" "${KUBE_DIR}/components" -type d -path "*/${app}/base" 2>/dev/null | head -1)

    if [[ -n "${target}" ]]; then
      seal_file "${file}" "${target}/sealed-secret.yaml"
    else
      warn "No base directory found for '${app}', skipping."
    fi
  done

  success "Base secrets sealed successfully."
}

###############################################################################
## Helper: Seal all overlay secrets for the given environment
###############################################################################
seal_overlay_secrets() {
  local overlay_dir="${SECRETS_DIR}/overlays/${ENVIRONMENT}"

  ## Check if overlay directory contains any secrets
  if ! compgen -G "${overlay_dir}/*.yaml" > /dev/null 2>&1; then
    info "No overlay secrets found for env '${ENVIRONMENT}', skipping."
    return 0
  fi

  info "Sealing overlay secrets for env '${ENVIRONMENT}'..."
  for file in "${overlay_dir}/"*.yaml; do
    [[ -f "${file}" ]] || continue
    local app=$(basename "${file}" .yaml)
    local target="${KUBE_DIR}/applications/${app}/overlays/${ENVIRONMENT}"

    if [[ -d "${target}" ]]; then
      seal_file "${file}" "${target}/sealed-secret.yaml"
    else
      warn "No overlay directory found for '${app}/${ENVIRONMENT}', skipping."
    fi
  done

  success "Overlay secrets for '${ENVIRONMENT}' sealed successfully."
}

###############################################################################
## Main Script
###############################################################################
info "========================================"
info " Seal Secrets (env: ${ENVIRONMENT})     "
info "========================================"

## Validate environment argument
[[ "${ENVIRONMENT}" == "prod" || "${ENVIRONMENT}" == "dev" ]] \
  || die "Invalid environment '${ENVIRONMENT}'. Must be 'prod' or 'dev'."

## Validate secrets directory exists
[[ -d "${SECRETS_DIR}/base" ]] \
  || die "Secrets base directory not found at ${SECRETS_DIR}/base."

## Seal base secrets
seal_base_secrets

## Seal overlay secrets
seal_overlay_secrets

success "========================================"
success " All secrets sealed successfully!       "
success "========================================"
