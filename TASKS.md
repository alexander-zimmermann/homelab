# Task List

**Status:** December 22, 2025  
**Goal:** Production-ready Talos Kubernetes Cluster for Homelab

---

## 📋 General To-Dos

### Refactoring

- [ ] **Longhorn Backup Target**: Configure NAS via NFS.
- [ ] **Velero Backup**: Install Helm Chart, configure S3 backend (MinIO/Cloud), schedule backups.
- [ ] **External DNS**: Automate DNS records for services (Cloudflare Integration).
- [ ] **Split Ingress Architecture**: Implement Dual Ingress Controller strategy (Internal vs DMZ).
  - Define Cilium IP Pools (Internal/DMZ).
  - Deploy `traefik-internal` & `traefik-external`.
  - Configure UDM VLAN/DMZ.
- [ ] **Optimizations**:
  - [ ] Prometheus Retention.
  - [ ] Traefik Retention.
  - [ ] InfluxDB Retention.
  - [ ] Evaluate CloudNativePG (CNPG) operator for Postgres.

### Documentation

- [ ] **Network Config**: Explain why `ipv4NativeRoutingCIDR: "10.244.0.0/16"` was configured.
- [ ] **README.md**: Cluster Specs (1 CP + 3 Workers), Bootstrap Procedure, Network Architecture Diagram.
- [ ] **Backup Strategy**: Document Talos machine-config backups, etcd snapshots, Longhorn snapshots, Velero strategy.
- [ ] **Disaster Recovery**: Document recovery procedures (Full Cluster Rebuild, Single Node Recovery, Data Restore).

---

## 🐳 Docker Migration Plan

### Wave 1: Tools (Low Hanging Fruits)

- [ ] **homepage**: Custom Deployment. Stateless.
- [ ] **gollum**: Custom Deployment. PVC 64M. Data migration required.
- [ ] **whoami**: Custom Deployment. Stateless.
- [x] **smtprelay**: Custom Deployment. Stateless.

### Wave 2: Observability - Exporters

- [ ] **unifi-poller**: Custom Deployment. Stateless
- [ ] **fritz-exporter**: Custom Deployment. Stateless
- [ ] **alloy**: Helm Chart (alloy/alloy). Stateless.

### Wave 3: Observability - Monitoring Stack

- [ ] **prometheus**: Helm Chart (prometheus-community/prometheus). PVC 5G. Data migration.
- [ ] **grafana**: Helm Chart (grafana/grafana). PVC 256M. Data migration.
- [ ] **loki**: Helm Chart (grafana/loki). PVC 512M. No data migration.
- [ ] **alertmanager**: Helm Chart (prometheus-community/alertmanager). PVC 16M. No data migration.

### Wave 4: Persistent Storage & Databases

- [ ] **postgres**: Helm Chart (bitnami/postgresql). PVC 256M. Data migration.
- [ ] **redis**: Helm Chart (bitnami/redis). PVC 16M. No data migration.
- [ ] **minio**: Helm Chart (minio/minio). PVC 16M. No data migration.

### Wave 5: Web Services

- [ ] **crowdsec**: Helm Chart (crowdsecurity/crowdsec). PVC 256M. Data migration.
- [ ] **traefik**: Helm Chart (traefik/traefik). PVC 32M. No data migration.
- [ ] **authelia**: Helm Chart (authelia/authelia). Stateless.
- [ ] **guacamole**: Custom Deployment. Stateless.

### Wave 6: Home Automation

- [ ] **influxdb**: Helm Chart (influxdb/influxdb2). PVC 10GB. Data migration.
- [ ] **mosquitto**: Custom Deployment, PVC 64M. Data migration.
  - [ ] Add fix IP from Cilium IP Pools
- [ ] **node-red**: Helm Chart (nodered/node-red). PVC 512M. Data migration.
- [ ] **solaredge2mqtt**: Custom Deployment. Stateless.

### Decommissioning

- [ ] **watchtower**: Not needed (ArgoCD handles updates).
- [ ] **portainer**: Not needed (Use ArgoCD/K9s/Lens).
- [ ] **node-exporter**: Replaced by Alloy/Kube-Prometheus.
- [ ] **blackbox-exporter**: Replaced by Alloy.
- [ ] **cadvisor**: Replaced by Alloy/Kubelet metrics.

---

## 🛠️ Implementation Strategy

For each application, we follow this standard GitOps workflow:

1.  **GitOps Structure**: Create `k8s-cluster/applications/<app>/`.
2.  **Manifests**:
    - Create `base/kustomization.yaml` (Deployment/StatefulSet, Service, PVC, ConfigMap OR Helm Chart).
    - Create `overlays/prod/kustomization.yaml` and `overlays/dev/kustomization.yaml`.
3.  **Secrets**: Seal sensitive env vars via `kubeseal`.
4.  **Ingress**: Define Traefik `IngressRoute` with Authelia Middleware (if public).
5.  **Data Migration**: `rsync` data from Docker bind-mounts to K8s PVCs (using temporary debug pods).
