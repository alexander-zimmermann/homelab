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
- [ ] **KNX → NATS via Telegraf**: Expose KNX events on NATS for future AI/home-automation consumers. Add `outputs.nats` to Telegraf so the existing `inputs.knx_listener` data is published on subjects like `knx.<a>.<b>.<c>` alongside the current InfluxDB write. No separate KNX→MQTT bridge, no MQTT gateway involved. Today only InfluxDB 3 gets the data — nothing else on NATS does.

## GitOps

- [ ] **ArgoCD Source Hydrator**: Evaluate the [Source Hydrator](https://argo-cd.readthedocs.io/en/latest/user-guide/source-hydrator/) for pre-rendering manifests before sync (replaces ApplicationSet + Kustomize render at sync time).
- [ ] **ArgoCD OIDC Bootstrap**: ArgoCD caches a failed OIDC state when it starts before Authentik is healthy. After a fresh bootstrap a manual ArgoCD server restart is currently required.

## Productivity

- [ ] **Migrate TODO.md to GitHub**: Move this list to GitHub Issues + a Project (v2) board with labels/milestones instead of a flat markdown file.
- [ ] **Readme**: Update project readme — see [buroa/k8s-gitops](https://github.com/buroa/k8s-gitops/tree/main) as reference.
- [ ] **Kromgo README badges**: Add a scheduled GitHub Actions workflow that fetches the [kromgo](kubernetes/applications/kromgo/base/config/kromgo.yaml) endpoints at `kromgo.zimmermann.sh` using the Cloudflare Access Service Token (stored as GH repo secrets `CF_ACCESS_CLIENT_ID` / `CF_ACCESS_CLIENT_SECRET`) and rewrites the static shields.io badges in `README.md`. Needed because GitHub's image proxy (Camo) can't forward custom headers, so a direct shields.io → kromgo request would be blocked by CF Access.
