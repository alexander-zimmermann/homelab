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
## Virtual machine & container images
###############################################################################
variable "images" {
  description = <<EOT
    A map of image download configurations for Proxmox nodes. Each key
    represents a unique image identifier, and the value is an object defining:

    - target_node: Where the image should be downloaded. Must be a key in var.pve_nodes
    - target_datastore: Where the image should be stored. Defaults to 'local'.
    - image source: URL, filename, checksum details, and image type (either 'iso' or 'vztmpl').

    This variable supports downloading ISO or LXC template images to specific
    nodes, verifying integrity via checksums, and customizing storage location
    and content type.
  EOT
  type = map(object({
    ## Storage configuration
    target_node      = string
    target_datastore = optional(string, "local")

    ## Image source and verification
    image_filename           = string
    image_url                = string
    image_checksum           = string
    image_checksum_algorithm = optional(string, "sha256")
    image_type               = optional(string, "iso")
  }))

  validation {
    condition = alltrue([
      for k, img in var.images : (
        can(regex("^(vm|lxc)_[a-z0-9]+_[a-z0-9_]+$", k)) &&
        contains(keys(var.pve_nodes), img.target_node) &&
        contains(["iso", "vztmpl", "import"], img.image_type)
      )
    ])
    error_message = <<EOT
      Invalid image definition. Requirements:
      - image name (map key): v(vm|lxc)_{distro}_{release}
      - target_node must exist
      - image_type allowed: iso, vztmpl, import
    EOT
  }
}


###############################################################################
##  VM cloud-init configuration
###############################################################################
variable "ci_user_configs" {
  description = <<EOT
    A map of user-data cloud-init configurations for Proxmox nodes. Each key
    represents a unique configuration identifier, and the value is an object defining:

    - target_node: Where the cloud-init snippet should be created. Must be a key in var.pve_nodes.
    - target_datastore: Where the snippet will be stored. Defaults to 'local'.
    - user account: Username, path to SSH public key, and optional password settings.

    This variable supports provisioning user accounts with SSH access, optional
    password authentication, and sudo privileges. It is used to generate cloud-init
    user-data snippets for VM initialization.
  EOT
  type = map(object({
    ## Storage configuration
    target_node      = string
    target_datastore = optional(string, "local")

    ## User account configuration
    username       = string
    ssh_public_key = string
    password       = optional(string, "")
    set_password   = optional(bool, false)
  }))

  validation {
    condition = alltrue([
      for k, cfg in var.ci_user_configs : (
        can(regex("^ci_user_[a-z0-9_]+$", k)) &&
        contains(keys(var.pve_nodes), cfg.target_node)
      )
    ])
    error_message = "ci_user_configs: key must match ci_user_<name>; target_node must exist."
  }
}

variable "ci_vendor_configs" {
  description = <<EOT
    A map of vendor-data cloud-init configurations for Proxmox nodes. Each key
    represents a unique configuration identifier, and the value is an object defining:

    - target_node: Where the cloud-init snippet should be created. Must be a key in var.pve_nodes.
    - target_datastore: Where the snippet will be stored. Defaults to 'local'.
    - packages: Optional list of packages to install.
    - runcmd: Optional list of commands to run.

    This variable supports installing additional packages (beyond qemu-guest-agent),
    updating the system, and executing custom commands during VM initialization.
    It is used to generate vendor-data snippets for system-level provisioning.
  EOT
  type = map(object({
    ## Storage configuration
    target_node      = string
    target_datastore = optional(string, "local")

    ## Package management
    packages       = optional(list(string), [])
    package_update = optional(bool, true)

    ## Custom commands
    runcmd = optional(list(string), [])
  }))

  validation {
    condition = alltrue([
      for k, cfg in var.ci_vendor_configs : (
        can(regex("^ci_vendor_[a-z0-9_]+$", k)) &&
        contains(keys(var.pve_nodes), cfg.target_node)
      )
    ])
    error_message = "ci_vendor_configs: key must match ci_vendor_<group>; target_node must exist."
  }
}

variable "ci_network_configs" {
  description = <<EOT
    A map of network-config cloud-init configurations for Proxmox nodes. Each key
    represents a unique configuration identifier, and the value is an object defining:

    - target_node: Where the cloud-init snippet should be created. Must be a key in var.pve_nodes.
    - target_datastore: Where the snippet will be stored. Defaults to 'local'.
    - network settings: DHCP and static IP configuration options, DNS settings, and interface name.

    This variable supports configuring network interfaces with DHCP or static
    IP addresses, DNS settings, and search domains. It is used to generate
    network-config snippets for VM networking setup.
  EOT
  type = map(object({
    ## Storage configuration
    target_node      = string
    target_datastore = optional(string, "local")

    ## DHCP configuration
    dhcp4     = optional(bool, true)
    dhcp6     = optional(bool, false)
    accept_ra = optional(bool, true)

    ## Static IP configuration
    ipv4_address = optional(string, "")
    ipv6_address = optional(string, "")
    ipv4_gateway = optional(string, "")
    ipv6_gateway = optional(string, "")

    ## DNS configuration
    dns_servers       = optional(list(string), ["1.1.1.1", "2606:4700:4700::1111"])
    dns_search_domain = optional(list(string), [])
  }))

  validation {
    condition = alltrue([
      for k, cfg in var.ci_network_configs : (
        can(regex("^ci_net_[a-z0-9_]+$", k)) &&
        contains(keys(var.pve_nodes), cfg.target_node)
      )
    ])
    error_message = "ci_network_configs: key must match ci_net_<group>; target_node must exist."
  }
}

variable "ci_meta_configs" {
  description = <<EOT
    A map of meta-data cloud-init configurations for Proxmox nodes. Each key
    represents a unique configuration identifier, and the value is an object defining:

    - target_node: Where the cloud-init snippet should be created. Must be a key in var.pve_nodes.
    - target_datastore: Where the snippet will be stored. Defaults to 'local'.
    - hostname: The local hostname to assign to the VM.

    This variable supports setting the system hostname via cloud-init meta-data,
    which is applied early in the VM boot process. It is used to generate meta-data
    snippets for identity and system-level configuration.
  EOT
  type = map(object({
    ## Storage configuration
    target_node      = string
    target_datastore = optional(string, "local")

    ## System identity
    hostname = string
  }))

  validation {
    condition = alltrue([
      for k, cfg in var.ci_meta_configs : (
        can(regex("^ci_meta_[a-z0-9_]+$", k)) &&
        contains(keys(var.pve_nodes), cfg.target_node)
      )
    ])
    error_message = "ci_meta_configs: key must match ci_meta_<profile>; target_node must exist."
  }
}


###############################################################################
##  Virtual machine & container templates
###############################################################################
variable "vm_templates" {
  description = <<EOT
    Map of VM template definitions for Proxmox. Each key is a unique template
    identifier and the value is an object describing how the template is created
    and configured. Templates serve as the source for cloning VMs or containers.

    Fields:
    - target_node: Proxmox node on which the template is created; must be a key
      in var.pve_nodes.
    - target_datastore: Storage for the template disk(s). Default: "local-zfs".
    - vm_id: Optional explicit numeric VMID (>0). When null, Proxmox allocates a free ID.
    - description: Human readable description. Default: "Terraform generated template".
    - tags: Optional list of tags for organizing templates in the Proxmox UI.
    - bios: Firmware type. Allowed: seabios, ovmf. Default: seabios.
    - machine_type: VM machine type/chipset. Allowed: q35 (modern PCIe), pc (legacy PCI). Default: null (Proxmox default).
    - cores: Number of virtual CPU cores to assign. Defaults to 2.
    - memory: RAM (MiB) to assign. Defaults to 4096.
    - image_id: Optional reference to key in `var.images`. If null a blank disk
      is created. When set the image is imported then (optionally) resized.
    - os_type: Guest OS type (Proxmox identifier). Allowed: other, wxp, w2k, w2k3,
      w2k8, wvista, win7, win8, win10, win11, l24, l26, solaris. Default: "other".
    - disk_size: Size (GiB) of the primary disk. Should be >= imported image size;
      not enforced by validation. Default: 20.
    - enable_cloud_init: Boolean toggle controlling whether a cloud-init initialization
      disk block may be rendered. The block is created only if this is true AND at
      least one ci_* data ID is non-null.
    - ci_*_data_id: Optional references to keys in var.ci_*_configs. Null means not used.
    - enable_tpm: Enable TPM 2.0 device (required for Windows 11). Only with UEFI (bios=ovmf). Default: false.
    - secure_boot: Enable UEFI Secure Boot (required for Windows 11). Only with UEFI (bios=ovmf). Default: false.

    Validation ensures referenced nodes, images and cloud-init snippet keys
    exist in their respective maps and that os_type & bios is one of the allowed values.
  EOT
  type = map(object({
    ## Infrastructure placement
    target_node      = string
    target_datastore = optional(string, "local-zfs")

    ## VM identification
    vm_id       = optional(number)
    description = optional(string, "Terraform generated template")
    tags        = optional(list(string), [])

    ## Hardware configuration
    bios         = optional(string, "seabios")
    machine_type = optional(string, null)
    cores        = optional(number, 2)
    memory       = optional(number, 4096)

    ## Disk and image configuration
    image_id  = optional(string, null)
    os_type   = optional(string, "other")
    disk_size = optional(number, 20)

    ## Cloud-init configuration
    enable_cloud_init  = optional(bool, true)
    ci_user_data_id    = optional(string, null)
    ci_vendor_data_id  = optional(string, null)
    ci_network_data_id = optional(string, null)
    ci_meta_data_id    = optional(string, null)

    ## Security and UEFI configuration (Windows 11 / modern OS)
    enable_tpm  = optional(bool, false)
    secure_boot = optional(bool, false)
  }))

  validation {
    condition = alltrue([
      for k, tmpl in var.vm_templates : (
        ## Template name must follow naming convention: vm_<distro>_<release>
        can(regex("^vm_[a-z0-9]+_[a-z0-9_]+$", k)) &&

        ## Target node must exist in the pve_nodes map
        contains(keys(var.pve_nodes), tmpl.target_node) &&

        ## Image ID validation: null (blank disk), key in var.images, or "talos" (special case)
        (tmpl.image_id == null || contains(keys(var.images), tmpl.image_id) || tmpl.image_id == "talos") &&

        ## VM ID must be positive integer if specified (Proxmox VMID range)
        (tmpl.vm_id == null || tmpl.vm_id > 0) &&

        ## CPU cores must be positive integer (reasonable range 1-128)
        (tmpl.cores > 0 && tmpl.cores <= 128) &&

        ## Memory must be positive integer in MiB (minimum 32MB, reasonable max 1TB)
        (tmpl.memory >= 32 && tmpl.memory <= 1048576) &&

        ## Disk size must be positive integer in GiB (minimum 1GB, reasonable max 32TB)
        (tmpl.disk_size > 0 && tmpl.disk_size <= 32768) &&

        ## Cloud-init user data reference must exist in respective map (if specified)
        (tmpl.ci_user_data_id == null || contains(keys(var.ci_user_configs), tmpl.ci_user_data_id)) &&

        ## Cloud-init vendor data reference must exist in respective map (if specified)
        (tmpl.ci_vendor_data_id == null || contains(keys(var.ci_vendor_configs), tmpl.ci_vendor_data_id)) &&

        ## Cloud-init network data reference must exist in respective map (if specified)
        (tmpl.ci_network_data_id == null || contains(keys(var.ci_network_configs), tmpl.ci_network_data_id)) &&

        ## Cloud-init meta data reference must exist in respective map (if specified)
        (tmpl.ci_meta_data_id == null || contains(keys(var.ci_meta_configs), tmpl.ci_meta_data_id)) &&

        ## OS type must be valid Proxmox guest OS identifier
        contains(["other", "wxp", "w2k", "w2k3", "w2k8", "wvista", "win7", "win8", "win10", "win11", "l24", "l26", "solaris"], tmpl.os_type) &&

        ## BIOS firmware type must be supported by Proxmox
        contains(["seabios", "ovmf"], tmpl.bios) &&

        ## Machine type must be valid Proxmox machine type (if specified)
        (tmpl.machine_type == null || contains(["q35", "pc"], tmpl.machine_type))
      )
    ])
    error_message = <<EOT
      Invalid VM template definition. Each template must meet these requirements:

      Template Naming:
      - Template name (map key) must follow pattern "vm_<distro>_<release>" (e.g., "vm_ubuntu_2404", "vm_debian_12").

      Node Configuration:
      - target_node must be a key in `var.pve_nodes`.
      - target_datastore must be a valid Proxmox storage identifier.

      VM Configuration:
      - vm_id must be a positive integer if specified (Proxmox VMID range).
      - cores must be between 1 and 128 CPU cores.
      - memory must be between 32 MiB and 1048576 MiB (1TB).
      - disk_size must be between 1 GiB and 32768 GiB (32TB).

      Image Configuration:
      - image_id must be null (blank disk), key in `var.images`, or "talos" (special case).

      OS and Firmware:
      - os_type allowed: other, wxp, w2k, w2k3, w2k8, wvista, win7, win8, win10, win11, l24, l26, solaris.
      - bios allowed: seabios (legacy BIOS), ovmf (UEFI firmware).
      - machine_type allowed: null (Proxmox default), q35 (modern PCIe chipset), pc (legacy PCI chipset).

      Cloud-Init Configuration (optional):
      - ci_user_data_id: null OR existing key in `var.ci_user_configs`.
      - ci_vendor_data_id: null OR existing key in `var.ci_vendor_configs`.
      - ci_network_data_id: null OR existing key in `var.ci_network_configs`.
      - ci_meta_data_id: null OR existing key in `var.ci_meta_configs`.
    EOT
  }
}

variable "container_templates" {
  description = <<EOT
    Map of LXC container template definitions for Proxmox. Each key is a unique
    template identifier; value defines how the container template is created.

    Fields:
    - target_node: Proxmox node where the template is created (must be a key in var.pve_nodes).
    - target_datastore: Storage for rootfs. Default: "local-zfs".
    - image_id: Key in var.images referencing an LXC template (image_type = "vztmpl").
    - lxc_id: Optional explicit numeric VMID (>0). If null, Proxmox allocates the next free ID.
    - unprivileged: Create unprivileged container (user namespaces). Default: true.
    - description: Human friendly text. Default: "Terraform generated template".
    - tags: Optional list of tags.
    - cores: Virtual CPU cores. Default: 1.
    - memory: RAM (MiB). Default: 512.
    - memory_swap: Swap (MiB). Default: 512.
    - disk_size: Root filesystem size (GiB). Default: 10.
    - os_type: Container OS classification. Allowed: alpine, archlinux, centos, debian,
      devuan, fedora, gentoo, nixos, opensuse, ubuntu, unmanaged. Default: unmanaged.
    - vnic_name / vnic_bridge / vlan_tag: Network interface name, bridge and optional VLAN tag.
    - dns_servers / dns_search_domain: Override DNS settings inside the container.

    Validation ensures target_node and image_id exist in their respective maps and
    os_type is from allowed set.
  EOT
  type = map(object({
    ## Infrastructure placement
    target_node      = string
    target_datastore = optional(string, "local-zfs")

    ## Container identification
    image_id     = string
    lxc_id       = optional(number)
    unprivileged = optional(bool, true)
    description  = optional(string, "Terraform generated template")
    tags         = optional(list(string), [])

    ## Resource allocation
    cores       = optional(number, 1)
    memory      = optional(number, 512)
    memory_swap = optional(number, 512)
    disk_size   = optional(number, 10)

    ## Operating system configuration
    os_type = optional(string, "unmanaged")

    ## Network configuration
    vnic_name         = optional(string, "eth0")
    vnic_bridge       = optional(string, "vmbr0")
    vlan_tag          = optional(number)
    dns_servers       = optional(list(string), ["1.1.1.1", "2606:4700:4700::1111"])
    dns_search_domain = optional(list(string), [])
  }))

  validation {
    condition = alltrue([
      for k, tmpl in var.container_templates : (
        ## Template name must follow naming convention: lxc_<distro>_<release>
        can(regex("^lxc_[a-z0-9]+_[a-z0-9_]+$", k)) &&

        ## Target node must exist in the pve_nodes map
        contains(keys(var.pve_nodes), tmpl.target_node) &&

        ## Image ID must reference an existing LXC template in var.images
        contains(keys(var.images), tmpl.image_id) &&

        ## LXC ID must be positive integer if specified (Proxmox VMID range)
        (tmpl.lxc_id == null || tmpl.lxc_id > 0) &&

        ## CPU cores must be positive integer (reasonable range 1-64 for containers)
        (tmpl.cores > 0 && tmpl.cores <= 64) &&

        ## Memory must be positive integer in MiB (minimum 16MB, reasonable max 512GB)
        (tmpl.memory >= 16 && tmpl.memory <= 524288) &&

        ## Memory swap must be non-negative integer in MiB (0 = no swap, reasonable max 512GB)
        (tmpl.memory_swap >= 0 && tmpl.memory_swap <= 524288) &&

        ## Disk size must be positive integer in GiB (minimum 1GB, reasonable max 16TB)
        (tmpl.disk_size > 0 && tmpl.disk_size <= 16384) &&

        ## VLAN tag must be within IEEE 802.1Q standard range (1-4094) if specified
        (tmpl.vlan_tag == null || (tmpl.vlan_tag >= 1 && tmpl.vlan_tag <= 4094)) &&

        ## OS type must be valid LXC container distribution identifier
        contains(["alpine", "archlinux", "centos", "debian", "devuan", "fedora", "gentoo", "nixos", "opensuse", "ubuntu", "unmanaged"], tmpl.os_type)
      )
    ])
    error_message = <<EOT
      Invalid LXC container template definition. Each template must meet these requirements:

      Template Naming:
      - Template name (map key) must follow pattern "lxc_<distro>_<release>" (e.g., "lxc_ubuntu_2404", "lxc_alpine_319").

      Node Configuration:
      - target_node must be a key in `var.pve_nodes`.
      - target_datastore must be a valid Proxmox storage identifier.

      Container Configuration:
      - lxc_id must be a positive integer if specified (Proxmox VMID range).
      - cores must be between 1 and 64 CPU cores (containers typically need fewer cores than VMs).
      - memory must be between 16 MiB and 524288 MiB (512GB).
      - memory_swap must be between 0 MiB and 524288 MiB (0 = no swap, 512GB max).
      - disk_size must be between 1 GiB and 16384 GiB (16TB).

      Image Configuration:
      - image_id must be an existing key in `var.images` referencing an LXC template (image_type = "vztmpl").

      OS Distribution Types:
      - os_type allowed: alpine (musl-based), archlinux (rolling), centos (RHEL-based), debian (stable),
        devuan (systemd-free), fedora (bleeding-edge), gentoo (source-based), nixos (declarative),
        opensuse (SUSE-based), ubuntu (Canonical), unmanaged (generic).

      Network Configuration (optional):
      - vlan_tag must be between 1 and 4094 (IEEE 802.1Q standard) if specified.
      - vnic_name, vnic_bridge must be valid interface identifiers.
      - dns_servers must be valid IP addresses, dns_search_domain must be valid domain names.
    EOT
  }
}


###############################################################################
##  Virtual machine & container clones
###############################################################################
variable "virtual_machines" {
  description = <<EOT
    Hybrid map of VM creation specifications keyed by a logical identifier.
    Supports two object shapes (single vs batch). The map key is always the human
    readable logical group name (for batch) or the instance name (for single).

    Single instance object (count omitted or == 0). Fields:
      - template_id (required): Key in `var.vm_templates`.
      - target_node (required): Key in `var.pve_nodes`.
      - vm_id (optional): Explicit VMID (>0). When null, provider allocates.

    Batch instance object (count > 0): Expands into multiple instances whose
    generated keys follow: <map key> + "-" + index (1..count). Fields:
      - template_id (required): Key in `var.vm_templates`.
      - target_node (required): Key in `var.pve_nodes`.
      - count (required >0): Number of instances to create.
      - vm_id_start (required >0): First VMID; subsequent = vm_id_start + index - 1

    Mutually exclusive sets: Single objects MUST NOT define count/vm_id_start.
    Batch objects MUST define count & vm_id_start and MUST NOT define vm_id.

    Validation ensures structural correctness and reference integrity. Additional
    collision detection of VMIDs can be added in locals.
  EOT
  type = map(object({
    ## VM template and placement
    template_id = string
    target_node = string

    ## Single VM deployment
    vm_id          = optional(number)
    wait_for_agent = optional(bool, true)

    ## Batch VM deployment
    count       = optional(number, 0)
    vm_id_start = optional(number)
  }))

  validation {
    condition = alltrue([
      for k, spec in var.virtual_machines : (
        ## VM naming validation based on deployment type:
        ## - Batch deployments: <group>_<distro> pattern (e.g., "web_apache", "db_mysql")
        ## - Single deployments: <hostname> pattern (e.g., "debian_01", "ubuntu_01", "windows_01")
        ##   Names use lowercase alphanumeric and underscores, representing the actual hostname
        (
          (try(spec.count, 0) > 0 && can(regex("^[a-z0-9]+_[a-z0-9]+$", k))) ||
          (try(spec.count, 0) == 0 && can(regex("^[a-z0-9_]+$", k)))
        ) &&

        ## Template ID must reference an existing VM template definition
        contains(keys(var.vm_templates), spec.template_id) &&

        ## Target node must exist in the pve_nodes map
        contains(keys(var.pve_nodes), spec.target_node) &&

        ## Deployment type validation: single vs batch configuration consistency
        ## Single deployment: count=0, no vm_id_start, optional explicit vm_id
        ## Batch deployment: count>0, vm_id_start>0, no explicit vm_id
        (
          (try(spec.count, 0) == 0 && spec.vm_id_start == null) ||
          (try(spec.count, 0) > 0 && spec.vm_id_start != null && spec.vm_id_start > 0 && spec.vm_id == null)
        ) &&

        ## VM ID must be positive integer if specified (Proxmox VMID range)
        (spec.vm_id == null || spec.vm_id > 0) &&

        ## Count must be non-negative (0 = single deployment, >0 = batch deployment)
        (try(spec.count, 0) >= 0) &&

        ## VM ID start must be positive integer for batch deployments
        (spec.vm_id_start == null || spec.vm_id_start > 0) &&

        ## Count validation: if specified, must be reasonable (1-50 VMs per batch)
        (try(spec.count, 0) == 0 || (spec.count >= 1 && spec.count <= 50))
      )
    ])
    error_message = <<EOT
      Invalid virtual machine deployment specification. Each VM entry must meet these requirements:

      VM Naming:
      - Single deployment: "<hostname>" (e.g., "debian_01", "ubuntu_01", "windows_01").
      - Batch deployment: "<group>_<distro>" (e.g., "web_apache", "db_mysql", "worker_ubuntu").
      - Names must use lowercase alphanumeric characters and underscores only.
      - Single deployment names are used as the actual VM hostname.

      Template Configuration:
      - template_id must be an existing key in `var.vm_templates`.
      - Template defines the base VM image, resources, cloud-init, and OS configuration.

      Node Configuration:
      - target_node must be an existing key in `var.pve_nodes`.
      - Specifies which Proxmox node will host the VM(s).

      Single VM Deployment (count = 0 or omitted):
      - Must NOT specify count or vm_id_start parameters.
      - May specify explicit vm_id (positive integer) or let Proxmox auto-assign.
      - Creates exactly one VM instance.

      Batch VM Deployment (count > 0):
      - Must specify both count (1-50) and vm_id_start (positive integer).
      - Must NOT specify explicit vm_id parameter.
      - Creates multiple VMs with sequential VMIDs: vm_id_start, vm_id_start+1, etc.
      - Generated VM names follow pattern: "<map_key>-<index>" where index = 1..count.

      Resource Limits:
      - count must be between 1 and 50 VMs per batch deployment (reasonable cluster limit).
      - vm_id and vm_id_start must be positive integers (Proxmox VMID range: 1-999999999).
    EOT
  }
}

variable "containers" {
  description = <<EOT
    Hybrid map of container creation specifications keyed by a logical identifier.
    Supports two object shapes (single vs batch). The map key is always the human
    readable logical group name (for batch) or the instance name (for single).

    Single instance object (count omitted or == 0). Fields:
      - template_id (required): Key in `var.container_templates`.
      - target_node (required): Key in `var.pve_nodes`.
      - target_datastore (optional): Storage for rootfs. Default: "local-zfs".
      - lxc_id (optional): Explicit LXC ID (>0). When null, provider allocates.

    Batch instance object (count > 0): Expands into multiple instances whose
    generated keys follow: <map key> + "-" + index (1..count). Fields:
      - template_id (required): Key in `var.container_templates`.
      - target_node (required): Key in `var.pve_nodes`.
      - target_datastore (optional): Storage for rootfs. Default: "local-zfs".
      - count (required >0): Number of instances to create.
      - lxc_id_start (required >0): First LXC ID; subsequent = lxc_id_start + index - 1

    Mutually exclusive sets: Single objects MUST NOT define count/lxc_id_start.
    Batch objects MUST define count & lxc_id_start and MUST NOT define lxc_id.

    Validation ensures structural correctness and reference integrity. Additional
    collision detection of LXC IDs can be added in locals.
  EOT
  type = map(object({
    ## Container template and placement
    template_id      = string
    target_node      = string
    target_datastore = optional(string, "local-zfs")

    ## Single container deployment
    lxc_id = optional(number)

    ## Batch container deployment
    count        = optional(number, 0)
    lxc_id_start = optional(number)
  }))

  validation {
    condition = alltrue([
      for k, spec in var.containers : (
        ## Container naming validation based on deployment type:
        ## - Batch deployments: <group>_<distro> pattern (e.g., "web_nginx", "db_postgres")
        ## - Single deployments: <hostname> pattern (e.g., "ubuntu_ct_01", "nginx_01")
        ##   Names use lowercase alphanumeric and underscores, representing the actual hostname
        (
          (try(spec.count, 0) > 0 && can(regex("^[a-z0-9]+_[a-z0-9_]+$", k))) ||
          (try(spec.count, 0) == 0 && can(regex("^[a-z0-9_]+$", k)))
        ) &&

        ## Template ID must reference an existing container template definition
        contains(keys(var.container_templates), spec.template_id) &&

        ## Target node validation: must exist in pve_nodes map (or be null for inheritance)
        (try(spec.target_node, null) == null || contains(keys(var.pve_nodes), spec.target_node)) &&

        ## Deployment type validation: single vs batch configuration consistency
        ## Single deployment: count=0, no lxc_id_start, optional explicit lxc_id
        ## Batch deployment: count>0, lxc_id_start>0, no explicit lxc_id
        (
          (try(spec.count, 0) == 0 && spec.lxc_id_start == null) ||
          (try(spec.count, 0) > 0 && spec.lxc_id_start != null && spec.lxc_id_start > 0 && spec.lxc_id == null)
        ) &&

        ## LXC ID must be positive integer if specified (Proxmox VMID range)
        (spec.lxc_id == null || spec.lxc_id > 0) &&

        ## Count must be non-negative (0 = single deployment, >0 = batch deployment)
        (try(spec.count, 0) >= 0) &&

        ## LXC ID start must be positive integer for batch deployments
        (spec.lxc_id_start == null || spec.lxc_id_start > 0) &&

        ## Count validation: if specified, must be reasonable (1-100 containers per batch)
        (try(spec.count, 0) == 0 || (spec.count >= 1 && spec.count <= 100))
      )
    ])
    error_message = <<EOT
      Invalid container deployment specification. Each container entry must meet these requirements:

      Container Naming:
      - Single deployment: "<hostname>" (e.g., "ubuntu_ct_01", "nginx_01").
      - Batch deployment: "<group>_<distro>" (e.g., "web_nginx", "db_postgres").
      - Names must use lowercase alphanumeric characters and underscores only.
      - Single deployment names are used as the actual container hostname.

      Template Configuration:
      - template_id must be an existing key in `var.container_templates`.
      - Template defines the base container image, resources, and OS configuration.

      Node Configuration:
      - target_node must be an existing key in `var.pve_nodes` (optional, can inherit from template).
      - If null, container will use the target_node specified in the referenced template.

      Single Container Deployment (count = 0 or omitted):
      - Must NOT specify count or lxc_id_start parameters.
      - May specify explicit lxc_id (positive integer) or let Proxmox auto-assign.
      - Creates exactly one container instance.

      Batch Container Deployment (count > 0):
      - Must specify both count (1-100) and lxc_id_start (positive integer).
      - Must NOT specify explicit lxc_id parameter.
      - Creates multiple containers with sequential LXC IDs: lxc_id_start, lxc_id_start+1, etc.
      - Generated container names follow pattern: "<map_key>-<index>" where index = 1..count.

      Resource Limits:
      - count must be between 1 and 100 containers per batch deployment.
      - lxc_id and lxc_id_start must be positive integers (Proxmox VMID range).
    EOT
  }
}


###############################################################################
## Talos configuration
###############################################################################
variable "talos_cluster_name" {
  type    = string
  default = "talos-cluster"
}

variable "talos_version" {
  description = <<EOT
    Talos version string (without a leading 'v') used across all Talos artifacts
    (images, machine config generation, provider). Example: "1.9.6".
    Pin a stable, exact version to guarantee reproducible cluster builds. Updates
    typically require a rolling upgrade of control plane and worker nodes.
    Release notes: https://github.com/siderolabs/talos/releases
  EOT
  type        = string
}

variable "kubernetes_version" {
  description = <<EOT
    Target Kubernetes version (Major.Minor.Patch) provisioned and managed by Talos.
    Example: "1.30.0". Change only after verifying Talos compatibility matrices.
    Upgrades are orchestrated via Talos; ensure system extensions and the CCM
    are compatible before bumping this value.
  EOT
  type        = string
}
