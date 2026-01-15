# Task List

**Status:** December 22, 2025  
**Goal:** Production-ready Talos Kubernetes Cluster for Homelab

---

## 📋 General To-Dos

### Refactoring

- [ ] **Longhorn Backup Target**: Configure NAS via NFS.
- [ ] **Velero Backup**: Install Helm Chart, configure S3 backend (MinIO/Cloud), schedule backups.
- [ ] **Proxmox Backup Server**: Setup PBS (LXC/VM), Configure Storage (NAS), Backup Jobs for Omni.
- [ ] **External DNS**: Automate DNS records for services (Cloudflare Integration).
- [ ] **Split Ingress Architecture**: Implement Dual Ingress Controller strategy (Internal vs DMZ).
  - Define Cilium IP Pools (Internal/DMZ).
  - Deploy `traefik-internal` & `traefik-external`.
  - Configure UDM VLAN/DMZ.
- [ ] **Optimizations**:
  - [x] Prometheus Retention.
  - [] Traefik Retention.
  - [ ] InfluxDB Retention.
  - [ ] Evaluate CloudNativePG (CNPG) operator for Postgres.
- [x] **Loki**: Migrate to Scalable/Microservice Mode (MinIO Backend) when storage is ready.
- [ ] **Omni**:
  - [ ] Use docker secrets for sensitive data.
  - [ ] Create service account for Omni.
  - [ ] Use Public IP for Omni.

### Documentation

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

- [o] **unifi-poller**: Custom Deployment. Stateless
- [ ] **fritz-exporter**: Custom Deployment. Stateless
- [/] **alloy**: Helm Chart (grafana/k8s-monitoring). Stateless.

### Wave 3: Observability - Monitoring Stack

- [/] **prometheus**: Helm Chart (prometheus-community/prometheus). PVC 5G. Data migration.
- [/] **grafana**: Helm Chart (grafana/grafana). PVC 256M. Data migration.
- [x] **loki**: Helm Chart (grafana/loki). PVC 512M. No data migration.
- [/] **alertmanager**: Helm Chart (prometheus-community/alertmanager). PVC 16M. No data migration.

### Wave 4: Persistent Storage & Databases

- [ ] **postgres**: Helm Chart (bitnami/postgresql). PVC 256M. Data migration.
- [ ] **redis**: Helm Chart (bitnami/redis). PVC 16M. No data migration.
- [x] **minio**: Helm Chart (minio/minio). PVC 5G. No data migration.

### Wave 5: Web Services

- [ ] **crowdsec**: Helm Chart (crowdsecurity/crowdsec). PVC 256M. Data migration.
- [ ] **traefik**: Helm Chart (traefik/traefik). PVC 32M. No data migration.
- [ ] **authelia**: Helm Chart (authelia/authelia). Stateless.
- [ ] **guacamole**: Custom Deployment. Stateless.

### Wave 6: Home Automation

- [ ] **influxdb**: Helm Chart (influxdb/influxdb2). PVC 10GB. Data migration.
- [] **mosquitto**: Custom Deployment, PVC 64M. Data migration.
  - [x] Add fix IP from Cilium IP Pools
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

For each application, we follow this strict GitOps workflow:

1.  **GitOps Structure**: Create `k8s-cluster/applications/<app>/`.

    - `base/` : Pure application logic (Deployment, ConfigMaps, default Service type ClusterIP). **NO** environment logic here.
    - `overlays/prod/`: Production environment (Fixed IPs, High Resources).
    - `overlays/dev/`: Development environment (Dynamic IPs, Low Resources).

2.  **Kustomize Patching (Strict JSON Patch)**:

    - **Format**: ALWAYS use **JSON Patch** (`op: replace/add`) for all patches. Do NOT use Strategic Merge Patch (YAML style).
    - **Order**: In `kustomization.yaml`, `patches:` list must observe:
      1. App Config Patches (Args, Env, Mounts)
      2. Ingress/Cert Patches
      3. **Network/Service Patches (ALWAYS LAST)**
    - **Values**: Always specify `patch:` block first, then `target:` block.

3.  **Network & Cilium BGP**:

    - **Service Config**: Defined **ONLY in Overlays**. Base keeps `type: ClusterIP` (or default).
    - **Production**:
      - `type: LoadBalancer`
      - Annotation: `io.cilium/lb-ipam-ips: "192.168.10.XX"` (Fixed IP)
      - Labels: `bgp.cilium.io/ip-pool: default` (Escaped: `bgp.cilium.io~1ip-pool`)
    - **Development**:
      - `type: LoadBalancer`
      - **NO** Fixed IP (Dynamic allocation)
      - Labels: `bgp.cilium.io/ip-pool: default`

4.  **Ingress**:

    - Use Traefik `IngressRoute`.
    - Patch `Host(...)` and `Certificate` DNS separately in overlays.

5.  **Secrets**: Seal sensitive env vars via `kubeseal` to `sealedsecret.yaml`.
