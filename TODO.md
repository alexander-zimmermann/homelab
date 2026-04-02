# TODO

## Observability

- [ ] **RustFS Monitoring**: Enable OTLP metrics export via Alloy once RustFS exposes meaningful S3 metrics (bucket ops, disk status). Configure `otelcol.receiver.otlp` in Alloy and add `PrometheusRule` for RustFS.
- [ ] **Gatus**: Deploy uptime monitoring for external ingress endpoints (wallbox, SolarEdge etc.) with GitHub status badges. Decision pending: self-hosted vs. SaaS.

## Infrastructure

- [ ] **Velero Backup**: Install Helm Chart, configure S3 backend (RustFS), schedule backups.
- [ ] **Restore Task**: Add `task k8s:restore` that replays Velero backups into DBs and PVCs after a bootstrap (e.g. Homepage images PVC).
- [ ] **Split Ingress Architecture**: Dual Traefik strategy (`traefik-internal` & `traefik-external`) with UDM VLAN/DMZ separation.
- [ ] **PBS Bootstrap**: Make re-bootstrap idempotent. Add a systemd timer to back up `/etc/proxmox-backup/` to NFS, so the bootstrap script can restore config first and all existing-checks (datastore, users, jobs) pass without re-initializing.

## Optimizations

- [ ] **InfluxDB**: Configure data retention policies.
- [ ] **Cilium**: Implement network policies.

## GitOps

- [ ] **ArgoCD Source Hydrator**: Evaluate the [Source Hydrator](https://argo-cd.readthedocs.io/en/latest/user-guide/source-hydrator/) for pre-rendering manifests before sync (replaces ApplicationSet + Kustomize render at sync time).

## Platform

- [ ] **Omni**: Use secrets for sensitive data.
- [ ] **Readme**: Update project readme — see [buroa/k8s-gitops](https://github.com/buroa/k8s-gitops/tree/main) as reference.
