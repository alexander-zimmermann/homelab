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

- **OpenTofu 1.10.6**: Infrastructure orchestration engine
- **Proxmox VE 9.0**: Virtualization platform
- **Talos Linux**: Kubernetes-focused OS for container workloads
- **Ubuntu 24.04 Noble**: General-purpose VM workloads
- **Debian Trixie (13)**: Alternative Linux distribution option
- **Windows 11 25H2**: Windows workloads with modern security features

### Project Structure

```bash
infrastructure/
├── infrastructure-manifest.yaml    # Main infrastructure definition
├── generated.auto.tfvars           # Auto-generated OpenTofu variables
├── main.tf                         # Primary OpenTofu configuration
├── locals.tf                       # Local variables and computations
├── variables.tf                    # Input variable definitions
├── outputs.tf                      # Output definitions
├── providers.tf                    # Provider configurations
├── versions.tf                     # Provider version constraints
├── terraform.tfvars.example        # Example credentials file
├── modules/                        # Reusable OpenTofu modules
│   ├── image/                      # Image download and management
│   ├── vm_template/                # VM template creation
│   ├── container_template/         # LXC template creation
│   ├── vm_clone/                   # VM cloning and provisioning
│   ├── container_clone/            # LXC container cloning
│   ├── vm_cloud-init/              # Cloud-init configuration
│   ├── talos-cluster/              # Talos cluster management
│   ├── pve_nodes/                  # Proxmox node configuration
│   ├── pve_user_mgmt/              # User and role management
│   ├── pve_network/                # Network configuration
│   └── pve_acme/                   # ACME certificate management
├── scripts/                        # Python utilities
│   ├── generate_tfvars.py          # Generate OpenTofu variables from manifest
│   ├── download_checksums.py       # Image checksum management
│   └── logging_formatter.py        # Shared logging utilities
├── templates/                      # Jinja2 templates
│   └── generated.auto.tfvars.j2    # Variable generation template
├── schemas/                        # Validation schemas
│   └── infrastructure-manifest.schema.json
├── build/                          # Build artifacts
│   └── checksums.yaml              # Downloaded image checksums
└── talos/                          # Talos-related files
  └── config/                     # Talos machine config patches + image factory schematic
      ├── baseline.yaml.tpl        # Applied to all nodes (control plane + workers)
      ├── dataplane.yaml.tpl       # Data plane only patch
      ├── controlplane.yaml.tpl    # Control plane only patch
      └── imagefactory.yaml        # Image Factory schematic (extensions/kernel args)
```

## Infrastructure Workflow

### 1. Task-Based Automation

The project uses a Task-based workflow with the following key commands:

#### `task initialize`

Sets up the development environment:

- Installs required dependencies (OpenTofu, Python packages, etc.)
- Creates Python virtual environment
- Prepares the workspace for infrastructure management

```bash
task initialize
```

#### `task tofu-prepare`

Comprehensive preparation pipeline:

1. **Template rendering**: Generates `generated.auto.tfvars` from manifest using Python script
2. **Checksum download**: Fetches and verifies image checksums from upstream sources
3. **Validation**: Ensures manifest consistency and correctness

```bash
task tofu-prepare
```

This automatically:

- Runs `scripts/generate_tfvars.py` with the infrastructure manifest
- Downloads checksums via `scripts/download_checksums.py`
- Validates the generated configuration

#### `task tofu-plan`

- Executes OpenTofu planning phase
- Shows infrastructure changes without applying them
- Depends on `tofu-prepare` for current configuration

```bash
task tofu-plan
```

#### `task tofu-apply`

- Applies planned infrastructure changes to Proxmox
- Creates VMs, containers, and Talos clusters
- Depends on successful planning phase

```bash
task tofu-apply
```

#### `task k8s-bootstrap-prod`

**Critical Step**: Use this to finalize the Cluster deployment after `tofu-apply`.

- Connects to the new cluster API.
- Installs ArgoCD.
- Deploys Core Components via GitOps (Cilium CNI, Talos Cloud Controller Manager).
- Approves Node CSRs automatically via CCM.

```bash
task k8s-bootstrap-prod
```

#### `task tofu-destroy`

- Tears down all managed infrastructure
- Removes VMs, containers, and associated resources
- Useful for environment reset or cleanup

```bash
task tofu-destroy
```

### 2. Infrastructure Definition

Infrastructure is defined in `infrastructure-manifest.yaml` using a structured
YAML format.

#### Image Specifications

```yaml
images:
  # Debian Cloud Image
  vm_debian_trixie:
    distro: debian
    release: trixie # Debian 13
    arch: amd64
    extension: qcow2

  # Talos Linux (Factory build with custom extensions)
  vm_talos_1_11_5:
    distro: talos
    release: "1.11.5"
    variant: nocloud
    schematic: b553b4a25d76e938fd7a9aaa7f887c06ea4ef75275e64f4630e6f8f739cf07df
    extension: raw

  # Note on Talos images:
  # - The Image Factory schematic is tracked in `talos/config/imagefactory.yaml`.
  # - OpenTofu downloads the actual Talos image to Proxmox via `image_url` (factory URL).

  # Windows 11 ISO (manually provided)
  vm_windows_11_25h2:
    distro: windows
    release: "11-25H2"
    arch: amd64
    extension: iso
```

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

### 4. Talos Kubernetes Cluster

The project includes automated Talos Kubernetes cluster deployment.

**Architecture Change (Dec 2025):**
The cluster deployment is now split into two phases to avoid cyclic dependencies:

1.  **Infrastructure (OpenTofu)**: Provisions VMs and bootstraps Talos OS.
2.  **GitOps (ArgoCD)**: Deploys the CNI (Cilium) and Cloud Controller Manager (Talos CCM).

**Note**: The Talos CCM is responsible for approving kubelet serving certificates. Until `task k8s-bootstrap-prod` runs, nodes may appear as `NotReady`.

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

- **OpenTofu 1.10.6+**: Infrastructure orchestration
- **Python 3.8+**: Template generation scripts
- **Talosctl**: Talos cluster management CLI

### Authentication and Access

Configure Proxmox credentials in `terraform.tfvars`:

```hcl
# Proxmox API Authentication
pve_endpoint = "https://192.168.1.100:8006"
pve_username = "root@pam"
pve_password = "your-password"
```

## Troubleshooting

### Common Issues

**Issue**: Talos nodes are `NotReady` after `tofu-apply`.

- **Solution**: Run `task k8s-bootstrap-prod` to deploy the CNI and CCM via ArgoCD.

**Issue**: Proxmox Console shows white screen.

- **Solution**:
  - If accessing via Cloudflare, disable **Rocket Loader** in Cloudflare settings.
  - Check if Cloudflare is injecting `X-Frame-Options: DENY`.
  - Try accessing Proxmox via local IP to verify VM health.

**Issue**: Talos Nodes have random names (e.g. `talos-xyz-123`).

- **Solution**: Ensure your DHCP server is assigning hostnames correctly, or verify that the `talos-cluster` module is receiving the correct hostname map (currently relies on DHCP).

## License

See LICENSE file for details.
