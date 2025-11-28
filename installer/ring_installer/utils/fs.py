"""
Filesystem utilities for Ring installer.

Provides safe file operations with backup, transformation, and error handling.
"""

import hashlib
import logging
import os
import shutil
import warnings
from datetime import datetime
from pathlib import Path
from typing import Callable, Optional, Union

logger = logging.getLogger(__name__)

# Hash algorithms considered weak and should be avoided
_WEAK_HASH_ALGORITHMS = {"md5", "sha1"}


def ensure_directory(path: Path) -> Path:
    """
    Ensure a directory exists, creating it if necessary.

    Args:
        path: Directory path to ensure exists

    Returns:
        The path that was created/verified

    Raises:
        PermissionError: If directory cannot be created due to permissions
        OSError: If directory creation fails for other reasons
    """
    path = Path(path).expanduser()

    if path.exists():
        if not path.is_dir():
            raise NotADirectoryError(f"Path exists but is not a directory: {path}")
        return path

    try:
        path.mkdir(parents=True, exist_ok=True)
        return path
    except PermissionError:
        raise PermissionError(f"Permission denied creating directory: {path}")
    except OSError as e:
        raise OSError(f"Failed to create directory {path}: {e}")


def backup_existing(path: Path, backup_dir: Optional[Path] = None) -> Optional[Path]:
    """
    Create a backup of an existing file or directory.

    Args:
        path: Path to the file/directory to backup
        backup_dir: Optional directory to store backups (default: same directory)

    Returns:
        Path to the backup, or None if source doesn't exist

    Raises:
        PermissionError: If backup cannot be created due to permissions
    """
    path = Path(path).expanduser()

    if not path.exists():
        return None

    # Generate backup name with timestamp
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_name = f"{path.name}.backup_{timestamp}"

    if backup_dir:
        backup_dir = Path(backup_dir).expanduser()
        ensure_directory(backup_dir)
        backup_path = backup_dir / backup_name
    else:
        backup_path = path.parent / backup_name

    try:
        if path.is_dir():
            shutil.copytree(path, backup_path)
        else:
            shutil.copy2(path, backup_path)
        return backup_path
    except PermissionError:
        raise PermissionError(f"Permission denied creating backup: {backup_path}")


def copy_with_transform(
    source: Path,
    target: Path,
    transform_func: Optional[Callable[[str], str]] = None,
    encoding: str = "utf-8"
) -> Path:
    """
    Copy a file with optional content transformation.

    Args:
        source: Source file path
        target: Target file path
        transform_func: Optional function to transform content
        encoding: File encoding (default: utf-8)

    Returns:
        Path to the created file

    Raises:
        FileNotFoundError: If source file doesn't exist
        PermissionError: If target cannot be written
        ValueError: If target is a symlink
    """
    source = Path(source).expanduser().resolve()
    target = Path(target).expanduser().resolve()

    if not source.exists():
        raise FileNotFoundError(f"Source file not found: {source}")

    # Check if target exists and is a symlink
    if target.exists() and target.is_symlink():
        raise ValueError(f"Refusing to write to symlink: {target}")

    # Ensure target directory exists
    ensure_directory(target.parent)

    # Handle binary files (no transformation)
    if _is_binary_file(source):
        shutil.copy2(source, target)
        return target

    # Read, transform, and write
    try:
        with open(source, "r", encoding=encoding) as f:
            content = f.read()
    except UnicodeDecodeError:
        # Fall back to binary copy if encoding fails
        shutil.copy2(source, target)
        return target

    if transform_func:
        content = transform_func(content)

    with open(target, "w", encoding=encoding) as f:
        f.write(content)

    # Preserve permissions
    shutil.copystat(source, target)

    return target


def safe_remove(path: Path, missing_ok: bool = True) -> bool:
    """
    Safely remove a file or directory.

    Args:
        path: Path to remove
        missing_ok: If True, don't raise error if path doesn't exist

    Returns:
        True if something was removed, False otherwise

    Raises:
        FileNotFoundError: If path doesn't exist and missing_ok is False
        PermissionError: If removal fails due to permissions
    """
    path = Path(path).expanduser()

    if not path.exists():
        if missing_ok:
            return False
        raise FileNotFoundError(f"Path not found: {path}")

    try:
        if path.is_dir():
            shutil.rmtree(path)
        else:
            path.unlink()
        return True
    except PermissionError:
        raise PermissionError(f"Permission denied removing: {path}")


def get_file_hash(path: Path, algorithm: str = "sha256") -> str:
    """
    Calculate hash of a file's contents.

    Args:
        path: Path to the file
        algorithm: Hash algorithm (sha256 recommended; md5 and sha1 are deprecated)

    Returns:
        Hexadecimal hash string

    Raises:
        FileNotFoundError: If file doesn't exist

    Warns:
        DeprecationWarning: If md5 or sha1 algorithm is used
    """
    path = Path(path).expanduser()

    if not path.exists():
        raise FileNotFoundError(f"File not found: {path}")

    # Warn about weak hash algorithms
    if algorithm.lower() in _WEAK_HASH_ALGORITHMS:
        warnings.warn(
            f"Hash algorithm '{algorithm}' is cryptographically weak. "
            "Use 'sha256' or 'sha512' for better security.",
            DeprecationWarning,
            stacklevel=2  # Points to immediate caller; use 3 if this function is wrapped
        )

    hash_func = hashlib.new(algorithm)

    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            hash_func.update(chunk)

    return hash_func.hexdigest()


def are_files_identical(path1: Path, path2: Path) -> bool:
    """
    Check if two files have identical content.

    Args:
        path1: First file path
        path2: Second file path

    Returns:
        True if files are identical, False otherwise
    """
    path1 = Path(path1).expanduser()
    path2 = Path(path2).expanduser()

    if not path1.exists() or not path2.exists():
        return False

    # Quick check: different sizes mean different content
    if path1.stat().st_size != path2.stat().st_size:
        return False

    # Compare hashes
    return get_file_hash(path1) == get_file_hash(path2)


def files_are_identical(path1: Path, path2: Path) -> bool:
    """
    Check if two files have identical content.

    .. deprecated:: 0.2.0
       Use :func:`are_files_identical` instead. This function will be
       removed in version 1.0.0.

    Args:
        path1: First file path
        path2: Second file path

    Returns:
        True if files are identical, False otherwise
    """
    warnings.warn(
        "files_are_identical() is deprecated, use are_files_identical() instead",
        DeprecationWarning,
        stacklevel=2
    )
    return are_files_identical(path1, path2)


def get_directory_size(path: Path) -> int:
    """
    Calculate total size of a directory and its contents.

    Args:
        path: Directory path

    Returns:
        Total size in bytes
    """
    path = Path(path).expanduser()
    total = 0

    if path.is_file():
        return path.stat().st_size

    for entry in path.rglob("*"):
        if entry.is_file():
            total += entry.stat().st_size

    return total


def list_files_recursive(
    path: Path,
    extensions: Optional[list[str]] = None,
    exclude_patterns: Optional[list[str]] = None
) -> list[Path]:
    """
    List all files in a directory recursively.

    Args:
        path: Directory to search
        extensions: Optional list of extensions to include (e.g., [".md", ".py"])
        exclude_patterns: Optional patterns to exclude (e.g., ["__pycache__", ".git"])

    Returns:
        List of file paths
    """
    path = Path(path).expanduser()
    exclude_patterns = exclude_patterns or []

    if not path.exists():
        return []

    files = []
    for entry in path.rglob("*"):
        if not entry.is_file():
            continue

        # Check exclusions
        skip = False
        for pattern in exclude_patterns:
            if pattern in str(entry):
                skip = True
                break
        if skip:
            continue

        # Check extensions
        if extensions:
            if entry.suffix not in extensions:
                continue

        files.append(entry)

    return sorted(files)


def atomic_write(path: Path, content: Union[str, bytes], encoding: str = "utf-8") -> None:
    """
    Write content to a file atomically.

    Writes to a temporary file first, then renames to target.
    This ensures the file is either fully written or not at all.

    Args:
        path: Target file path
        content: Content to write (str or bytes)
        encoding: Encoding for string content

    Raises:
        ValueError: If target is a symlink
    """
    import tempfile

    path = Path(path).expanduser().resolve()

    # Check if target exists and is a symlink
    if path.exists() and path.is_symlink():
        raise ValueError(f"Refusing to write to symlink: {path}")

    # Ensure parent directory exists
    ensure_directory(path.parent)

    # Use tempfile for secure random filename
    fd, temp_path_str = tempfile.mkstemp(
        dir=path.parent,
        prefix=f".{path.name}.",
        suffix=".tmp"
    )
    temp_path = Path(temp_path_str)

    try:
        if isinstance(content, bytes):
            with os.fdopen(fd, "wb") as f:
                f.write(content)
        else:
            with os.fdopen(fd, "w", encoding=encoding) as f:
                f.write(content)

        # Set explicit permissions (rw-r--r--) before rename
        os.chmod(temp_path, 0o644)

        # Atomic rename
        temp_path.replace(path)
    except Exception:
        # Clean up temp file on error
        if temp_path.exists():
            temp_path.unlink()
        raise
    finally:
        # Clean up temp file if rename failed
        if temp_path.exists():
            temp_path.unlink()


def _is_binary_file(path: Path, sample_size: int = 8192) -> bool:
    """
    Check if a file appears to be binary.

    Args:
        path: File path to check
        sample_size: Number of bytes to sample

    Returns:
        True if file appears to be binary
    """
    # Known binary extensions
    binary_extensions = {
        ".png", ".jpg", ".jpeg", ".gif", ".bmp", ".ico",
        ".pdf", ".zip", ".tar", ".gz", ".bz2",
        ".exe", ".dll", ".so", ".dylib",
        ".pyc", ".pyo", ".class",
    }

    if path.suffix.lower() in binary_extensions:
        return True

    # Check for null bytes in sample
    try:
        with open(path, "rb") as f:
            sample = f.read(sample_size)
        return b"\x00" in sample
    except Exception:
        return False
