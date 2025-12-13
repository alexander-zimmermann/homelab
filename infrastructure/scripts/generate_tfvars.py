#!/usr/bin/env python3
"""
Terraform Variables Generator

This script generates Terraform/OpenTofu variables file (generated.auto.tfvars)
from YAML manifest and checksums using Jinja2 templates.

Usage:
  python generate_tfvars.py --manifest infrastructure-manifest.yaml
  python generate_tfvars.py --output custom.auto.tfvars --verbose
"""

from __future__ import annotations

import argparse
import logging
import sys
import yaml

from pathlib import Path
from typing import Any, Generator
from dataclasses import dataclass
from contextlib import contextmanager

from jinja2 import Environment, FileSystemLoader, select_autoescape, TemplateError

from logging_formatter import setup_logging_from_config


# Exit codes
EXIT_SUCCESS = 0
EXIT_GENERATION_ERROR = 1
EXIT_MANIFEST_ERROR = 2
EXIT_TEMPLATE_ERROR = 3
EXIT_UNEXPECTED_ERROR = 99

# Default paths
DEFAULT_MANIFEST_PATH = Path("./infrastructure-manifest.yaml")
DEFAULT_CHECKSUMS_PATH = Path("./build/checksums.yaml")
DEFAULT_TEMPLATE_PATH = Path("./templates/generated.auto.tfvars.j2")
DEFAULT_OUTPUT_PATH = Path("./generated.auto.tfvars")

# Extension to type mapping (Proxmox VE supported file types)
EXT_TO_TYPE = {
    "iso": "iso",
    "img": "import",
    "qcow2": "import",
    "raw": "import",
    "raw.xz": "import",
    "vmdk": "import",
    "tar.xz": "vztmpl",
    "tar.gz": "vztmpl",
    "tar.zst": "vztmpl"
}

# Debian version mapping
DEBIAN_VERSIONS = {
    "bookworm": "12",
    "trixie": "13"
}

# URL templates
DEBIAN_URL_TEMPLATE = "https://cloud.debian.org/images/cloud/{release}/latest/debian-{release_num}-genericcloud-{arch}.qcow2"
UBUNTU_QCOW2_URL_TEMPLATE = "https://cloud-images.ubuntu.com/{release}/current/{release}-server-cloudimg-{arch}.img"
UBUNTU_VZTMPL_URL_TEMPLATE = "https://images.linuxcontainers.org/images/ubuntu/noble/{arch}/cloud/{build_date}/rootfs.tar.xz"
TALOS_URL_TEMPLATE = "https://factory.talos.dev/image/{schematic}/v{version}/nocloud-amd64.{extension}"
VIRTIO_STABLE_URL = "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso"


# Custom exceptions
class GenerationError(Exception):
    """Exception for generation errors."""
    pass


class ManifestError(Exception):
    """Exception for manifest parsing errors."""
    pass


class TemplateLoadError(Exception):
    """Exception for template loading errors."""
    pass


class TemplateRenderError(Exception):
    """Exception for template rendering errors."""
    pass


@contextmanager
def handle_manifest_errors(message: str) -> Generator[None, None, None]:
    """Context manager that converts YAML file/parsing errors to ManifestError.

    Args:
        message: Error message prefix

    Yields:
        None

    Raises:
        ManifestError: If any manifest-related error occurs
    """
    try:
        yield
    except (FileNotFoundError, PermissionError, yaml.YAMLError) as e:
        raise ManifestError(f"{message}: {e}") from e


@contextmanager
def handle_template_errors(message: str, error_class: type[Exception] = TemplateError) -> Generator[None, None, None]:
    """Context manager that handles template-related errors.

    Args:
        message: Error message prefix
        error_class: Exception class to raise

    Yields:
        None

    Raises:
        TemplateLoadError or TemplateRenderError: Based on error_class parameter
    """
    try:
        yield
    except TemplateError as e:
        raise error_class(f"{message}: {e}") from e
    except (FileNotFoundError, PermissionError) as e:
        raise error_class(f"{message}: {e}") from e


@contextmanager
def handle_generation_errors(message: str) -> Generator[None, None, None]:
    """Context manager that converts generation errors to GenerationError.

    Args:
        message: Error message prefix

    Yields:
        None

    Raises:
        GenerationError: If any generation-related error occurs
    """
    try:
        yield
    except (FileNotFoundError, PermissionError, OSError) as e:
        raise GenerationError(f"{message}: {e}") from e


@contextmanager
def handle_application_errors() -> Generator[None, None, None]:
    """Context manager for application-level error handling.

    Yields:
        None

    Side Effects:
        Exits the program with appropriate exit code on error
    """
    logger = logging.getLogger('generate_tfvars')
    try:
        yield
    except ManifestError as e:
        logger.error(str(e))
        sys.exit(EXIT_MANIFEST_ERROR)
    except (TemplateLoadError, TemplateRenderError) as e:
        logger.error(str(e))
        sys.exit(EXIT_TEMPLATE_ERROR)
    except GenerationError as e:
        logger.error(str(e))
        sys.exit(EXIT_GENERATION_ERROR)
    except Exception as e:
        logger.exception(f"Unexpected error: {e}")
        sys.exit(EXIT_UNEXPECTED_ERROR)


@dataclass
class GenerationContext:
    """Context for template generation."""
    manifest: dict[str, Any]
    checksums: dict[str, Any]
    manifest_path: Path
    checksums_path: Path
    template_path: Path
    output_path: Path


class VMTemplateGenerator:
    """Handles VM template data preparation."""

    logger = logging.getLogger(__name__)

    @classmethod
    def prepare_vm_templates(cls, manifest: dict[str, Any]) -> dict[str, Any]:
        """Prepare all VM templates with resolved policies and profiles.

        Args:
            manifest: Full manifest dictionary

        Returns:
            Dictionary of prepared VM templates with all fields resolved
        """
        prepared = {}

        for key, item in manifest.get('vm_templates', {}).items():
            # Resolve policy and profile
            policy = manifest.get('resource_policies', {}).get(item.get('resource_policy', ''), {})
            raw_profile = manifest.get('vm_cloud_init_profiles', {}).get(item.get('cloud_init_profile', ''), {})

            # Filter profile to only non-null cloud-init fields
            profile = {
                ci_field: raw_profile[ci_field]
                for ci_field in ['ci_user_data_id', 'ci_vendor_data_id', 'ci_network_data_id', 'ci_meta_data_id']
                if ci_field in raw_profile and raw_profile[ci_field]
            }

            # Start with copy of all template fields
            result = dict(item)

            # Add all policy fields (resource_policy reference not needed in output)
            result.update(policy)
            if 'resource_policy' in result:
                del result['resource_policy']

            # Add cloud-init profile fields (profile reference not needed)
            result.update(profile)
            if 'cloud_init_profile' in result:
                del result['cloud_init_profile']

            # Apply defaults if not already set
            result.setdefault('target_node', manifest.get('pve_default_target_node', 'pve'))
            result.setdefault('target_datastore', manifest.get('pve_block_storage', 'local-lvm'))
            result.setdefault('description', f'{key} template')
            result.setdefault('tags', ['opentofu', 'template', 'vm'])
            result.setdefault('os_type', 'l26')

            # Derived field: machine_type from bios (only if bios is OVMF and not already set)
            if result.get('bios') == 'ovmf' and 'machine_type' not in result:
                result['machine_type'] = 'q35'

            prepared[key] = result

        return prepared


class ContainerTemplateGenerator:
    """Handles container template data preparation."""

    logger = logging.getLogger(__name__)

    @classmethod
    def prepare_container_templates(cls, manifest: dict[str, Any]) -> dict[str, Any]:
        """Prepare all container templates.

        Args:
            manifest: Full manifest dictionary

        Returns:
            Dictionary of prepared container templates
        """
        prepared = {}

        for key, item in manifest.get('container_templates', {}).items():
            result = dict(item)
            result.setdefault('target_node', manifest.get('pve_default_target_node', 'pve'))
            result.setdefault('target_datastore', manifest.get('pve_block_storage', 'local-lvm'))
            result.setdefault('description', f'{key} container template')
            result.setdefault('tags', ['opentofu', 'template', 'lxc'])
            result.setdefault('os_type', 'linux')
            prepared[key] = result

        return prepared


class VirtualMachineGenerator:
    """Handles virtual machine data preparation."""

    logger = logging.getLogger(__name__)

    @staticmethod
    def _prepare_disks(disks_spec: list, manifest: dict[str, Any]) -> list:
        """Prepare disks configuration - extract fields and apply global datastore.

        Args:
            disks_spec: List of disk specifications from manifest
            manifest: Full manifest dictionary for global pve_block_storage

        Returns:
            List of prepared disk configurations
        """
        disks = []

        for disk in disks_spec:
            result = dict(disk)
            result.setdefault('disk_datastore', manifest.get('pve_block_storage', 'local-lvm'))

            disks.append(result)

        return disks

    @classmethod
    def prepare_virtual_machines(cls, manifest: dict[str, Any]) -> dict[str, Any]:
        """Prepare all virtual machines (singles and batches).

        Args:
            manifest: Full manifest dictionary

        Returns:
            Dictionary of prepared virtual machines
        """
        prepared = {}

        # Process singles
        for key, item in manifest.get('virtual_machines', {}).get('singles', {}).items():
            result = dict(item)
            result['is_batch'] = False
            result.setdefault('target_node', manifest.get('pve_default_target_node', 'pve'))
            result['disks'] = cls._prepare_disks(result['disks'], manifest) if 'disks' in result else []
            prepared[key] = result

        # Process batches
        for key, item in manifest.get('virtual_machines', {}).get('batches', {}).items():
            result = dict(item)
            result['is_batch'] = True
            result.setdefault('target_node', manifest.get('pve_default_target_node', 'pve'))
            result['disks'] = cls._prepare_disks(result['disks'], manifest) if 'disks' in result else []
            prepared[key] = result

        return prepared


class ContainerGenerator:
    """Handles container data preparation."""

    logger = logging.getLogger(__name__)

    @classmethod
    def prepare_containers(cls, manifest: dict[str, Any]) -> dict[str, Any]:
        """Prepare all containers (singles and batches).

        Args:
            manifest: Full manifest dictionary

        Returns:
            Dictionary of prepared containers
        """
        prepared = {}

        # Process singles
        for key, item in manifest.get('containers', {}).get('singles', {}).items():
            result = dict(item)
            result['is_batch'] = False
            result.setdefault('target_node', manifest.get('pve_default_target_node', 'pve'))
            result.setdefault('target_datastore', manifest.get('pve_block_storage', 'local-lvm'))
            prepared[key] = result

        # Process batches
        for key, item in manifest.get('containers', {}).get('batches', {}).items():
            result = dict(item)
            result['is_batch'] = True
            result.setdefault('target_node', manifest.get('pve_default_target_node', 'pve'))
            result.setdefault('target_datastore', manifest.get('pve_block_storage', 'local-lvm'))
            prepared[key] = result

        return prepared


class CloudInitGenerator:
    """Handles Cloud-Init configuration data preparation."""

    logger = logging.getLogger(__name__)

    @staticmethod
    def _prepare_configs(manifest: dict[str, Any], config_key: str) -> dict[str, Any]:
        """Prepare Cloud-Init configs with defaults.

        Args:
            manifest: Full manifest dictionary
            config_key: Manifest key for config section (e.g., 'ci_user_configs')

        Returns:
            Dictionary of prepared configs
        """
        prepared = {}

        for key, item in manifest.get(config_key, {}).items():
            result = dict(item)
            result.setdefault('target_node', manifest.get('pve_default_target_node', 'pve'))
            result.setdefault('target_datastore', manifest.get('pve_file_storage', 'local'))
            prepared[key] = result

        return prepared

    @classmethod
    def prepare_user_configs(cls, manifest: dict[str, Any]) -> dict[str, Any]:
        """Prepare Cloud-Init user configs."""
        return cls._prepare_configs(manifest, 'ci_user_configs')

    @classmethod
    def prepare_vendor_configs(cls, manifest: dict[str, Any]) -> dict[str, Any]:
        """Prepare Cloud-Init vendor configs."""
        return cls._prepare_configs(manifest, 'ci_vendor_configs')

    @classmethod
    def prepare_network_configs(cls, manifest: dict[str, Any]) -> dict[str, Any]:
        """Prepare Cloud-Init network configs."""
        return cls._prepare_configs(manifest, 'ci_network_configs')

    @classmethod
    def prepare_meta_configs(cls, manifest: dict[str, Any]) -> dict[str, Any]:
        """Prepare Cloud-Init meta configs."""
        return cls._prepare_configs(manifest, 'ci_meta_configs')


class TalosGenerator:
    """Handles Talos cluster configuration."""

    logger = logging.getLogger(__name__)

    @classmethod
    def prepare_talos_config(cls, manifest: dict[str, Any]) -> dict[str, Any]:
        """Prepare Talos cluster configuration.

        Args:
            manifest: Full manifest dictionary

        Returns:
            Dictionary with Talos configuration fields
        """
        talos_config = manifest.get('talos_configuration', {})

        # Start with copy of all config fields
        result = dict(talos_config)

        # Resolve talos_version: Try explicit version, fallback to derive from images
        if 'talos_version' not in result or not result['talos_version']:
            for key, item in manifest.get('images', {}).items():
                if item.get('distro') == 'talos':
                    result['talos_version'] = cls._resolve_version(item.get('release', ''), manifest)
                    break

        # Apply defaults if not already set
        result.setdefault('cluster_name', '')
        result.setdefault('talos_version', '')
        result.setdefault('kubernetes_version', '')

        return result

    @staticmethod
    def _resolve_version(release_raw: Any, manifest: dict[str, Any]) -> str:
        """Resolve version from manifest.versions if needed.

        Args:
            release_raw: Raw release value
            manifest: Full manifest dictionary

        Returns:
            Resolved version string
        """
        if isinstance(release_raw, str) and release_raw.startswith("versions."):
            version_key = release_raw.replace("versions.", "")
            return manifest.get("versions", {}).get(version_key, release_raw)
        return str(release_raw)


class ImageGenerator:
    """Handles image URL and filename generation."""

    logger = logging.getLogger(__name__)

    @classmethod
    def prepare_images(cls, manifest: dict[str, Any], checksums: dict[str, Any]) -> dict[str, Any]:
        """Prepare all images with URLs, filenames, and checksums.

        Args:
            manifest: Full manifest dictionary
            checksums: Checksums dictionary

        Returns:
            Dictionary of prepared images with all fields
        """
        prepared = {}
        checksums_data = checksums.get('checksums', {})

        for key, item in manifest.get('images', {}).items():
            checksum_entry = checksums_data.get(key, {})

            # Windows 11 manual ISO has no URL or checksum
            if key == 'vm_windows_11_24h2':
                image_checksum = ''
                algorithm = 'sha256'
            else:
                image_checksum = checksum_entry.get('checksum', '')
                algorithm = checksum_entry.get('algorithm', 'sha256')

            prepared[key] = {
                'target_node': item.get('target_node', manifest.get('pve_default_target_node', 'pve')),
                'target_datastore': item.get('target_datastore', manifest.get('pve_file_storage', 'local')),
                'image_type': cls.get_image_type(item.get('extension', '')),
                'image_filename': cls.generate_image_filename(key, item, manifest),
                'image_url': cls.generate_image_url(key, item, manifest),
                'image_checksum': image_checksum,
                'image_checksum_algorithm': algorithm
            }

        return prepared

    @staticmethod
    def get_image_type(extension: str) -> str:
        """Map file extension to Proxmox image type.

        Args:
            extension: File extension (e.g., 'iso', 'qcow2')

        Returns:
            Proxmox image type ('iso', 'import', or 'vztmpl')
        """
        return EXT_TO_TYPE.get(extension.lower(), "unknown")

    @staticmethod
    def get_debian_version_number(codename: str) -> str:
        """Map Debian codename to version number.

        Args:
            codename: Debian release codename (e.g., 'bookworm')

        Returns:
            Version number (e.g., '12')
        """
        return DEBIAN_VERSIONS.get(codename, codename)

    @staticmethod
    def _resolve_version(release_raw: Any, manifest: dict[str, Any]) -> str:
        """Resolve version from manifest.versions if needed.

        Args:
            release_raw: Raw release value (may be string or versions reference)
            manifest: Full manifest dictionary

        Returns:
            Resolved version string
        """
        if isinstance(release_raw, str) and release_raw.startswith("versions."):
            version_key = release_raw.replace("versions.", "")
            return manifest.get("versions", {}).get(version_key, release_raw)
        return str(release_raw)

    @classmethod
    def generate_image_url(cls, key: str, spec: dict[str, Any], manifest: dict[str, Any]) -> str:
        """Generate download URL for an image based on its specification.

        Args:
            key: Image key (e.g., 'vm_debian_bookworm')
            spec: Image specification from manifest
            manifest: Full manifest dictionary

        Returns:
            Download URL for the image (empty string if manually provided)
        """
        distro = spec.get("distro")
        extension = spec.get("extension", "").lower()
        arch = spec.get("arch", "amd64")
        version = cls._resolve_version(spec.get("release", ""), manifest)

        # Debian cloud images
        if distro == "debian":
            debian_version = cls.get_debian_version_number(version)
            return DEBIAN_URL_TEMPLATE.format(
                release=version,
                release_num=debian_version,
                arch=arch
            )

        # Ubuntu cloud images (QCOW2)
        elif distro == "ubuntu" and extension == "qcow2":
            return UBUNTU_QCOW2_URL_TEMPLATE.format(
                release=version,
                arch=arch
            )

        # Ubuntu LXC templates
        elif distro == "ubuntu" and cls.get_image_type(extension) == "vztmpl":
            build_date = spec.get("build_date", "")
            return UBUNTU_VZTMPL_URL_TEMPLATE.format(
                arch=arch,
                build_date=build_date
            )

        # Talos Linux
        elif distro == "talos":
            schematic = spec.get("schematic", "")
            return TALOS_URL_TEMPLATE.format(
                schematic=schematic,
                version=version,
                extension=extension
            )

        # Windows ISOs
        elif distro == "windows":
            # Windows 11 ISO is manually provided
            if "windows_11" in key:
                return ""
            # VirtIO drivers ISO - use stable-virtio URL
            elif "virtio" in key:
                return VIRTIO_STABLE_URL

        return ""

    @classmethod
    def generate_image_filename(cls, key: str, spec: dict[str, Any], manifest: dict[str, Any]) -> str:
        """Generate appropriate filename for an image.

        Args:
            key: Image key (e.g., 'vm_debian_bookworm')
            spec: Image specification from manifest
            manifest: Full manifest dictionary

        Returns:
            Generated filename
        """
        distro = spec.get("distro")
        extension = spec.get("extension", "").lower()
        arch = spec.get("arch", "amd64")
        image_type = cls.get_image_type(extension)
        version = cls._resolve_version(spec.get("release", ""), manifest)

        # ISO images
        if image_type == "iso":
            if distro == "talos":
                return f"talos-{version}-nocloud-{arch}.iso"
            elif distro == "windows":
                if key == "vm_windows_11_24h2":
                    return "Win11_24H2_German_x64.iso"
                else:
                    return f"windows-{version}-{arch}.iso"
            else:
                return f"{distro}-{version}-{arch}.{extension}"

        # Import images (QCOW2, RAW, etc.)
        elif image_type == "import":
            if distro == "talos":
                return f"talos-{version}-nocloud-{arch}.{extension}"
            elif distro == "ubuntu" and extension == "qcow2":
                return f"ubuntu-{version}-server-cloudimg-{arch}.{extension}"
            elif distro == "debian":
                debian_version = cls.get_debian_version_number(version)
                return f"debian-{debian_version}-genericcloud-{arch}.{extension}"
            else:
                return f"{distro}-{version}-{arch}.{extension}"

        # LXC templates
        elif image_type == "vztmpl":
            release_raw = spec.get("release", "")
            build_date = str(spec.get("build_date", "")).replace(":", "").replace("_", "")
            return f"{distro}-{release_raw}-cloud-{arch}-{build_date}.{extension}"

        return f"{distro}-{version}-{arch}.{extension}"


class TFVarsGenerator:
    """Orchestrates the tfvars generation process."""

    logger = logging.getLogger(__name__)

    def __init__(self, context: GenerationContext):
        """Initialize generator with context.

        Args:
            context: Generation context containing paths and data
        """
        self.context = context

    def generate(self) -> None:
        """Main generation entry point.

        Raises:
            GenerationError: If file operations fail
        """
        # Prepare all data using generator classes
        prepared_context = self._prepare_context()

        # Setup Jinja2 environment and render template
        template_dir = self.context.template_path.parent
        template_name = self.context.template_path.name

        with handle_template_errors(f"Error loading template {template_name}", TemplateLoadError):
            env = Environment(
                loader=FileSystemLoader(str(template_dir)),
                autoescape=select_autoescape(),
                trim_blocks=True,
                lstrip_blocks=True
            )
            template = env.get_template(template_name)

        with handle_template_errors(f"Error rendering template {template_name}", TemplateRenderError):
            output = template.render(**prepared_context)

        # Write output
        with handle_generation_errors(f"Error writing output to {self.context.output_path}"):
            self.context.output_path.write_text(output, encoding='utf-8')

        # Log statistics
        self._log_statistics(prepared_context)

    def _prepare_context(self) -> dict[str, Any]:
        """Prepare complete template context using all generator classes.

        Returns:
            Dictionary with all prepared data for template rendering
        """
        manifest = self.context.manifest
        checksums = self.context.checksums

        return {
            'manifest': manifest,  # Still needed for global values in images section
            'images': ImageGenerator.prepare_images(manifest, checksums),
            'vm_templates': VMTemplateGenerator.prepare_vm_templates(manifest),
            'container_templates': ContainerTemplateGenerator.prepare_container_templates(manifest),
            'virtual_machines': VirtualMachineGenerator.prepare_virtual_machines(manifest),
            'containers': ContainerGenerator.prepare_containers(manifest),
            'ci_user_configs': CloudInitGenerator.prepare_user_configs(manifest),
            'ci_vendor_configs': CloudInitGenerator.prepare_vendor_configs(manifest),
            'ci_network_configs': CloudInitGenerator.prepare_network_configs(manifest),
            'ci_meta_configs': CloudInitGenerator.prepare_meta_configs(manifest),
            'talos_config': TalosGenerator.prepare_talos_config(manifest)
        }

    def _log_statistics(self, prepared_context: dict[str, Any]) -> None:
        """Log generation statistics.

        Args:
            prepared_context: Prepared context dictionary
        """
        self.logger.info(f"Successfully generated {self.context.output_path}")
        self.logger.info(f"   Processed {len(self.context.manifest.get('images', {}))} images")
        self.logger.info(f"   Processed {len(prepared_context['vm_templates'])} VM templates")
        self.logger.info(f"   Processed {len(prepared_context['container_templates'])} container templates")


def load_manifest(manifest_path: Path) -> dict[str, Any]:
    """Load and parse YAML manifest file.

    Args:
        manifest_path: Path to manifest YAML file

    Returns:
        Parsed manifest dictionary

    Raises:
        ManifestError: If manifest cannot be loaded or parsed
    """
    with handle_manifest_errors(f"Error loading manifest from {manifest_path}"), \
         manifest_path.open('r', encoding='utf-8') as f:
        return yaml.load(f, Loader=yaml.SafeLoader)


def load_checksums(checksums_path: Path) -> dict[str, Any]:
    """Load checksums file (optional).

    Args:
        checksums_path: Path to checksums YAML file

    Returns:
        Parsed checksums dictionary (empty if file doesn't exist)
    """
    logger = logging.getLogger('generate_tfvars')

    if not checksums_path.exists():
        logger.debug(f"Checksums file not found at {checksums_path}, using empty checksums")
        return {"checksums": {}}

    try:
        with checksums_path.open('r', encoding='utf-8') as f:
            checksums = yaml.load(f, Loader=yaml.SafeLoader)
            return checksums or {"checksums": {}}
    except (yaml.YAMLError, PermissionError) as e:
        logger.warning(f"Error loading checksums from {checksums_path}: {e}")
        return {"checksums": {}}


def main() -> int:
    """Main CLI entry point.

    Returns:
        Exit code (0 for success, non-zero for errors)
    """
    parser = argparse.ArgumentParser(
        description="Generate Terraform/OpenTofu variables from YAML manifest",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument('--manifest', '-m', type=Path, default=DEFAULT_MANIFEST_PATH,
                       help=f'Path to infrastructure-manifest.yaml (default: {DEFAULT_MANIFEST_PATH})')
    parser.add_argument('--checksums', '-c', type=Path, default=DEFAULT_CHECKSUMS_PATH,
                       help=f'Path to checksums.yaml (default: {DEFAULT_CHECKSUMS_PATH})')
    parser.add_argument('--template', '-t', type=Path, default=DEFAULT_TEMPLATE_PATH,
                       help=f'Path to Jinja2 template (default: {DEFAULT_TEMPLATE_PATH})')
    parser.add_argument('--output', '-o', type=Path, default=DEFAULT_OUTPUT_PATH,
                       help=f'Path to output file (default: {DEFAULT_OUTPUT_PATH})')
    parser.add_argument('--verbose', '-v', action='store_true',
                       help='Enable verbose output (show additional info messages)')

    args = parser.parse_args()

    # Setup logging
    setup_logging_from_config(
        profile='development' if args.verbose else 'production',
        verbose=args.verbose
    )

    # Run generation
    with handle_application_errors():
        # Load manifest and checksums
        manifest = load_manifest(args.manifest)
        checksums = load_checksums(args.checksums)

        # Create generation context
        context = GenerationContext(
            manifest=manifest,
            checksums=checksums,
            manifest_path=args.manifest,
            checksums_path=args.checksums,
            template_path=args.template,
            output_path=args.output
        )

        # Generate tfvars
        generator = TFVarsGenerator(context)
        generator.generate()

    return EXIT_SUCCESS


if __name__ == "__main__":
    sys.exit(main())
