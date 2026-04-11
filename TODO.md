# TODO

## Observability

- [ ] **RustFS Monitoring**: Enable OTLP metrics export via Alloy once RustFS exposes meaningful S3 metrics (bucket ops, disk status). Configure `otelcol.receiver.otlp` in Alloy and add `PrometheusRule` for RustFS.
- [ ] **Gatus**: Deploy uptime monitoring for external ingress endpoints (wallbox, SolarEdge etc.) with GitHub status badges. Decision pending: self-hosted vs. SaaS.

## Infrastructure

- [ ] **Restore Task**: Add `task k8s:restore` that replays Velero backups into DBs and PVCs after a bootstrap (e.g. Homepage images PVC).
- [ ] **Split Ingress Architecture**: Dual Traefik strategy with UDM VLAN/DMZ separation.
  - `traefik-external` (DMZ VLAN) → `*.zimmermann.sh` via Cloudflare, all services publicly accessible
  - `traefik-internal` (internal VLAN) → `*.zimmermann.eu.com` via internal DNS resolver
  - Each service gets two IngressRoutes (one per Traefik instance / domain)
  - All backend services migrate from LoadBalancer to ClusterIP
  - ExternalDNS split: `.sh` → Cloudflare, `.eu.com` → internal resolver
  - BGP announces only two IPs (one per Traefik) instead of one per service

## Optimizations

- [ ] **InfluxDB**: Configure data retention policies.
- [ ] **Cilium**: Implement network policies.

## GitOps

- [ ] **ArgoCD Source Hydrator**: Evaluate the [Source Hydrator](https://argo-cd.readthedocs.io/en/latest/user-guide/source-hydrator/) for pre-rendering manifests before sync (replaces ApplicationSet + Kustomize render at sync time).
- [ ] **ArgoCD OIDC Bootstrap**: ArgoCD caches a failed OIDC state when it starts before Authentik is healthy. After a fresh bootstrap a manual ArgoCD server restart is currently required.

## Platform

- [ ] **Omni**: Use secrets for sensitive data.
- [ ] **Readme**: Update project readme — see [buroa/k8s-gitops](https://github.com/buroa/k8s-gitops/tree/main) as reference.
