# Homelab Infrastructure - Proxmox Orchestration with OpenTofu

A comprehensive infrastructure-as-code solution for managing Proxmox VE
environments using OpenTofu, featuring automated VM provisioning, Talos
Kubernetes clusters, and streamlined cloud-init management.

## Overview

This project orchestrates a complete homelab infrastructure on Proxmox VE
using OpenTofu (Terraform fork). It provides:

- **Declarative Infrastructure**: YAML-based manifest for defining all
  infrastructure components
- **Automated VM/Container Provisioning**: Streamlined creation of VMs and LXC containers
- **Talos Kubernetes Integration**: Automated Talos cluster deployment and configuration
- **Cloud-Init Management**: Modular cloud-init configuration system
- **Image Management**: Automated download and checksum verification of OS images
- **Windows VM Support**: UEFI, TPM 2.0, and Secure Boot configuration for Windows 11

## Architecture

### Core Components

- **OpenTofu 1.11.1**: Infrastructure orchestration engine
- **Proxmox VE 9.0**: Virtualization platform
- **Talos Linux**: Kubernetes-focused OS for container workloads
- **Ubuntu 24.04 Noble**: General-purpose VM workloads
- **Debian Trixie (13)**: Alternative Linux distribution option
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
│   ├── 50-fleet/               # Virtual Machines & Containers
│   └── 60-talos-cluster/       # Talos Cluster Config
├── modules/                    # Reusable OpenTofu modules
│   ├── 10-pve-node-core/       # Proxmox Node Core Config
│   ├── 30-cloud-init/          # Cloud-Init Generation
│   └── ... (others)
└── templates/                  # Templates for Cloud-Init & Provisioning
    ├── 30-cloud-init/          # Secret injection templates (.tftpl)
    └── 60-talos-cluster/       # Talos configuration templates
```

## Infrastructure Workflow

### 1. Task-Based Automation

The project uses `go-task` with organized sub-taskfiles.

#### Infrastructure (`infra:*`)

These tasks manage the Proxmox infrastructure via OpenTofu.

- `task infra:prepare`: Initialize OpenTofu (`tofu init`), download plugins.
- `task infra:plan`: Generate an execution plan. Checks manifest validity.
- `task infra:apply`: Apply changes to Proxmox (Create VMs, Clusters, etc.).
- `task infra:destroy`: Tear down all managed infrastructure.
- `task infra:output`: Show Terraform outputs.
- `task infra:refresh`: Refresh infrastructure state (OpenTofu refresh).

### 2. Infrastructure Definition

Infrastructure is defined in a **split manifest structure** located in `infrastructure/manifest/*.yaml`. This allows for better organization and maintainability.

The configuration is loaded and merged by `locals.tf`.

#### Manifest Files

#### Manifest Directories

- **`00-cluster/`**: Cluster-wide configurations (PVE connection, ACME, Users).
- **`10-pve-node/`**: Node-specific configurations (Core settings, Repositories, Network).
- **`20-image/`**: Operating System images (Debian, Talos, Windows) with checksums.
- **`30-cloud-init/`**: Reusable Cloud-Init modules (Users, Vendor, Network).
- **`40-template/`**: VM and LXC Templates (Hardware specs, OS type).
- **`50-fleet/`**: Actual Virtual Machine and Container instances.
- **`60-talos-cluster/`**: Talos Cluster specific configuration (Control Plane/Worker topology).

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
  vm_talos_1_11_5:
    image_type: import
    image_filename: talos-1.11.5-nocloud-amd64.raw
    image_url: https://factory.talos.dev/image/b553b4a25d76e938fd7a9aaa7f887c06ea4ef75275e64f4630e6f8f739cf07df/v1.11.5/nocloud-amd64.raw
    image_checksum: "b106e0b4a6644045e895552877c68c5094d1eb77633a37d900ddfaeefdb8e29b"

  # Windows 11 ISO (manually provided)
  vm_windows_11_25h2:
    image_type: iso
    image_filename: windows-11-25H2-amd64.iso
    image_url: "" # manual upload
    image_checksum: ""
```

#### Templates Directory (`templates/`)

Contains text-based templates (`.tftpl`) used by OpenTofu's `templatefile()` function:

- **`30-cloud-init/`**: Environment files and scripts injected into VMs via Cloud-Init. Supports secret injection.
- **`60-talos-cluster/`**: Talos machine configuration patches and overrides.

#### VM Templates and Deployment

Defined in `vm_templates` and `virtual_machines` sections of the manifest. Supports:

- **Resource Policies**: Predefined sizes (small, medium, large)
- **Batches**: create N identical VMs (e.g., Talos workers)
- **Singles**: Individual bespoke VMs (e.g., Windows Gaming VM)

### 3. Cloud-Init Configuration System

Modular cloud-init configuration supporting:

- **User Configuration**: SSH keys, passwords, user creation
- **Vendor Configuration**: Package installation, system commands
- **Network Configuration**: Static/DHCP networking, DNS settings
- **Meta Configuration**: Hostname and metadata
- **Snap Configuration**: Native support for Snap packages (used for `lego` and `task`)

### 4. Management VM & Omni Setup (GitOps Light)

A dedicated management VM (`management-01`) hosts the **Omni** platform. The deployment follows a "GitOps Light" approach:

1.  **Bootstrapping**:

    - Cloud-Init provisions the VM (Ubuntu Noble).
    - Installs dependencies: `docker`, `git`, `snapd`.
    - Installs tools via Snap: `task` (classic), `lego`.
    - Configures secrets in `/opt/omni/.env` (injected from `terraform.tfvars`).
    - Clones the infrastructure repository to `/opt/homelab` using `GITHUB_TOKEN`.
    - Automatically triggers the local deployment task.

2.  **Deployment Workflow**:

    - **Local (on VM)**: `management/Taskfile.yaml` handles the actual deployment (symlinks `compose.yaml`, runs `docker compose`).
    - **Remote (from Host)**: `task mgmt:deploy-omni` connects via SSH, pulls the latest code, and triggers the local task.

3.  **Secrets Management**:
    - Secrets (Auth0, Github Token) are managed in `terraform.tfvars`.
    - They are injected into `/opt/omni/.env` by Cloud-Init.
    - `bootstrap-omni.sh` sources this file to authenticate git operations.

### 5. Talos Kubernetes Cluster

The project includes automated Talos Kubernetes cluster deployment.

**Architecture (Dec 2025):**
The cluster deployment is now split into two phases to avoid cyclic dependencies:

1.  **Infrastructure (OpenTofu)**: Provisions VMs and bootstraps Talos OS.
2.  **GitOps (ArgoCD)**: Deploys the CNI (Cilium) and Cloud Controller Manager (Talos CCM).

**Note**: The Talos CCM is responsible for approving kubelet serving certificates. Until `task cluster:bootstrap ENV=prod` runs, nodes may appear as `NotReady`.

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

### Talos Provider (siderolabs/talos)

- **Kubernetes Cluster Management**: Specialized cluster orchestration
- **Automated Bootstrapping**: Zero-touch cluster initialization

## Prerequisites

### Infrastructure Requirements

- **Proxmox VE 9.0+**: Accessible via API (port 8006)
- **Network**: DHCP server for VM/container IP assignment

### Development Environment

- **OpenTofu 1.11.1+**: Infrastructure orchestration
- **Talosctl**: Talos cluster management CLI

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

## Configuration

### APT Repositories

You can configure which APT repositories are enabled on your Proxmox nodes via `manifest/10-pve-node/pve-node-core.yaml`:

```yaml
pve_node_core:
  pve-1:
    repositories:
      enable_no_subscription: true
      enable_enterprise: false
      enable_ceph: false
```

### Secret Injection (Cloud-Init)

Secrets are securely injected into VMs using a template-based approach:

1.  **Define Secrets**: Store sensitive values in `terraform.tfvars` under `ci_secrets`.
2.  **Create Template**: Create a `.tftpl` file in `infrastructure/templates/` (e.g., `service.env.tftpl`).
3.  **Reference in Manifest**: Use `secret_ref` and `template_file` in your cloud-init manifest.

**Example `terraform.tfvars`**:

```hcl
ci_secrets = {
  my_service = {
    api_key = "secret-value"
  }
}
```

**Example Template (`service.env.tftpl`)**:

```bash
API_KEY=${api_key}
```

**Example Manifest (`ci-vendor-config.yaml`)**:

```yaml
write_files:
  - path: /etc/my-service/.env
    secret_ref: my_service
    template_file: templates/my-service/service.env.tftpl
```

## Troubleshooting

### Common Issues

**Issue**: Talos nodes are `NotReady` after `tofu-apply`.

- **Solution**: Run `task cluster:bootstrap ENV=prod` to deploy the CNI and CCM via ArgoCD.

**Issue**: Talos Nodes have random names (e.g. `talos-xyz-123`).

- **Solution**: Ensure your DHCP server is assigning hostnames correctly, or verify that the `talos-cluster` module is receiving the correct hostname map (currently relies on DHCP).

## License

See LICENSE file for details.
