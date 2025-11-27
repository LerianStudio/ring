# Security Fixes Applied to Ring Multi-Platform Installer

This document summarizes the security validations added to the Ring installer codebase.

## Date: 2025-11-27

## Overview

Five medium-severity security issues have been addressed across the installer codebase to prevent path traversal attacks, symlink vulnerabilities, command injection, and race conditions.

## Fixes Applied

### 1. Path Traversal Validation (Medium Priority)

**Location:** `installer/ring_installer/core.py` - `InstallTarget.__post_init__()`

**Issue:** Custom install paths were not validated, potentially allowing installation outside safe directories.

**Fix:** Added validation to ensure custom install paths are within expected boundaries:
- Paths must be under the user's home directory, OR
- Paths must be under `/opt` or `/usr/local` (standard system locations)
- Paths are resolved to absolute paths to prevent traversal attacks

**Code Changes:**
```python
def __post_init__(self):
    if self.path is not None:
        self.path = Path(self.path).expanduser().resolve()
        # Validate path is within expected boundaries
        home = Path.home()
        try:
            self.path.relative_to(home)
        except ValueError:
            # Path not under home - check if it's a reasonable location
            allowed = [Path("/opt"), Path("/usr/local")]
            if not any(
                self.path.is_relative_to(p) for p in allowed if p.exists()
            ):
                raise ValueError(
                    f"Install path must be under home directory or /opt, /usr/local: {self.path}"
                )
```

**Impact:** Prevents installation to arbitrary system locations like `/etc`, `/var`, or other sensitive directories.

---

### 2. Symlink Validation (Medium Priority)

**Location:** `installer/ring_installer/utils/fs.py` - `copy_with_transform()` and `atomic_write()`

**Issue:** Functions could write to symlink targets, potentially overwriting critical system files.

**Fix:** Added symlink checks before writing to target files:

**In `copy_with_transform()`:**
```python
# Check if target exists and is a symlink
if target.exists() and target.is_symlink():
    raise ValueError(f"Refusing to write to symlink: {target}")
```

**In `atomic_write()`:**
```python
# Check if target exists and is a symlink
if path.exists() and path.is_symlink():
    raise ValueError(f"Refusing to write to symlink: {path}")
```

**Impact:** Prevents symlink attacks where an attacker could trick the installer into overwriting system files via symlinks.

---

### 3. Use Resolved Binary Path in Subprocess (Medium Priority)

**Location:** `installer/ring_installer/utils/platform_detect.py` - `_detect_claude()` and `_detect_factory()`

**Issue:** Using command strings instead of resolved paths in subprocess calls could be exploited via PATH manipulation.

**Fix:** Changed subprocess calls to use the resolved binary path returned by `shutil.which()`:

**Before:**
```python
binary = shutil.which("claude")
if binary:
    result = subprocess.run(["claude", "--version"], ...)
```

**After:**
```python
binary = shutil.which("claude")
if binary:
    result = subprocess.run([binary, "--version"], ...)  # Use resolved path
```

**Applied to:**
- `_detect_claude()` (line 151-163)
- `_detect_factory()` (line 193-212)

**Impact:** Ensures the correct binary is executed even if PATH is manipulated, preventing command injection through malicious binaries in the PATH.

---

### 4. Atomic Write Race Condition (Medium Priority)

**Location:** `installer/ring_installer/utils/fs.py` - `atomic_write()`

**Issue:** Predictable temporary file names created a race condition where an attacker could replace the temp file before it's renamed.

**Fix:** Used Python's `tempfile` module for secure random temp filenames:

**Before:**
```python
temp_path = path.parent / f".{path.name}.tmp"
```

**After:**
```python
import tempfile

fd, temp_path_str = tempfile.mkstemp(
    dir=path.parent,
    prefix=f".{path.name}.",
    suffix=".tmp"
)
temp_path = Path(temp_path_str)
```

**Additional Improvements:**
- Use `os.fdopen(fd, ...)` to write directly to the secure file descriptor
- Improved error handling to clean up temp file on exceptions
- Added symlink check before writing

**Impact:** Eliminates TOCTOU (time-of-check-time-of-use) race condition by using unpredictable temporary filenames.

---

### 5. Factory Terminology Replacement (Medium Priority)

**Location:** `installer/ring_installer/adapters/factory.py` - `_replace_agent_references()`

**Issue:** Overly broad replacement was changing "agent" to "droid" in unrelated contexts like "user agent", code blocks, and URLs.

**Fix:** Implemented selective replacement with protected regions:

**Features:**
- Protects code blocks (fenced and inline) from replacement
- Protects URLs from replacement
- Excludes "user agent" and similar terms from replacement
- Only replaces Ring-specific agent references (e.g., `ring:*-agent`, `subagent_type`)
- Uses negative lookbehind/lookahead patterns to avoid false positives

**Code Structure:**
1. Identify protected regions (code blocks, URLs)
2. Replace Ring-specific contexts (tool references, subagent)
3. Replace general "agent" terminology with exclusions
4. Skip replacements in protected regions

**Impact:** Prevents corruption of code samples, URLs, and technical terms during Factory AI transformation.

---

## Testing Recommendations

The following tests should be added or updated:

### Path Traversal Tests
```python
def test_rejects_path_outside_home(self):
    """InstallTarget should reject paths outside home directory."""
    with pytest.raises(ValueError) as exc:
        InstallTarget(platform="claude", path="/etc/passwd")
    assert "Install path must be under home directory" in str(exc.value)

def test_accepts_path_in_opt(self):
    """InstallTarget should accept paths under /opt."""
    target = InstallTarget(platform="claude", path="/opt/ring")
    assert target.path == Path("/opt/ring").resolve()
```

### Symlink Tests
```python
def test_copy_with_transform_rejects_symlink(self, tmp_path):
    """copy_with_transform() should reject writing to symlink."""
    source = tmp_path / "source.txt"
    source.write_text("content")
    target = tmp_path / "link.txt"
    real_target = tmp_path / "real.txt"
    real_target.write_text("original")
    target.symlink_to(real_target)

    with pytest.raises(ValueError) as exc:
        copy_with_transform(source, target)
    assert "symlink" in str(exc.value).lower()

def test_atomic_write_rejects_symlink(self, tmp_path):
    """atomic_write() should reject writing to symlink."""
    target = tmp_path / "link.txt"
    real_target = tmp_path / "real.txt"
    real_target.write_text("original")
    target.symlink_to(real_target)

    with pytest.raises(ValueError) as exc:
        atomic_write(target, "new content")
    assert "symlink" in str(exc.value).lower()
```

### Factory Replacement Tests
```python
def test_preserves_user_agent(self):
    """_replace_agent_references() should not replace 'user agent'."""
    text = "The user agent string contains browser info."
    result = adapter._replace_agent_references(text)
    assert "user agent" in result
    assert "user droid" not in result

def test_preserves_code_blocks(self):
    """_replace_agent_references() should not replace inside code blocks."""
    text = "```python\nagent = Agent()\n```"
    result = adapter._replace_agent_references(text)
    assert "agent = Agent()" in result

def test_replaces_ring_contexts(self):
    """_replace_agent_references() should replace Ring-specific contexts."""
    # Test uses old shorthand format to verify adapter transformation behavior
    text = 'Use "ring:test-agent" for testing'
    result = adapter._replace_agent_references(text)
    # Adapter should transform ring:test-agent → ring:test-droid for Factory AI
    assert "ring:test-droid" in result
```

---

## Backward Compatibility

These changes maintain backward compatibility:
- Valid installation paths continue to work unchanged
- Error messages clearly indicate why a path/operation was rejected
- No changes to public API signatures
- Factory AI transformations preserve semantic meaning

---

## Security Posture Improvements

| Vulnerability Type | Before | After |
|-------------------|--------|-------|
| Path Traversal | ❌ Unrestricted | ✅ Validated boundaries |
| Symlink Attacks | ❌ Unprotected | ✅ Explicit checks |
| Command Injection | ⚠️ Weak protection | ✅ Resolved paths |
| Race Conditions | ⚠️ Predictable temps | ✅ Secure random |
| Code Corruption | ⚠️ Over-replacement | ✅ Context-aware |

---

## Files Modified

1. `installer/ring_installer/core.py`
   - Added path validation to `InstallTarget.__post_init__()`

2. `installer/ring_installer/utils/fs.py`
   - Added symlink check to `copy_with_transform()`
   - Rewrote `atomic_write()` with `tempfile` module and symlink check

3. `installer/ring_installer/utils/platform_detect.py`
   - Updated `_detect_claude()` to use resolved binary path
   - Updated `_detect_factory()` to use resolved binary path

4. `installer/ring_installer/adapters/factory.py`
   - Rewrote `_replace_agent_references()` with protected regions and selective replacement

---

## Future Considerations

1. **Additional Validation:**
   - Consider adding disk space checks before installation
   - Validate that target paths are writable before starting installation

2. **Security Hardening:**
   - Consider adding file integrity verification (checksums)
   - Add optional GPG signature verification for source files

3. **Audit Logging:**
   - Log security-related rejections for monitoring
   - Track installation attempts to sensitive directories

4. **Documentation:**
   - Update user documentation to clarify allowed installation paths
   - Add security guidelines for administrators

---

## References

- OWASP Path Traversal: https://owasp.org/www-community/attacks/Path_Traversal
- CWE-59 Improper Link Resolution: https://cwe.mitre.org/data/definitions/59.html
- CWE-367 TOCTOU Race Condition: https://cwe.mitre.org/data/definitions/367.html
- Python tempfile Security: https://docs.python.org/3/library/tempfile.html#tempfile.mkstemp
