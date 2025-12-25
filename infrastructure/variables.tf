###############################################################################
## PVE API connection & auth
###############################################################################
variable "pve_api_url" {
  description = <<EOT
    Full URL to the Proxmox API endpoint. Must include the scheme (`http` or `https`)
    and end with `/api2/json`. Example: `https://pve.example.com/api2/json`.
  EOT
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("(?i)^http[s]?://.*/api2/json$", var.pve_api_url))
    error_message = "Proxmox API Endpoint Invalid. Check URL - Scheme and Path required."
  }
}

variable "pve_token_id" {
  description = <<EOT
    Identifier of the Proxmox API token used for authentication. Must follow
    the format `username!tokenname`, where `username` includes the realm (e.g.,
    `admint@pam!mytoken`).
  EOT
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[^!]+![^!]+$", var.pve_token_id))
    error_message = "pve_token_id must follow the format 'username!tokenname'."
  }
}

variable "pve_token_secret" {
  description = <<EOT
    Secret value of the Proxmox API token. This is used together with `pve_token_id`
    to authenticate API requests. Sensitive value.
  EOT
  type        = string
  sensitive   = true
}

variable "pve_username" {
  description = <<EOT
    Full username with realm used for API authentication when operations are not
    supported via API token (e.g., ACME account creation). Example: `root@pam`.
  EOT
  type        = string
  default     = "root@pam"
}

variable "pve_password" {
  description = <<EOT
    Password for API authentication when not using an API token. Required for
    operations that require full user privileges. Sensitive value.
  EOT
  type        = string
  sensitive   = true
}

variable "pve_insecure" {
  description = <<EOT
    If set to `true`, TLS certificate verification will be skipped when connecting
    to the Proxmox API. This is useful for development or lab environments but
    should be disabled in production.
  EOT
  type        = bool
  default     = true
}



###############################################################################
## PVE SSH across all cluster nodes
##############################################################################
variable "pve_ssh_username" {
  description = <<EOT
    SSH access is needed for operations that cannot be performed via the Proxmox API.
    PAM user present on every Proxmox node. This user must have passwordless sudo
    privileges for executing required system commands. Required when SSH is used.
  EOT
  type        = string
  default     = "opentofu"
  sensitive   = true

  validation {
    condition     = can(regex("^[a-z_][a-z0-9_-]{0,31}$", var.pve_ssh_username))
    error_message = "pve_ssh_username must be a valid Linux username."
  }
}


variable "pve_ssh_use_agent" {
  description = <<EOT
    Whether to use `ssh-agent` for authentication via the `SSH_AUTH_SOCK` environment
    variable. If set to `true`, the system will use the agent to retrieve SSH credentials.
    If set to `false`, a PEM-encoded private key must be provided via `pve_ssh_private_key`.
  EOT
  type        = bool
  default     = true
}

variable "pve_ssh_private_key" {
  description = <<EOT
    Path to the PEM-encoded private key used for SSH authentication when not
    using `ssh-agent`. Required if `pve_ssh_use_agent` is `false`.
    Example: `~/.ssh/id_ed25519`.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.pve_ssh_use_agent || (var.pve_ssh_private_key != null && length(var.pve_ssh_private_key) > 0)
    error_message = "pve_ssh_private_key must be set when pve_ssh_use_agent is false."
  }
}

variable "pve_nodes" {
  description = <<EOT
    A map of Proxmox nodes used to configure SSH access for the provider. Each key
    represents the name of a Proxmox node (e.g., `pve`, `pve01`, `pve02`), and the
    value is an object containing:

    - address: The IP or hostname of the PVE node.
    - port: Optional SSH port (defaults to `22`).

    This variable is used to dynamically configure SSH access per node in the
    `proxmox` provider block. The node names must match those used elsewhere in
    the configuration (e.g., `target_node` in image definitions).
  EOT
  type = map(object({
    address = string
    port    = optional(number, 22)
  }))

  validation {
    condition = alltrue([
      for node_name, node in var.pve_nodes : (
        length(trimspace(node_name)) > 0 &&
        can(regex("^[a-zA-Z][a-zA-Z0-9_-]*$", node_name)) &&
        length(trimspace(node.address)) > 0 &&
        (
          can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", node.address)) ||
          can(regex("^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$", node.address))
        ) &&
        (node.port >= 1 && node.port <= 65535)
      )
    ])
    error_message = <<EOM
      Each PVE node must meet these rules:
      - node_name must be a non-empty string starting with a letter, containing only
        alphanumeric characters, underscores, or dashes
      - address must be a valid IPv4 address or hostname/FQDN
      - port must be between 1 and 65535
    EOM
  }
}


###############################################################################
## PVE node configuration
###############################################################################
variable "timezone" {
  description = <<EOT
    Time zone to set on the Proxmox node. This affects system time and logging.
    Defaults to `Europe/Berlin`.
  EOT
  type        = string
  default     = "Europe/Berlin"
}

variable "dns_servers" {
  description = <<EOT
    List of DNS servers to configure on the node. These will be used for
    name resolution. Defaults to Cloudflare's IPv4 and IPv6 DNS.
  EOT
  type        = list(string)
  default     = ["1.1.1.1", "2606:4700:4700::1111"]
}

variable "dns_search_domain" {
  description = <<EOT
    DNS search domain to configure on the node. This is used to resolve
    short hostnames within a specific domain context.
  EOT
  type        = string
}

variable "local_content_types" {
  description = <<-EOT
    Desired content types to allow on the 'local' storage.
    Allowed values: iso, vztmpl, backup, snippets, images, rootdir, import
  EOT
  type        = set(string)
  default     = ["iso", "vztmpl", "snippets", "import"]

  validation {
    condition = length(
      setsubtract(
        var.local_content_types,
        toset(["iso", "vztmpl", "backup", "snippets", "images", "rootdir", "import"])
      )
    ) == 0
    error_message = "local_content_types must be a subset of: iso, vztmpl, backup, snippets, images, rootdir, import."
  }
}


###############################################################################
## PVE user management
###############################################################################
variable "users" {
  description = <<EOT
    A map of user configurations for Proxmox access management. Each key represents
    a unique username (without realm), and the value is an object defining:

    - User identity and with optional metadata (name, email, comment).
    - Role assignment (built-in or custom) and optional role creation with specific privileges.
    - ACL path and propagation behavior
    - Optional API token creation
  EOT
  type = map(object({
    ## User identity and authentication
    password   = string
    realm      = optional(string, "pve")
    enabled    = optional(bool, true)
    first_name = optional(string)
    last_name  = optional(string)
    email      = optional(string)
    comment    = optional(string, "Managed by OpenTofu")

    ## Role and permissions
    role_id         = string
    create_role     = optional(bool, false)
    role_privileges = optional(list(string), [])

    ## ACL configuration
    path      = string
    propagate = optional(bool, true)

    ## API token
    create_token          = optional(bool, false)
    token_name            = optional(string, "")
    privileges_separation = optional(bool, false)
  }))

  default = {}

  validation {
    condition = alltrue([
      for k, user in var.users : (
        ## Username validation (key)
        can(regex("^[a-z][a-z0-9_-]{0,31}$", k)) &&

        ## Password validation (non-empty)
        length(trimspace(user.password)) > 0 &&

        ## Realm validation (common Proxmox realms)
        contains(["pve", "pam", "ldap", "ad"], user.realm) &&

        ## Email validation (if provided)
        (user.email == null || can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", user.email))) &&

        ## Role ID validation (non-empty)
        length(trimspace(user.role_id)) > 0 &&

        ## Role privileges validation (if role is created)
        (!user.create_role || length(user.role_privileges) > 0) &&

        ## Path validation (must start with /)
        can(regex("^/", user.path)) &&

        ## Token name validation (if token is created)
        (!user.create_token || (user.token_name != null && length(trimspace(user.token_name)) > 0))
      )
    ])
    error_message = <<EOT
      Invalid user configuration. Each user must meet these requirements:
      - Username (map key) must be a valid Linux username (lowercase, start with letter, max 32 chars).
      - password must be non-empty.
      - realm must be one of: pve, pam, ldap, ad.
      - email must be a valid email address if specified.
      - role_id must be non-empty.
      - role_privileges must be non-empty if create_role is true.
      - path must start with '/'.
      - token_name must be non-empty if create_token is true.
    EOT
  }
}


###############################################################################
## PVE certificate management
###############################################################################
variable "acme_target_node" {
  description = <<EOT
    Name of the Proxmox node responsible for ordering the ACME certificate.
    This must be a valid key in the `pve_nodes` map, which defines the available
    nodes in the cluster. The selected node will handle DNS challenges and
    certificate installation.
  EOT
  type        = string

  validation {
    condition     = contains(keys(var.pve_nodes), var.acme_target_node)
    error_message = "`target_node` must be a key in var.pve_nodes."
  }
}

variable "acme_cert_domains" {
  description = <<EOT
    List of domain names to include in the certificate (SANs). Must contain at
    least one domain. These domains must be resolvable and manageable via the
    configured DNS plugin.
  EOT
  type        = list(string)

  validation {
    condition     = length(var.acme_cert_domains) > 0
    error_message = "acme_cert_domains must contain at least one domain."
  }
}

variable "acme_account_name" {
  description = <<EOT
    Name of the ACME account used for certificate issuance. This is a logical
    identifier within the Proxmox cluster and should be unique per environment.
    Defaults to `letsencrypt-prod`.
  EOT
  type        = string
  default     = "letsencrypt-prod"
}

variable "acme_contact_email" {
  description = <<EOT
    Email address associated with the ACME account. This is used for important
    notifications such as certificate expiry and account status.
  EOT
  type        = string
}

variable "cf_token" {
  description = <<EOT
    Cloudflare API token used for DNS management. This is required for DNS-01
    challenge validation when using Cloudflare. Sensitive value.
  EOT
  type        = string
  sensitive   = true
}

variable "cf_zone_id" {
  description = <<EOT
    Cloudflare Zone ID for the domain being validated. This identifies the DNS
    zone where challenge records will be created.
  EOT
  type        = string
  default     = null
}

variable "cf_account_id" {
  description = <<EOT
    Cloudflare Account ID. Optional and only required for certain API operations.
  EOT
  type        = string
  default     = null
}


###############################################################################
## PVE network configuration
###############################################################################
variable "bonds" {
  description = <<EOT
    A map of Linux bond interfaces for network aggregation and redundancy.
    Each key represents a unique bond identifier, and the value is an object
    containing:

    - target_node: Proxmox node where the bond should be configured (must be a key in `var.pve_nodes`).
    - mode: Bonding mode determining load balancing and failover behavior.
    - slaves: List of physical interface names to aggregate (e.g., `["eno1", "eno2"]`).
    - xmit_hash_policy: Hash algorithm for packet distribution (modes 2, 4, and 6 only).
    - miimon: Link monitoring interval in milliseconds for failure detection (optional).
    - lacp_rate: LACP negotiation rate for 802.3ad mode (optional).
    - primary: Primary interface for active-backup mode (optional).
    - mtu: Maximum transmission unit size (optional).
    - address: IPv4 address in CIDR notation (optional).
    - address6: IPv6 address in CIDR notation (optional).
    - gateway: IPv4 gateway address (optional).
    - gateway6: IPv6 gateway address (optional).
    - autostart: Whether to bring up the interface automatically (optional).
    - comment: Optional description for documentation purposes.

    Bond interfaces can be referenced in bridge configurations and used as parent
    interfaces for VLAN tagging.
  EOT
  type = map(object({
    ## Node placement
    target_node = string

    ## Bonding configuration
    mode        = string
    slaves      = list(string)
    miimon      = optional(number, 100)
    lacp_rate   = optional(string)
    hash_policy = optional(string)
    primary     = optional(string)

    ## Network configuration
    mtu      = optional(number)
    address  = optional(string)
    address6 = optional(string)
    gateway  = optional(string)
    gateway6 = optional(string)

    ## Interface options
    autostart = optional(bool, true)
    comment   = optional(string)
  }))

  default = {}

  validation {
    condition = alltrue([
      for k, bond in var.bonds : (
        ## Bond name must follow Linux bonding convention: bond0, bond1, etc.
        can(regex("^bond[0-9]+$", k)) &&

        ## Target node must exist in the pve_nodes map
        contains(keys(var.pve_nodes), bond.target_node) &&

        ## Bonding mode must be one of the supported Linux bonding modes
        contains([
          "802.3ad",       ## LACP (IEEE 802.3ad Dynamic link aggregation)
          "active-backup", ## Fault-tolerance (active-backup policy)
          "balance-xor",   ## XOR (balance-xor policy)
          "balance-tlb",   ## Adaptive transmit load balancing
          "balance-alb",   ## Adaptive load balancing
          "balance-rr",    ## Round-robin (balance-rr policy)
          "broadcast"      ## Broadcast (broadcast policy)
        ], bond.mode) &&

        ## Bond requires at least 2 slave interfaces for redundancy
        length(bond.slaves) >= 2 &&

        ## All slave interface names must be non-empty strings
        alltrue([for slave in bond.slaves : length(trimspace(slave)) > 0]) &&

        ## MII monitoring interval (50-1000ms range is standard for stability)
        (bond.miimon == null || (bond.miimon >= 50 && bond.miimon <= 1000)) &&

        ## LACP rate validation (only applicable for 802.3ad mode)
        (bond.lacp_rate == null || contains(["fast", "slow"], bond.lacp_rate)) &&

        ## Hash policy validation (for load balancing modes 2, 4, 6)
        (bond.hash_policy == null || contains([
          "layer2",   ## MAC addresses
          "layer2+3", ## MAC + IP addresses
          "layer3+4", ## IP + port numbers
          "encap2+3", ## Encapsulated MAC + IP
          "encap3+4"  ## Encapsulated IP + ports
        ], bond.hash_policy)) &&

        ## Primary interface must be one of the configured slaves
        (bond.primary == null || contains(bond.slaves, bond.primary)) &&

        ## MTU must be within valid Ethernet range (68-9000 bytes)
        (bond.mtu == null || (bond.mtu >= 68 && bond.mtu <= 9000)) &&

        ## IPv4 address must be in valid CIDR notation (if specified)
        (bond.address == null || can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", bond.address))) &&

        ## IPv6 address must be in valid CIDR notation (if specified)
        (bond.address6 == null || can(regex("^[0-9a-fA-F:]+/[0-9]{1,3}$", bond.address6))) &&

        ## IPv4 gateway must be a valid IP address (if specified)
        (bond.gateway == null || can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", bond.gateway))) &&

        ## IPv6 gateway must be a valid IPv6 address (if specified)
        (bond.gateway6 == null || can(regex("^[0-9a-fA-F:]+$", bond.gateway6)))
      )
    ])
    error_message = <<EOT
      Invalid bond configuration. Each bond must meet these requirements:

      Bond Naming:
      - Bond name (map key) must follow pattern "bond<number>" (e.g., "bond0", "bond1").

      Node Configuration:
      - target_node must be a key in `var.pve_nodes`.

      Bonding Configuration:
      - mode must be one of: 802.3ad, active-backup, balance-xor, balance-tlb, balance-alb, balance-rr, broadcast.
      - slaves must contain at least 2 non-empty interface names.
      - miimon must be between 50 and 1000 milliseconds (if specified).
      - lacp_rate must be "fast" or "slow" (if specified, only for 802.3ad mode).
      - hash_policy must be one of: layer2, layer2+3, layer3+4, encap2+3, encap3+4 (if specified).
      - primary must be one of the slave interfaces (if specified, for active-backup mode).

      Network Configuration:
      - address must be in IPv4 CIDR notation (if specified).
      - address6 must be in IPv6 CIDR notation (if specified).
      - gateway must be a valid IPv4 address (if specified).
      - gateway6 must be a valid IPv6 address (if specified).
      - mtu must be between 68 and 9000 bytes (if specified).
    EOT
  }
}

variable "vlans" {
  description = <<EOT
    A map of Linux VLAN interfaces for network segmentation and isolation.
    Each key represents a unique VLAN identifier, and the value is an object
    containing:

    - target_node: Proxmox node where the VLAN should be configured (must be a key in `var.pve_nodes`).
    - interface: Parent interface name (required if name doesn't use dot notation).
    - vlan: VLAN ID number 1-4094 (required if name doesn't use dot notation).
    - address: IPv4 address in CIDR notation for the VLAN (optional).
    - address6: IPv6 address in CIDR notation for the VLAN (optional).
    - gateway: IPv4 gateway address for routing (optional).
    - gateway6: IPv6 gateway address for routing (optional).
    - mtu: Maximum transmission unit size for the interface (optional).
    - autostart: Whether to automatically bring up the interface (optional).
    - comment: Optional description for documentation purposes.

    VLAN interfaces can use either dot notation (e.g., `eno1.10`) where the
    VLAN ID is embedded in the name, or custom names with explicit interface
    and vlan parameters. VLANs can be referenced in bridge port configurations.
  EOT
  type = map(object({
    ## Node placement
    target_node = string

    ## VLAN configuration
    interface = optional(string)
    vlan      = optional(number)

    ## Network configuration
    address  = optional(string)
    address6 = optional(string)
    gateway  = optional(string)
    gateway6 = optional(string)
    mtu      = optional(number)

    ## Interface options
    autostart = optional(bool)
    comment   = optional(string)
  }))

  default = {}

  validation {
    condition = alltrue([
      for k, vlan in var.vlans : (
        ## VLAN interface name must follow Linux naming convention
        can(regex("^[a-zA-Z][a-zA-Z0-9_.-]*$", k)) &&

        ## Target node must exist in the pve_nodes map
        contains(keys(var.pve_nodes), vlan.target_node) &&

        ## VLAN configuration must follow one of two patterns:
        ## 1. Dot notation: interface name contains VLAN ID (e.g., "eno1.10")
        ## 2. Explicit: separate interface and vlan parameters specified
        (
          can(regex("\\.[0-9]+$", k)) ||
          (vlan.interface != null && vlan.vlan != null)
        ) &&

        ## Parent interface name must be non-empty (if explicitly specified)
        (vlan.interface == null || length(trimspace(vlan.interface)) > 0) &&

        ## VLAN ID must be within IEEE 802.1Q standard range (1-4094)
        ## Note: VLAN 0 is reserved, 4095 is reserved for implementation use
        (vlan.vlan == null || (vlan.vlan >= 1 && vlan.vlan <= 4094)) &&

        ## IPv4 address must be in valid CIDR notation (if specified)
        (vlan.address == null || can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", vlan.address))) &&

        ## IPv6 address must be in valid CIDR notation (if specified)
        (vlan.address6 == null || can(regex("^[0-9a-fA-F:]+/[0-9]{1,3}$", vlan.address6))) &&

        ## IPv4 gateway must be a valid IP address (if specified)
        (vlan.gateway == null || can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", vlan.gateway))) &&

        ## IPv6 gateway must be a valid IPv6 address (if specified)
        (vlan.gateway6 == null || can(regex("^[0-9a-fA-F:]+$", vlan.gateway6))) &&

        ## MTU must be within valid Ethernet range (68-9000 bytes)
        (vlan.mtu == null || (vlan.mtu >= 68 && vlan.mtu <= 9000))
      )
    ])
    error_message = <<EOT
      Invalid VLAN definition. Each VLAN must meet these requirements:

      VLAN Naming:
      - VLAN name (map key) must start with a letter and contain only alphanumeric characters,
        underscores, dots, or dashes.
      - Supports dot notation (e.g., "eno1.10") or custom names (e.g., "vlan_mgmt").

      Node Configuration:
      - target_node must be a key in `var.pve_nodes`.

      VLAN Configuration:
      - Must use either dot notation OR explicit interface+vlan parameters.
      - Dot notation: VLAN ID embedded in name (e.g., "bond0.100").
      - Explicit: separate interface and vlan parameters must both be specified.
      - interface must be non-empty if explicitly specified.
      - vlan must be between 1 and 4094 (IEEE 802.1Q standard) if specified.

      Network Configuration:
      - address must be in IPv4 CIDR notation (if specified).
      - address6 must be in IPv6 CIDR notation (if specified).
      - gateway must be a valid IPv4 address (if specified).
      - gateway6 must be a valid IPv6 address (if specified).
      - mtu must be between 68 and 9000 bytes (if specified).
    EOT
  }
}

variable "bridges" {
  description = <<EOT
    A map of Linux bridges for connecting multiple network interfaces and VMs.
    Each key represents a unique bridge identifier, and the value is an object
    containing:

    - target_node: Proxmox node for bridge configuration (must be a key in `var.pve_nodes`).
    - ports: List of interfaces to attach to the bridge (e.g., `["eno1", "bond0", "eno1.10"]`).
    - vlan_aware: Enable VLAN awareness for trunk-style bridges (optional).
    - address: IPv4 address in CIDR notation for the bridge (optional).
    - address6: IPv6 address in CIDR notation for the bridge (optional).
    - gateway: IPv4 gateway address for routing (optional).
    - gateway6: IPv6 gateway address for routing (optional).
    - mtu: Maximum transmission unit size for the bridge (optional).
    - autostart: Whether to automatically bring up the interface (optional).
    - comment: Optional description for documentation purposes.

    Bridge ports can reference physical NICs, VLAN interfaces (e.g., `eno1.10`),
    bond interfaces (e.g., `bond0`), or other network interfaces. When `vlan_aware`
    is enabled, the bridge can handle VLAN-tagged traffic for multiple VLANs.
  EOT
  type = map(object({
    ## Node placement
    target_node = string

    ## Bridge configuration
    ports      = optional(list(string))
    vlan_aware = optional(bool)

    ## Network configuration
    address  = optional(string)
    address6 = optional(string)
    gateway  = optional(string)
    gateway6 = optional(string)
    mtu      = optional(number)

    ## Interface options
    autostart = optional(bool)
    comment   = optional(string)
  }))

  default = {}

  validation {
    condition = alltrue([
      for k, bridge in var.bridges : (
        ## Bridge name must follow Linux bridge naming convention
        ## Common patterns: vmbr0, br-lan, bridge-mgmt, etc.
        can(regex("^[a-zA-Z][a-zA-Z0-9_-]*$", k)) &&

        ## Target node must exist in the pve_nodes map
        contains(keys(var.pve_nodes), bridge.target_node) &&

        ## All port names must be valid interface identifiers (if ports specified)
        ## Ports can include: physical NICs (eno1), bonds (bond0), VLANs (eno1.10)
        (bridge.ports == null || alltrue([
          for port in bridge.ports : length(trimspace(port)) > 0
        ])) &&

        ## IPv4 address must be in valid CIDR notation (if specified)
        (bridge.address == null || can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", bridge.address))) &&

        ## IPv6 address must be in valid CIDR notation (if specified)
        (bridge.address6 == null || can(regex("^[0-9a-fA-F:]+/[0-9]{1,3}$", bridge.address6))) &&

        ## IPv4 gateway must be a valid IP address (if specified)
        (bridge.gateway == null || can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", bridge.gateway))) &&

        ## IPv6 gateway must be a valid IPv6 address (if specified)
        (bridge.gateway6 == null || can(regex("^[0-9a-fA-F:]+$", bridge.gateway6))) &&

        ## MTU must be within valid Ethernet range (68-9000 bytes)
        (bridge.mtu == null || (bridge.mtu >= 68 && bridge.mtu <= 9000))
      )
    ])
    error_message = <<EOT
      Invalid bridge configuration. Each bridge must meet these requirements:

      Bridge Naming:
      - Bridge name (map key) must start with a letter and contain only alphanumeric characters, underscores, or dashes.
      - Common patterns: vmbr0, br-lan, bridge-mgmt, etc.

      Node Configuration:
      - target_node must be a key in `var.pve_nodes`.

      Bridge Configuration:
      - All port names must be non-empty strings if ports are specified.
      - Ports can include: physical NICs (eno1), bonds (bond0), VLANs (eno1.10), other bridges.
      - Empty ports list is allowed (bridge without attached interfaces).
      - vlan_aware enables VLAN tag handling (trunk mode).

      Network Configuration:
      - address must be in IPv4 CIDR notation (if specified).
      - address6 must be in IPv6 CIDR notation (if specified).
      - gateway must be a valid IPv4 address (if specified).
      - gateway6 must be a valid IPv6 address (if specified).
      - mtu must be between 68 and 9000 bytes (if specified).
    EOT
  }
}


###############################################################################
##  Talos
###############################################################################
variable "talos_dns_servers" {
  description = <<EOT
    List of DNS servers configured on Talos nodes. These are used by Talos for
    name resolution.
  EOT
  type        = list(string)
  default     = []
}

variable "talos_ntp_servers" {
  description = <<EOT
    List of NTP servers used for time synchronization on Talos nodes.
    Default: Cloudflare Time and pool.ntp.org.
  EOT
  type        = list(string)
  default     = ["time.cloudflare.com", "pool.ntp.org"]
}

variable "talos_longhorn" {
  description = <<EOT
    Longhorn dataplane storage settings for Talos worker nodes.

    These values are used to generate Talos block storage configuration
    (UserVolumeConfig) and kubelet mount propagation for CSI/Longhorn.

    Fields:
      - disk_selector_match: CEL expression used as UserVolumeConfig.provisioning.diskSelector.match.
        Examples: !system_disk | disk.transport == "nvme" | disk.model.contains("Samsung")
      - mount_path: Must be /var/mnt/<name> for Talos user volumes.
      - filesystem: Filesystem type for the provisioned volume (ext4 or xfs).
  EOT

  type = object({
    ## Disk selection
    disk_selector_match = optional(string, "!system_disk")

    ## Volume mount (Talos user volume mount path)
    mount_path = optional(string, "/var/mnt/longhorn")

    ## Filesystem type used to format the volume
    filesystem = optional(string, "ext4")
  })

  default = {}

  validation {
    condition = alltrue([
      ## disk_selector_match must be non-empty (CEL expression)
      length(trimspace(var.talos_longhorn.disk_selector_match)) > 0,

      ## mount_path must be /var/mnt/<name>
      can(regex("^/var/mnt/[A-Za-z0-9-]{1,34}$", var.talos_longhorn.mount_path)),

      ## filesystem must be one of the supported types
      contains(["ext4", "xfs"], var.talos_longhorn.filesystem),
    ])
    error_message = <<EOT
      Invalid talos_longhorn configuration. Requirements:
      - disk_selector_match must be a non-empty CEL expression string (e.g. !system_disk)
      - mount_path must be /var/mnt/<name> where <name> is 1-34 chars of letters/digits/hyphens (e.g. /var/mnt/longhorn)
      - filesystem must be one of: ext4, xfs
    EOT
  }
}
