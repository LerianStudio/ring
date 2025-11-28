"""
Platform adapters for Ring installer.

This module provides adapters for transforming Ring components to various
AI platform formats.

Supported Platforms:
- Claude Code: Native Ring format (passthrough)
- Factory AI: Agents -> Droids transformation
- Cursor: Skills -> Rules, Agents/Commands -> Workflows
- Cline: All components -> Prompts
"""

from typing import Dict, List, Optional, Type, TypeVar


# TypeVar for adapter type hints
AdapterT = TypeVar("AdapterT", bound="PlatformAdapter")


class PlatformID:
    """
    Platform identifier constants.

    Use these instead of magic strings when referencing platforms.

    Example:
        if platform == PlatformID.CLAUDE:
            # handle Claude Code
    """
    CLAUDE = "claude"
    FACTORY = "factory"
    CURSOR = "cursor"
    CLINE = "cline"

    @classmethod
    def all(cls) -> list[str]:
        """Return all platform identifiers."""
        return [cls.CLAUDE, cls.FACTORY, cls.CURSOR, cls.CLINE]

    @classmethod
    def is_valid(cls, platform: str) -> bool:
        """Check if a platform identifier is valid."""
        return platform.lower() in cls.all()


from ring_installer.adapters.base import PlatformAdapter
from ring_installer.adapters.claude import ClaudeAdapter
from ring_installer.adapters.factory import FactoryAdapter
from ring_installer.adapters.cursor import CursorAdapter
from ring_installer.adapters.cline import ClineAdapter

# Registry of supported platforms and their adapters
ADAPTER_REGISTRY: Dict[str, Type[PlatformAdapter]] = {
    PlatformID.CLAUDE: ClaudeAdapter,
    PlatformID.FACTORY: FactoryAdapter,
    PlatformID.CURSOR: CursorAdapter,
    PlatformID.CLINE: ClineAdapter,
}

# List of supported platform identifiers
SUPPORTED_PLATFORMS = list(ADAPTER_REGISTRY.keys())


def get_adapter(
    platform: str,
    config: Optional[dict] = None,
    adapter_class_override: Optional[Type[AdapterT]] = None
) -> PlatformAdapter:
    """
    Get an adapter instance for the specified platform.

    Args:
        platform: Platform identifier (claude, factory, cursor, cline)
        config: Optional platform-specific configuration
        adapter_class_override: Optional adapter class to use instead of registry

    Returns:
        Instantiated adapter for the platform

    Raises:
        ValueError: If the platform is not supported
    """
    platform = platform.lower()

    if adapter_class_override is not None:
        return adapter_class_override(config)

    if platform not in ADAPTER_REGISTRY:
        supported = ", ".join(SUPPORTED_PLATFORMS)
        raise ValueError(
            f"Unsupported platform: '{platform}'. "
            f"Supported platforms are: {supported}"
        )

    adapter_class = ADAPTER_REGISTRY[platform]
    return adapter_class(config)


def register_adapter(platform: str, adapter_class: Type[PlatformAdapter]) -> None:
    """
    Register a custom adapter for a platform.

    This allows extending the installer with support for additional platforms.

    Args:
        platform: Platform identifier
        adapter_class: Adapter class (must inherit from PlatformAdapter)

    Raises:
        TypeError: If adapter_class doesn't inherit from PlatformAdapter
    """
    if not issubclass(adapter_class, PlatformAdapter):
        raise TypeError(
            f"Adapter class must inherit from PlatformAdapter, "
            f"got {adapter_class.__name__}"
        )

    ADAPTER_REGISTRY[platform.lower()] = adapter_class


def list_platforms() -> list[dict]:
    """
    List all supported platforms with their details.

    Returns:
        List of platform information dictionaries
    """
    platforms = []
    for platform_id, adapter_class in ADAPTER_REGISTRY.items():
        adapter = adapter_class()
        platforms.append({
            "id": platform_id,
            "name": adapter.platform_name,
            "native_format": adapter.is_native_format(),
            "terminology": adapter.get_terminology(),
            "components": list(adapter.get_component_mapping().keys()),
        })
    return platforms


__all__ = [
    # Type hints
    "AdapterT",
    # Platform identifiers
    "PlatformID",
    # Base class
    "PlatformAdapter",
    # Concrete adapters
    "ClaudeAdapter",
    "FactoryAdapter",
    "CursorAdapter",
    "ClineAdapter",
    # Registry and utilities
    "ADAPTER_REGISTRY",
    "SUPPORTED_PLATFORMS",
    "get_adapter",
    "register_adapter",
    "list_platforms",
]
