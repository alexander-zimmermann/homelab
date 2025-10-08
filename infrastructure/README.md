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
- **Talos 1.11.5**: Kubernetes-focused OS for container workloads
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
└── talos/                          # Talos cluster artifacts
    ├── talosconfig                 # Talos cluster configuration
    └── kubeconfig                  # Kubernetes configuration
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

#### `task tofu-destroy`

- Tears down all managed infrastructure
- Removes VMs, containers, and associated resources
- Useful for environment reset or cleanup

```bash
task tofu-destroy
```

### 2. Infrastructure Definition

Infrastructure is defined in `infrastructure-manifest.yaml` using a structured
YAML format:

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

  # Windows 11 ISO (manually provided)
  vm_windows_11_25h2:
    distro: windows
    release: "11-25H2"
    arch: amd64
    extension: iso

  # Ubuntu LXC Container Template
  lxc_ubuntu_plucky:
    distro: ubuntu
    release: plucky
    arch: amd64
    build_date: "20251120_09:26"
    extension: tar.xz
```

#### VM Templates

#### VM Templates

```yaml
resource_policies:
  vm_small:
    memory: 1024
    cores: 1
    disk: 10
    network_bridge: vmbr0

  vm_large:
    memory: 4096
    cores: 4
    disk: 40
    network_bridge: vmbr0

vm_templates:
  # Linux template with cloud-init
  vm_debian_trixie:
    vm_id: 10000
    image: vm_debian_trixie
    os_type: l26
    resource_policy: vm_small
    cloud_init_profile: ci_profile_std_linux

  # Talos template (no cloud-init)
  vm_talos_1_11_5:
    vm_id: 10002
    image: vm_talos_1_11_5
    os_type: l26
    resource_policy: vm_medium

  # Windows 11 with UEFI, TPM 2.0, and Secure Boot
  vm_windows_11_25h2:
    vm_id: 10003
    image: vm_windows_11_25h2
    os_type: win11
    resource_policy: vm_large
    bios: ovmf # UEFI boot
    enable_tpm: true # TPM 2.0 support
    secure_boot: true # Secure Boot enabled
```

#### Container Templates

```yaml
container_templates:
  lxc_ubuntu_plucky:
    lxc_id: 15000
    image: lxc_ubuntu_plucky
    os_type: ubuntu
    resource_policy: lxc_small
```

#### Virtual Machine Deployment

```yaml
virtual_machines:
  singles:
    # Single VM instances
    debian_01:
      template_id: vm_debian_trixie
      vm_id: 1000

    windows_01:
      template_id: vm_windows_11_25h2
      vm_id: 1100
      wait_for_agent: false # Manual setup required

  batches:
    # Batch deployment for Talos cluster
    talos_cp:
      template_id: vm_talos_1_11_5
      count: 1
      vm_id_start: 2000

    talos_dp:
      template_id: vm_talos_1_11_5
      count: 1
      vm_id_start: 2100
```

#### Container Deployment

```yaml
containers:
  singles:
    ubuntu_ct_01:
      template_id: lxc_ubuntu_plucky
      lxc_id: 5000
```

### 3. Cloud-Init Configuration System

### 3. Cloud-Init Configuration System

Modular cloud-init configuration supporting:

- **User Configuration**: SSH keys, passwords, user creation
- **Vendor Configuration**: Package installation, system commands
- **Network Configuration**: Static/DHCP networking, DNS settings
- **Meta Configuration**: Hostname and metadata

```yaml
ci_user_configs:
  ci_user_std_linux:
    username: alexander
    ssh_public_key: ~/.ssh/id_rsa.pub
    set_password: false

ci_vendor_configs:
  ci_vendor_std_linux:
    packages:
      - htop
      - vim
      - qemu-guest-agent

vm_cloud_init_profiles:
  ci_profile_std_linux:
    description: "Standard Linux configuration"
    ci_user_data_id: ci_user_std_linux
    ci_vendor_data_id: ci_vendor_std_linux
    ci_network_data_id: ci_net_std_linux
    ci_meta_data_id: ci_meta_std_linux
```

### 4. Talos Kubernetes Cluster

### 4. Talos Kubernetes Cluster

The project includes automated Talos Kubernetes cluster deployment:

```yaml
talos_configuration:
  cluster_name: "homelab"
  kubernetes_version: "1.30.0"
```

Features:

- **Automated bootstrapping**: Zero-touch cluster initialization
- **Control plane nodes**: Deployed from `talos_cp` batch
- **Data plane nodes**: Deployed from `talos_dp` batch
- **Deterministic networking**: MAC address generation for stable DHCP assignments

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

### Proxmox Provider (bpg/proxmox v0.87.0)

- **Primary Management**: VM/container lifecycle management
- **API Communication**: RESTful API integration with Proxmox VE
- **Template Support**: VM/container template creation and cloning
- **Cloud-Init Integration**: Automated guest configuration
- **Image Management**: ISO and disk image handling

### Talos Provider (siderolabs/talos v0.9.0)

- **Kubernetes Cluster Management**: Specialized cluster orchestration
- **Automated Bootstrapping**: Zero-touch cluster initialization
- **Node Configuration**: Control plane and data plane node setup
- **Machine Configuration**: Talos-specific system configuration

### Supporting Providers

- **Local**: Local file and data management for cloud-init snippets
- **TLS**: Certificate and key generation for secure communications
- **Random**: ID and password generation for security
- **Null**: Resource lifecycle hooks and triggers

## Prerequisites

### Infrastructure Requirements

- **Proxmox VE 9.0+**: Accessible via API (port 8006)
- **Network**: DHCP server for VM/container IP assignment
- **Storage**: Sufficient storage for VM images, containers, and disks
  - File storage: local (for ISOs, templates, snippets)
  - Block storage: local-zfs (for VM/container disks)

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

# SSH Configuration for Network Management
pve_ssh_username = "root"
pve_ssh_private_key = "/path/to/private/key"
pve_ssh_use_agent = false

# Node Configuration
pve_nodes = {
  "pve-1" = {
    address = "192.168.1.100"
    port    = 22
  }
  "pve-2" = {
    address = "192.168.1.101"
    port    = 22
  }
}
```

## Getting Started

1. **Clone Repository**:

   ```bash
   git clone <repository-url>
   cd homelab/infrastructure
   ```

2. **Configure Credentials**:

   Create `terraform.tfvars`:

   ```hcl
   pve_endpoint = "https://your-proxmox-server:8006"
   pve_username = "root@pam"
   pve_password = "your-password"
   ```

3. **Configure Infrastructure**:

   Edit `infrastructure-manifest.yaml` to define your desired infrastructure

4. **Generate Variables**:

   ```bash
   python3 scripts/generate_tfvars.py
   ```

5. **Initialize OpenTofu**:

   ```bash
   tofu init
   ```

6. **Plan Deployment**:

   ```bash
   tofu plan
   ```

7. **Apply Infrastructure**:

   ```bash
   tofu apply
   ```

## Current Deployment

The current configuration deploys:

- **2 Linux VMs**: Debian Trixie and Ubuntu Noble (VMID 1000-1001)
- **1 Windows VM**: Windows 11 25H2 with UEFI/TPM/SecureBoot (VMID 1100)
- **2 Talos VMs**: Control plane and data plane nodes (VMID 2000, 2100)
- **1 Ubuntu Container**: LXC container (CTID 5000)
- **Talos Kubernetes Cluster**: Single control plane + single data plane

All resources use:

- DHCP for IP assignment
- Deterministic MAC addresses for stable IPs
- Cloud-init for automated Linux VM configuration
- QEMU Guest Agent for VM management

## Advanced Topics

### MAC Address Format

VMs and containers receive predictable MAC addresses:

```
VMs:        02:01:00:XX:XX:XX  (XX:XX:XX from VM ID)
Containers: 02:02:00:XX:XX:XX  (XX:XX:XX from Container ID)
```

Example:

- VM 1000 → `02:01:00:00:03:e8`
- Container 5000 → `02:02:00:00:13:88`

### Windows VM Installation

Windows VMs require manual installation steps:

1. VM is created with ISO attached
2. Boot from ISO and follow Windows installation
3. Install VirtIO drivers during setup (from virtio-win.iso)
4. Complete Windows installation
5. QEMU Guest Agent will report IP after installation

### Talos Cluster Access

After deployment, access your Talos cluster:

```bash
# Get talosconfig
export TALOSCONFIG=./talosconfig

# Check cluster status
talosctl health --nodes <control-plane-ip>

# Get kubeconfig
talosctl kubeconfig
```

## Troubleshooting

### Common Issues

**Issue**: VM fails to start after cloning

- **Solution**: Check disk storage availability on target node

**Issue**: Cloud-init not applying configuration

- **Solution**: Verify cloud-init snippets are in Proxmox file storage

**Issue**: Talos cluster not bootstrapping

- **Solution**: Ensure VMs have network connectivity and DHCP assigns IPs

**Issue**: Windows VM not showing IP

- **Solution**: Complete Windows installation and install QEMU Guest Agent

### Useful Commands

```bash
# Refresh Terraform state
tofu refresh

# Destroy specific resource
tofu destroy -target='module.vm_clone["debian_01"]'

# View current state
tofu show

# Validate configuration
tofu validate
```

## License

See LICENSE file for details.
