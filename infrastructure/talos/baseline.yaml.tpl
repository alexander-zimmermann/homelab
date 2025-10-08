# https://www.talos.dev/latest/reference/configuration/v1alpha1/config/
---
version: v1alpha1
debug: false # verbose TTY logging

machine:
  kernel:
    modules:
      - name: zfs
