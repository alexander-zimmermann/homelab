# TODO

## Observability

- [ ] **RustFS Monitoring**: Enable OTLP metrics export via Alloy once RustFS exposes meaningful S3 metrics (bucket ops, disk status). Configure `otelcol.receiver.otlp` in Alloy and add `PrometheusRule` for RustFS.
- [ ] **Grafana dashboards Flux → InfluxQL/SQL**: 17 dashboards (`energy-*`, `hvac-*`, `knx-*`) still contain Flux queries (`from(bucket:...)`) targeting stale InfluxDB v2 datasource UIDs. InfluxDB 3 dropped Flux — rewrite to InfluxQL or SQL and point to the `InfluxDB (InfluxQL)` / `InfluxDB (SQL)` datasources (UIDs `ab06323c-...` / `3b275c55-...`).
- [ ] **CrowdSec fine-tuning**: Monthly alert quota (500/500) exhausted and two `crowdsec-lapi` log processors flagged as inactive (>48h no pushed alerts) in the CrowdSec console. Review parsers/scenarios, reduce noisy alerts, and investigate why LAPI pods stop pushing.
- [ ] **Proxmox & PBS metrics**: Enable metrics export on Proxmox VE nodes and — if available — on the Proxmox Backup Server, scrape via Prometheus/Alloy and add dashboards.

## Infrastructure

- [ ] **Omni**: Use secrets for sensitive data.
- [ ] **external-services dev domain**: Certificates in [kubernetes/applications/external-services/base/certificate.yaml](kubernetes/applications/external-services/base/certificate.yaml) only cover `*.zimmermann.sh` — add counterparts for the dev domain `*.zimmermann.phd`.
- [ ] **Restore Task**: Add `task k8s:restore` that replays Velero backups into DBs and PVCs after a bootstrap (e.g. Homepage images PVC).
- [ ] **CNPG cluster PG16 → PG18 migration**: `authentik-db`, `wiki-js-db`, `crowdsec-db`, `gatus-db` are currently on PG 16.1. CNPG operator 1.28.x already supports PG 18 (in-place major upgrade via `imageName` bump + `pg_upgrade` orchestrated by the operator). New `timescaledb-db` runs on PG 18.3 / TimescaleDB 2.23 — keeping the others on 16.1 means two Postgres major versions in parallel. Plan a coordinated bump (one cluster at a time, verify backup + app reconnect after each) to land them all on PG 18.x.
- [ ] **Split Ingress Architecture**: Dual Traefik strategy with UDM VLAN/DMZ separation.
  - `traefik-external` (DMZ VLAN) → `*.zimmermann.sh` via Cloudflare, all services publicly accessible
  - `traefik-internal` (internal VLAN) → `*.zimmermann.eu.com` via internal DNS resolver
  - Each service gets two IngressRoutes (one per Traefik instance / domain)
  - All backend services migrate from LoadBalancer to ClusterIP
  - ExternalDNS split: `.sh` → Cloudflare, `.eu.com` → internal resolver
  - BGP announces only two IPs (one per Traefik) instead of one per service

## Optimizations

- [ ] **stakater/application Chart**: Migrate apps with raw Deployment manifests to [stakater/application](https://github.com/stakater/application) (same pattern as Gatus). Start with `smtprelay` and `fritz-exporter` (simplest cases), then evaluate `solaredge2mqtt` (two releases), `homepage` (RBAC/PVC needs check), and `node-red` (initContainer + PVC support needed).
- [ ] **Cilium**: Implement network policies.

## GitOps

- [ ] **ArgoCD Source Hydrator**: Evaluate the [Source Hydrator](https://argo-cd.readthedocs.io/en/latest/user-guide/source-hydrator/) for pre-rendering manifests before sync (replaces ApplicationSet + Kustomize render at sync time).
- [ ] **ArgoCD OIDC Bootstrap**: ArgoCD caches a failed OIDC state when it starts before Authentik is healthy. After a fresh bootstrap a manual ArgoCD server restart is currently required.

## Productivity

- [ ] **Migrate TODO.md to GitHub**: Move this list to GitHub Issues + a Project (v2) board with labels/milestones instead of a flat markdown file.
