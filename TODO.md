# TODO

## Observability

- [ ] **RustFS Monitoring**: Enable OTLP metrics export via Alloy once RustFS exposes meaningful S3 metrics (bucket ops, disk status). Configure `otelcol.receiver.otlp` in Alloy and add `PrometheusRule` for RustFS.
- [ ] **Gatus**: Deploy uptime monitoring for external ingress endpoints (wallbox, SolarEdge etc.) with GitHub status badges. Decision pending: self-hosted vs. SaaS.

## Infrastructure

- [ ] **Velero Backup**: Install Helm Chart, configure S3 backend (RustFS), schedule backups.
- [ ] **Split Ingress Architecture**: Dual Traefik strategy (`traefik-internal` & `traefik-external`) with UDM VLAN/DMZ separation.
- [ ] **ArgoCD**: Enable notification services.

## Optimizations

- [ ] **Traefik**: Configure log retention.
- [ ] **InfluxDB**: Configure data retention policies.
- [ ] **Cilium**: Implement network policies.

## Platform

- [ ] **Omni**: Use secrets for sensitive data.
- [ ] **Omni**: Switch to public IP.
- [ ] **Readme**: Update project readme — see [buroa/k8s-gitops](https://github.com/buroa/k8s-gitops/tree/main) as reference.
