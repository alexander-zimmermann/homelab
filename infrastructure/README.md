# Homelab Infrastructure - Proxmox Orchestration with OpenTofu

A comprehensive infrastructure-as-code solution for managing Proxmox VE environments using OpenTofu, featuring automated VM provisioning, Talos Kubernetes clusters, and streamlined cloud-init management.

## Overview

This project orchestrates a complete homelab infrastructure on Proxmox VE using OpenTofu (Terraform fork). It provides:

- **Declarative Infrastructure**: YAML-based manifest for defining all infrastructure components
- **Automated VM/Container Provisioning**: Streamlined creation of VMs and LXC containers
- **Talos Kubernetes Integration**: Automated Talos cluster deployment via Sidero Omni
- **Cloud-Init Management**: Modular cloud-init configuration system
- **Image Management**: Automated download and checksum verification of OS images
- **Windows VM Support**: UEFI, TPM 2.0, and Secure Boot configuration for Windows 11

## Architecture

### Core Components

- **OpenTofu 1.11.1**: Infrastructure orchestration engine
- **Proxmox VE 9.0**: Virtualization platform
- **Talos Linux**: Kubernetes-focused OS for container workloads
- **Sidero Omni**: Management platform for Talos clusters
- **Ubuntu 24.04 Noble**: General-purpose VM workloads
- **Windows 11 25H2**: Windows workloads with modern security features

### Project Structure

```bash
infrastructure/
├── main.tf                     # Primary configuration
├── locals.tf                   # Logic & Manifest loading
├── variables.tf                # Input variables definitions
├── outputs.tf                  # Output values definitions
├── versions.tf                 # Provider & Terraform versions
├── terraform.tfvars.example    # Example variable values
├── manifest/                   # YAML definitions (The "Source of Truth")
│   ├── 00-cluster/             # Cluster-wide settings (PVE connection)
│   ├── 10-pve-node/            # Node configurations (Core, Network)
│   ├── 20-image/               # OS Image definitions
│   ├── 30-cloud-init/          # Cloud-Init config (users, vendor, net)
│   ├── 40-template/            # VM/LXC Templates
│   └── 50-fleet/               # Virtual Machines & Containers
├── modules/                    # Reusable OpenTofu modules
│   ├── 10-pve-node-core/       # Proxmox Node Core Config
│   ├── 30-cloud-init/          # Cloud-Init Generation
│   └── ... (others)
└── templates/                  # Templates for Cloud-Init & Provisioning
    └── 30-cloud-init/          # Secret injection templates (.tftpl)
```

## Infrastructure Workflow

### 1. Task-Based Automation

The project uses `go-task` with organized sub-taskfiles.

#### Infrastructure (`infra:*`)

These tasks manage the Proxmox infrastructure via OpenTofu.

- `task infra:init`: Initialize OpenTofu (`tofu init`), download plugins.
- `task infra:status`: Generate an execution plan (`tofu plan`). Checks for drift.
- `task infra:create`: Apply changes to Proxmox (`tofu apply`). **Zero-to-Hero infra command.**
- `task infra:delete`: Tear down all managed infrastructure.
- `task infra:show`: Show Terraform outputs.

### 2. Infrastructure Definition

Infrastructure is defined in a **split manifest structure** located in `infrastructure/manifest/*.yaml`. This allows for better organization and maintainability.

The configuration is loaded and merged by `locals.tf`.

#### Manifest Directories

- **`00-cluster/`**: Cluster-wide configurations (PVE connection, ACME, Users).
- **`10-pve-node/`**: Node-specific configurations (Core settings, Repositories, Network).
- **`20-image/`**: Operating System images (Debian, Talos, Windows) with checksums.
- **`30-cloud-init/`**: Reusable Cloud-Init modules (Users, Vendor, Network).
- **`40-template/`**: VM and LXC Templates (Hardware specs, OS type).
- **`50-fleet/`**: Actual Virtual Machine and Container instances.

#### Example: Image Specifications (`20-image/`)

```yaml
image:
  # Debian Cloud Image
  vm_debian_trixie:
    image_type: import
    image_filename: debian-13-genericcloud-amd64.qcow2
    image_url: https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2
    image_checksum: "e5563c7bb388eebf7df385e99ee36c83cd16ba8fad4bd07f4c3fd725a6f1cf1cb9f54c6673d4274a856974327a5007a69ff24d44f9b21f7f920e1938a19edf7e"
    image_checksum_algorithm: "sha512"

  # Talos Linux (Factory build)
  vm_talos_1_12_0:
    image_type: import
    image_filename: talos-1.12.0-nocloud-amd64.raw
    image_url: https://factory.talos.dev/image/.../nocloud-amd64.raw
    image_checksum: "b106e0b4a6644045e895552877c68c5094d1eb77633a37d900ddfaeefdb8e29b"
```

#### Templates Directory (`templates/`)

Contains text-based templates (`.tftpl`) used by OpenTofu's `templatefile()` function:

- **`30-cloud-init/`**: Environment files and scripts injected into VMs via Cloud-Init. Supports secret injection.

### 3. Cloud-Init Configuration System

Modular cloud-init configuration supporting:

- **User Configuration**: SSH keys, passwords, user creation
- **Vendor Configuration**: Package installation, system commands
- **Network Configuration**: Static/DHCP networking, DNS settings
- **Meta Configuration**: Hostname and metadata
- **Snap Configuration**: Native support for Snap packages (used for `lego` and `task`)

### 4. Management VM & Omni Setup

A dedicated management VM (`management-01` / `cluster-mgmt`) hosts the **Omni** platform.

- **Storage**: Persistent data on `/mnt/omni`.
- **Config**: Ephemeral managed config in `/opt/omni` (Docker Compose, Envs).
- **Bootstrap**: Cloud-Init Native:
  - Cloud-Init injects `omni-compose.yaml` and `.env` files directly.
  - `omni-bootstrap.sh` handles Init (Certificates, GPG) and Startup.
  - No external git clone required during boot.

### 5. Talos Kubernetes Cluster

The project includes automated Talos Kubernetes cluster deployment via **Sidero Omni**.

1.  **Infrastructure Provisioning**: OpenTofu creates the VMs (`infra:create`).
2.  **Omni Registration**: VMs boot custom images (generated via `cluster:init`) and register with Omni.
3.  **Machine Classes**: Defined in Omni (via `cluster:create`) to automatically assign roles (Control Plane / Worker) based on generic hardware or labels.

### 5. Advanced Features

#### Deterministic MAC Address Generation

All VMs and containers receive deterministic MAC addresses based on their ID:

- **VMs**: `02:01:00:XX:XX:XX` format (based on VM ID)
- **Containers**: `02:02:00:XX:XX:XX` format (based on Container ID)
- **Benefits**: Stable DHCP IP assignments across reboots and redeployments

#### Windows 11 Support

Full support for modern Windows VMs:

- **UEFI Boot**: `bios: ovmf` for modern boot process
- **TPM 2.0**: Hardware security module for BitLocker and Windows 11 requirements
- **Secure Boot**: Pre-enrolled keys for secure boot validation
- **Q35 Machine Type**: Modern chipset emulation
- **VirtIO Drivers**: Automated ISO attachment for optimal performance

## Provider Configuration

### Proxmox Provider (bpg/proxmox)

- **Primary Management**: VM/container lifecycle management
- **API Communication**: RESTful API integration with Proxmox VE

## Prerequisites

### Infrastructure Requirements

- **Proxmox VE 9.0+**: Accessible via API (port 8006)
- **Network**: DHCP server for VM/container IP assignment

### Development Environment

- **OpenTofu 1.11.1+**: Infrastructure orchestration
- **Talosctl**: Talos cluster management CLI
- **Omnictl**: Sidero Omni CLI

### Authentication and Access

Configure Proxmox credentials and subscription keys in `terraform.tfvars`:

```hcl
# Proxmox API Authentication
pve_cluster_token_id     = "YOUR_PVE_TOKEN_ID"
pve_cluster_token_secret = "YOUR_PVE_TOKEN_SECRET"
pve_cluster_password     = "YOUR_PVE_PASSWORD" # Optional (Console Access)

# Proxmox Subscription Keys (Optional)
pve_node_core_subscription_keys = {
  pve-1 = "YOUR_SUBSCRIPTION_KEY"
}
```

## Troubleshooting

### Common Issues

**Issue**: Talos nodes are `NotReady`.

- **Solution**: Check Sidero Omni dashboard. Ensure Machine Classes are registered (`task cluster:create`).

**Issue**: `tofu taint` doesn't trigger rebuild.

- **Solution**: `task infra:status` (Plan) checks for state changes. Ensure `task infra:create` applies the plan (`tofu apply tfplan`).

## License

See LICENSE file for details.
