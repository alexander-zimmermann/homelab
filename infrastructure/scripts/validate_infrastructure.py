#!/usr/bin/env python3
"""
Centralized Infrastructure Validation Script

This script validates Homelab Infrastructure Manifest YAML files using JSON Schema
and provides additional cross-reference validation.

Usage:
  python validate_infrastructure.py pre --manifest infrastructure-manifest.yaml --schema schema.json
  python validate_infrastructure.py post --manifest infrastructure-manifest.yaml --generated generated.auto.tfvars
"""

from __future__ import annotations

import argparse
import json
import logging
import re
import sys
import yaml
import jsonschema

from pathlib import Path
from typing import Dict, Any, Set, List, Generator
from dataclasses import dataclass
from contextlib import contextmanager

from logging_formatter import setup_logging_from_config


# Exit codes
EXIT_SUCCESS = 0
EXIT_VALIDATION_ERROR = 1
EXIT_MANIFEST_ERROR = 2
EXIT_SCHEMA_ERROR = 3
EXIT_UNEXPECTED_ERROR = 99

# Default paths
DEFAULT_MANIFEST_PATH = Path("./infrastructure-manifest.yaml")
DEFAULT_GENERATED_PATH = Path("./generated.auto.tfvars")
DEFAULT_SCHEMA_PATH = Path("./schemas/infrastructure-manifest.schema.json")


# Custom exception for validation errors.
class ValidationError(Exception):
    """Custom exception for validation errors."""
    pass


class ManifestError(Exception):
    """Exception for manifest parsing errors."""
    pass


class SchemaError(Exception):
    """Exception for schema loading/validation errors."""
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
def handle_schema_errors(message: str, result: 'ValidationResult' = None) -> Generator[None, None, None]:
    """Context manager that handles all schema-related errors.

    Args:
        message: Error message prefix
        result: Optional ValidationResult to add errors to

    Yields:
        None

    Raises:
        SchemaError: If any schema-related error occurs
    """
    try:
        yield
    except (FileNotFoundError, json.JSONDecodeError, jsonschema.SchemaError) as e:
        raise SchemaError(f"{message}: {e}") from e
    except jsonschema.ValidationError as e:
        if result is not None:
            # Convert JSON Schema validation error to ValidationResult format
            error_path = " -> ".join(str(p) for p in e.absolute_path) if e.absolute_path else "root"
            result.add_error(f"Schema validation failed at {error_path}: {e.message}")
        else:
            # Fallback: raise as SchemaError if no result object provided
            raise SchemaError(f"{message}: {e}") from e


@contextmanager
def handle_validation_errors(message: str) -> Generator[None, None, None]:
    """Context manager that converts validation errors to ValidationError.

    Args:
        message: Error message prefix

    Yields:
        None

    Raises:
        ValidationError: If any validation-related error occurs
    """
    try:
        yield
    except (FileNotFoundError, PermissionError, yaml.YAMLError) as e:
        raise ValidationError(f"{message}: {e}") from e


@contextmanager
def handle_application_errors() -> Generator[None, None, None]:
    """Context manager for application-level error handling.

    Yields:
        None

    Side Effects:
        Exits the program with appropriate exit code on error
    """
    logger = logging.getLogger('validate_infrastructure')
    try:
        yield
    except ManifestError as e:
        logger.error(str(e))
        sys.exit(EXIT_MANIFEST_ERROR)
    except SchemaError as e:
        logger.error(str(e))
        sys.exit(EXIT_SCHEMA_ERROR)
    except ValidationError as e:
        logger.error(str(e))
        sys.exit(EXIT_VALIDATION_ERROR)
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        sys.exit(EXIT_UNEXPECTED_ERROR)


@dataclass
class ValidationResult:
    """Container for validation results."""
    errors: List[str]
    warnings: List[str]

    def __init__(self):
        """Initialize empty results."""
        self.errors = []
        self.warnings = []

    def add_error(self, message: str):
        """Add validation error."""
        self.errors.append(message)

    def add_warning(self, message: str):
        """Add validation warning."""
        self.warnings.append(message)

    def merge(self, other: 'ValidationResult'):
        """Merge another validation result."""
        self.errors.extend(other.errors)
        self.warnings.extend(other.warnings)

    def is_valid(self) -> bool:
        """Check if validation passed (no errors)."""
        return len(self.errors) == 0

    def __bool__(self) -> bool:
        """Boolean evaluation (True if valid)."""
        return self.is_valid()

    def __str__(self) -> str:
        """Human-readable string representation."""
        return f"ValidationResult(errors={len(self.errors)}, warnings={len(self.warnings)})"

    def __repr__(self) -> str:
        """Developer-friendly representation."""
        return f"ValidationResult(errors={self.errors!r}, warnings={self.warnings!r})"

    def merge(self, other: 'ValidationResult') -> 'ValidationResult':
        """Merge another validation result.

        Args:
            other: Another ValidationResult to merge

        Returns:
            Self for method chaining
        """
        self.errors.extend(other.errors)
        self.warnings.extend(other.warnings)
        return self

    def print_results(self):
        """Print validation results using logging."""
        logger = logging.getLogger('validate_infrastructure')

        for warning in self.warnings:
            logger.warning(warning)

        for error in self.errors:
            logger.error(error)

        if not self.errors:
            logger.info("All validations passed.")


class PreValidation:
    """Pre-generation validation using JSON Schema."""

    logger = logging.getLogger(__name__)

    def __init__(self, manifest: Dict[str, Any], schema: Dict[str, Any]):
        """Initialize with JSON Schema."""
        self.manifest = manifest
        self.schema = schema

    def validate_manifest(self) -> ValidationResult:
        """Validate manifest using JSON Schema."""
        result = ValidationResult()

        with handle_schema_errors("JSON Schema validation failed", result):
            # Primary validation using JSON Schema
            jsonschema.validate(self.manifest, self.schema)

        # Additional cross-reference validations
        result.merge(self._validate_references(self.manifest))

        return result

    def _validate_reference(
        self,
        result: ValidationResult,
        items: Dict[str, Any],
        item_type: str,
        ref_field: str,
        ref_type: str,
        valid_keys: Set[str]
    ) -> None:
        """Validate references in a collection.

        Args:
            result: ValidationResult to add errors to
            items: Dictionary of items to validate
            item_type: Human-readable item type (e.g., "VM template")
            ref_field: Field name to check (e.g., "image")
            ref_type: Human-readable reference type (e.g., "image")
            valid_keys: Set of valid reference keys
        """
        for key, item in items.items():
            if ref_field in item and item[ref_field] not in valid_keys:
                result.add_error(
                    f"{item_type} '{key}' references unknown {ref_type}: {item[ref_field]}"
                )

    def _validate_references(self, manifest: Dict[str, Any]) -> ValidationResult:
        """Validate cross-references between sections."""
        result = ValidationResult()

        # Get available keys for reference validation
        image_keys = set(manifest.get('images', {}).keys())
        vm_template_keys = set(manifest.get('vm_templates', {}).keys())
        container_template_keys = set(manifest.get('container_templates', {}).keys())
        resource_policy_keys = set(manifest.get('resource_policies', {}).keys())
        ci_profile_keys = set(manifest.get('vm_cloud_init_profiles', {}).keys())
        ci_user_keys = set(manifest.get('ci_user_configs', {}).keys())
        ci_vendor_keys = set(manifest.get('ci_vendor_configs', {}).keys())
        ci_network_keys = set(manifest.get('ci_network_configs', {}).keys())
        ci_meta_keys = set(manifest.get('ci_meta_configs', {}).keys())

        # Validate VM template references
        self._validate_reference(
            result, manifest.get('vm_templates', {}),
            'VM template', 'image', 'image', image_keys
        )
        self._validate_reference(
            result, manifest.get('vm_templates', {}),
            'VM template', 'resource_policy', 'resource policy', resource_policy_keys
        )
        self._validate_reference(
            result, manifest.get('vm_templates', {}),
            'VM template', 'cloud_init_profile', 'cloud init profile', ci_profile_keys
        )

        # Validate container template references
        self._validate_reference(
            result, manifest.get('container_templates', {}),
            'Container template', 'image', 'image', image_keys
        )
        self._validate_reference(
            result, manifest.get('container_templates', {}),
            'Container template', 'resource_policy', 'resource policy', resource_policy_keys
        )

        # Validate VM singles and batches references
        self._validate_reference(
            result, manifest.get('virtual_machines', {}).get('singles', {}),
            'VM single', 'template_id', 'template', vm_template_keys
        )
        self._validate_reference(
            result, manifest.get('virtual_machines', {}).get('batches', {}),
            'VM batch', 'template_id', 'template', vm_template_keys
        )

        # Validate container singles and batches references
        self._validate_reference(
            result, manifest.get('containers', {}).get('singles', {}),
            'Container single', 'template_id', 'template', container_template_keys
        )
        self._validate_reference(
            result, manifest.get('containers', {}).get('batches', {}),
            'Container batch', 'template_id', 'template', container_template_keys
        )

        # Validate CI profile references
        self._validate_reference(
            result, manifest.get('vm_cloud_init_profiles', {}),
            'CI profile', 'ci_user_data_id', 'user config', ci_user_keys
        )
        self._validate_reference(
            result, manifest.get('vm_cloud_init_profiles', {}),
            'CI profile', 'ci_vendor_data_id', 'vendor config', ci_vendor_keys
        )
        self._validate_reference(
            result, manifest.get('vm_cloud_init_profiles', {}),
            'CI profile', 'ci_network_data_id', 'network config', ci_network_keys
        )
        self._validate_reference(
            result, manifest.get('vm_cloud_init_profiles', {}),
            'CI profile', 'ci_meta_data_id', 'meta config', ci_meta_keys
        )

        return result


class PostValidation:
    """Post-generation validation (after Jinja2 template rendering)."""

    logger = logging.getLogger(__name__)

    # Regex patterns for parsing generated file
    GENERATED_BLOCK_PATTERNS = {
        name: re.compile(rf'{name}\s*=\s*\{{(.*?)\n\}}', re.DOTALL) for name in [
            'images', 'vm_templates', 'container_templates',
            'virtual_machines', 'containers',
            'ci_user_configs', 'ci_vendor_configs',
            'ci_network_configs', 'ci_meta_configs'
        ]
    }

    KEY_PATTERN = re.compile(r'^\s*([a-zA-Z0-9_.-]+)\s*= \{')

    def __init__(self, manifest: Dict[str, Any], generated_content: str):
        """Initialize with JSON Schema."""
        self.manifest = manifest
        self.generated_content = generated_content

    def validate_consistency(self) -> ValidationResult:
        """Main post-validation entry point."""
        result = ValidationResult()

        with handle_validation_errors("Error parsing generated components"):
            # Parse generated components
            generated_components = self._parse_generated_components(self.generated_content)

        with handle_validation_errors("Error validating completeness"):
            # Validate completeness
            result.merge(self._validate_completeness(self.manifest, generated_components))

        with handle_validation_errors("Error validating filename consistency"):
            # Validate filename consistency
            result.merge(self._validate_filenames(self.generated_content))

        return result

    def _parse_generated_components(self, content: str) -> Dict[str, Set[str]]:
        """Parse all component keys from generated file."""
        components = {}

        for component_type, pattern in self.GENERATED_BLOCK_PATTERNS.items():
            match = pattern.search(content)
            if match:
                keys = set()
                for line in match.group(1).splitlines():
                    key_match = self.KEY_PATTERN.match(line)
                    if key_match:
                        keys.add(key_match.group(1))
                components[component_type] = keys
            else:
                components[component_type] = set()

        return components

    def _validate_completeness(self, manifest: Dict[str, Any], generated_components: Dict[str, Set[str]]) -> ValidationResult:
        """Validate that all manifest components are generated."""
        result = ValidationResult()

        # Images
        manifest_images = set(manifest.get('images', {}).keys())
        generated_images = generated_components.get('images', set())
        self._compare_sets(result, 'images', manifest_images, generated_images)

        # VM Templates
        manifest_vm_templates = set(manifest.get('vm_templates', {}).keys())
        generated_vm_templates = generated_components.get('vm_templates', set())
        self._compare_sets(result, 'vm_templates', manifest_vm_templates, generated_vm_templates)

        # Container Templates
        manifest_container_templates = set(manifest.get('container_templates', {}).keys())
        generated_container_templates = generated_components.get('container_templates', set())
        self._compare_sets(result, 'container_templates', manifest_container_templates, generated_container_templates)

        # Virtual Machines (combined singles and batches)
        virtual_machines = manifest.get('virtual_machines', {})
        manifest_vm_keys = set()
        # Add singles keys (with sanitization)
        manifest_vm_keys.update(key.replace('-', '_') for key in virtual_machines.get('singles', {}).keys())
        # Add batches keys (with sanitization)
        manifest_vm_keys.update(key.replace('-', '_') for key in virtual_machines.get('batches', {}).keys())

        generated_vm_keys = generated_components.get('virtual_machines', set())
        self._compare_sets(result, 'virtual_machines', manifest_vm_keys, generated_vm_keys)

        # Containers (combined singles and batches)
        containers = manifest.get('containers', {})
        manifest_container_keys = set()
        # Add singles keys (with sanitization)
        manifest_container_keys.update(key.replace('-', '_') for key in containers.get('singles', {}).keys())
        # Add batches keys (with sanitization)
        manifest_container_keys.update(key.replace('-', '_') for key in containers.get('batches', {}).keys())

        generated_container_keys = generated_components.get('containers', set())
        self._compare_sets(result, 'containers', manifest_container_keys, generated_container_keys)

        # CI Configs (with key sanitization)
        for config_type in ['ci_user_configs', 'ci_vendor_configs', 'ci_network_configs', 'ci_meta_configs']:
            manifest_keys = {key.replace('-', '_') for key in manifest.get(config_type, {}).keys()}
            generated_keys = generated_components.get(config_type, set())
            self._compare_sets(result, config_type, manifest_keys, generated_keys)

        return result

    def _compare_sets(self, result: ValidationResult, component_type: str, manifest_keys: Set[str], generated_keys: Set[str]):
        """Compare manifest and generated key sets."""
        missing = manifest_keys - generated_keys
        extra = generated_keys - manifest_keys

        if missing:
            result.add_error(f"Missing {component_type} keys in generated file: {sorted(missing)}")
        if extra:
            result.add_error(f"Unexpected {component_type} keys in generated file: {sorted(extra)}")

    def _validate_filenames(self, generated_content: str) -> ValidationResult:
        """Validate filename consistency with Proxmox extension mapping."""
        result = ValidationResult()

        # Extract image blocks and validate filename vs URL basename
        images_match = self.GENERATED_BLOCK_PATTERNS['images'].search(generated_content)
        if not images_match:
            return result

        # Parse each image block
        for line in images_match.group(1).splitlines():
            key_match = self.KEY_PATTERN.match(line)
            if key_match:
                key = key_match.group(1)

                # Extract the full block for this key
                block_pattern = re.compile(rf'{re.escape(key)}\s*=\s*\{{(.*?)\}}', re.DOTALL)
                block_match = block_pattern.search(generated_content)

                if block_match:
                    block_content = block_match.group(1)

                    # Extract URL, filename, and type
                    url_match = re.search(r'image_url\s*=\s*"([^"]+)"', block_content)
                    filename_match = re.search(r'image_filename\s*=\s*"([^"]*)"', block_content)
                    type_match = re.search(r'image_type\s*=\s*"([^"]+)"', block_content)

                    if url_match and filename_match and type_match:
                        url = url_match.group(1)
                        filename = filename_match.group(1)
                        img_type = type_match.group(1)

                        # For import types, validate extension mapping
                        if img_type == "import":
                            url_basename = url.split('/')[-1]

                            # Extract original extension
                            if '.' in url_basename:
                                original_ext = url_basename.split('.', 1)[1].lower()  # everything after first dot

        return result


class InfrastructureValidator:
    """Main validator class."""

    logger = logging.getLogger(__name__)

    def __init__(self, manifest_path: Path):
        """Initialize validators."""
        # Load manifest and schema (always needed)
        with handle_manifest_errors(f"Error loading manifest {manifest_path}"),\
             manifest_path.open('r', encoding='utf-8') as f:
            self.manifest = yaml.load(f, Loader=yaml.SafeLoader)

    def validate_pre_generation(self, schema_path: Path) -> ValidationResult:
        """Validate manifest before generation."""
        with handle_schema_errors(f"Error loading schema from {schema_path}"), \
             schema_path.open('r', encoding='utf-8') as f:
            schema = json.load(f)

        pre_validator = PreValidation(self.manifest, schema)
        return pre_validator.validate_manifest()

    def validate_post_generation(self, generated_path: Path) -> ValidationResult:
        """Validate generated file consistency."""
        with handle_validation_errors(f"Error reading generated file {generated_path}"):
            generated_content = generated_path.read_text(encoding='utf-8')

        post_validator = PostValidation(self.manifest, generated_content)
        return post_validator.validate_consistency()


def main():
    """Main CLI entry point."""
    parser = argparse.ArgumentParser(
        description="Centralized Infrastructure Validation using JSON Schema",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    # Global arguments
    parser.add_argument('--verbose', '-v', action='store_true',
                       help='Enable verbose output (show additional info messages)')

    # Create subparsers for pre/post commands
    subparsers = parser.add_subparsers(dest='command', help='Validation commands')
    subparsers.required = True

    # Pre-validation subcommand
    pre_parser = subparsers.add_parser('pre', help='Pre-generation validation (before template rendering)')
    pre_parser.add_argument('--manifest', '-m', type=Path, default=DEFAULT_MANIFEST_PATH,
                           help=f'Path to infrastructure-manifest.yaml (default: {DEFAULT_MANIFEST_PATH})')
    pre_parser.add_argument('--schema', '-s', type=Path, default=DEFAULT_SCHEMA_PATH,
                           help=f'Path to JSON schema file (default: {DEFAULT_SCHEMA_PATH})')

    # Post-validation subcommand
    post_parser = subparsers.add_parser('post', help='Post-generation validation (after template rendering)')
    post_parser.add_argument('--manifest', '-m', type=Path, default=DEFAULT_MANIFEST_PATH,
                            help=f'Path to infrastructure-manifest.yaml (default: {DEFAULT_MANIFEST_PATH})')
    post_parser.add_argument('--generated', '-g', type=Path, default=DEFAULT_GENERATED_PATH,
                            help=f'Path to generated.auto.tfvars (default: {DEFAULT_GENERATED_PATH})')
    post_parser.add_argument('--schema', '-s', type=Path, default=DEFAULT_SCHEMA_PATH,
                            help=f'Path to JSON schema file (default: {DEFAULT_SCHEMA_PATH})')

    args = parser.parse_args()

    # Setup logging from config
    setup_logging_from_config(
        profile='development' if args.verbose else 'production',
        verbose=args.verbose
    )

    # Run validation based on subcommand
    with handle_application_errors():
        validator = InfrastructureValidator(args.manifest)

        if args.command == 'pre':
            result = validator.validate_pre_generation(args.schema)
        elif args.command == 'post':
            result = validator.validate_post_generation(args.generated)

    result.print_results()
    return EXIT_SUCCESS if result else EXIT_VALIDATION_ERROR


if __name__ == '__main__':
    sys.exit(main())
