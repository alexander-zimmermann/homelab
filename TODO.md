# TODO

## Observability

- [ ] **RustFS Monitoring**: Enable OTLP metrics export via Alloy once RustFS exposes meaningful S3 metrics (bucket ops, disk status). Configure `otelcol.receiver.otlp` in Alloy and add `PrometheusRule` for RustFS.

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
- [ ] **Telegraf NATS native**: Migrate Telegraf from MQTT protocol (`inputs.mqtt_consumer`) to native NATS protocol (`inputs.nats_consumer`) for solaredge topics. Enables direct JetStream access (replay, persistence).
- [ ] **KNX → NATS via Telegraf**: Expose KNX events on NATS for future AI/home-automation consumers. Add `outputs.nats` to Telegraf so the existing `inputs.knx_listener` data is published on subjects like `knx.<a>.<b>.<c>` alongside the current InfluxDB write. No separate KNX→MQTT bridge, no MQTT gateway involved. Today only InfluxDB 3 gets the data — nothing else on NATS does.

## GitOps

- [ ] **ArgoCD Source Hydrator**: Evaluate the [Source Hydrator](https://argo-cd.readthedocs.io/en/latest/user-guide/source-hydrator/) for pre-rendering manifests before sync (replaces ApplicationSet + Kustomize render at sync time).
- [ ] **ArgoCD OIDC Bootstrap**: ArgoCD caches a failed OIDC state when it starts before Authentik is healthy. After a fresh bootstrap a manual ArgoCD server restart is currently required.

## Platform

- [ ] **Omni**: Use secrets for sensitive data.
- [ ] **Readme**: Update project readme — see [buroa/k8s-gitops](https://github.com/buroa/k8s-gitops/tree/main) as reference.
