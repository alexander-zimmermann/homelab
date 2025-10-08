"""
Shared logging formatter for infrastructure scripts.
"""
import logging
import os
import yaml
from logging.config import dictConfig
from pathlib import Path


class ColoredFormatter(logging.Formatter):
    """Simple colored formatter for better readability."""

    # ANSI color codes
    COLORS = {
        'DEBUG': '\033[36m',    # Cyan
        'INFO': '\033[32m',     # Green
        'WARNING': '\033[33m',  # Yellow
        'ERROR': '\033[31m',    # Red
        'CRITICAL': '\033[35m', # Magenta
    }
    RESET = '\033[0m'

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        # Only use colors in TTY and if not disabled
        self.use_colors = (
            hasattr(os.sys.stderr, 'isatty') and
            os.sys.stderr.isatty() and
            os.getenv('NO_COLOR') is None
        )

    def format(self, record):
        # Apply color to the entire message if supported
        if self.use_colors:
            color = self.COLORS.get(record.levelname, '')
            formatted = super().format(record)
            return f"{color}{formatted}{self.RESET}"
        else:
            return super().format(record)


def setup_logging_from_config(config_file: str = None,
                              profile: str = 'development', verbose: bool = False):
    """
    Setup logging from YAML configuration.

    Args:
        config_file: Path to logging config YAML file
        profile: Profile to use (development, production, ci)
        verbose: Enable verbose logging (overrides profile level)
    """

    config_file = Path(config_file or Path(__file__).parent / 'logging_config.yaml')

    try:
        with config_file.open('r') as f:
            config = yaml.safe_load(f)

        # Apply profile-specific overrides
        if profile in config.get('profiles', {}):
            profile_config = config['profiles'][profile]

            # Update handler references for loggers
            for logger_name in ['generate_checksums', 'validate_infrastructure', 'scripts']:
                if logger_name in config.get('loggers', {}):
                    config['loggers'][logger_name]['handlers'] = profile_config['handlers']
                    if not verbose:  # Only override if not explicitly verbose
                        config['loggers'][logger_name]['level'] = profile_config['level']

        # Override level if verbose requested
        if verbose:
            for logger_config in config.get('loggers', {}).values():
                logger_config['level'] = 'DEBUG'
            config['root']['level'] = 'DEBUG'

        dictConfig(config)

    except Exception as e:
        # Fallback to basic config if YAML config fails
        logging.basicConfig(
            level=logging.DEBUG if verbose else logging.INFO,
            format='[%(levelname)s] %(message)s'
        )
        logging.getLogger(__name__).warning(f"Failed to load logging config from {config_file}: {e}")
