output "id" {
  description = "Instance VM ID"
  value       = proxmox_virtual_environment_vm.vm.id
}

output "ipv4" {
  description = "Instance Public IPv4 Address"
  value = try(
    ## Filter for real network IPs: exclude loopback, link-local, and Kubernetes CNI
    flatten([
      for addr_list in proxmox_virtual_environment_vm.vm.ipv4_addresses : [
        for addr in addr_list : addr
        if !startswith(addr, "127.") &&  ## No loopback (127.x.x.x)
        !startswith(addr, "169.254.") && ## No link-local (169.254.x.x)
        !startswith(addr, "10.244.")     ## No Kubernetes CNI (10.244.x.x)
      ]
    ]),
    []
  )
}

output "ipv6" {
  description = "Instance Public IPv6 Address"
  value = try(
    ## Filter for real network IPs: exclude loopback and link-local
    flatten([
      for addr_list in proxmox_virtual_environment_vm.vm.ipv6_addresses : [
        for addr in addr_list : addr
        if addr != "::1" &&        ## No loopback (::1)
        !startswith(addr, "fe80:") ## No link-local (fe80::/10)
      ]
    ]),
    []
  )
}
