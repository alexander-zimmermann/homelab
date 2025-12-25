output "id" {
  description = "Container resource identifier"
  value       = proxmox_virtual_environment_container.lxc.id
}

output "ipv4" {
  description = "Container IPv4 addresses per network interface"
  value = try(
    [for iface, addr in proxmox_virtual_environment_container.lxc.ipv4 :
      addr if iface != "lo" # Exclude loopback
    ],
    []
  )
}

output "ipv6" {
  description = "Container IPv6 addresses per network interface"
  value = try(
    [for iface, addr in proxmox_virtual_environment_container.lxc.ipv6 :
      addr if iface != "lo" && !startswith(addr, "fe80:") # Exclude loopback and link-local
    ],
    []
  )
}
