"""
Base transformer classes and interfaces.

Provides the foundation for content transformation across platforms.
Transformers follow a pipeline pattern for composability.
"""

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Any, Callable, Dict, List, Optional, Protocol, Tuple
import re

# YAML import with error handling at module level
try:
    import yaml
    YAML_AVAILABLE = True
except ImportError:
    YAML_AVAILABLE = False


@dataclass
class TransformContext:
    """
    Context passed through transformation pipeline.

    Attributes:
        platform: Target platform identifier
        component_type: Type of component (skill, agent, command, hook)
        source_path: Original file path
        metadata: Additional metadata from discovery
        options: Platform-specific options
    """
    platform: str
    component_type: str
    source_path: str = ""
    metadata: Dict[str, Any] = field(default_factory=dict)
    options: Dict[str, Any] = field(default_factory=dict)


@dataclass
class TransformResult:
    """
    Result of a transformation operation.

    Attributes:
        content: Transformed content
        success: Whether transformation succeeded
        errors: List of error messages
        warnings: List of warning messages
        metadata: Additional output metadata
    """
    content: str
    success: bool = True
    errors: List[str] = field(default_factory=list)
    warnings: List[str] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)


class Transformer(Protocol):
    """Protocol for transformer implementations."""

    def transform(self, content: str, context: TransformContext) -> TransformResult:
        """Transform content according to context."""
        ...


class BaseTransformer(ABC):
    """
    Abstract base class for content transformers.

    Transformers handle conversion of Ring component formats
    to platform-specific formats.
    """

    # Class constants for platform-specific replacements
    CURSOR_REPLACEMENTS = [
        ("subagent", "sub-workflow"),
        ("Subagent", "Sub-workflow"),
        ("Task tool", "workflow step"),
        ("Skill tool", "rule reference"),
    ]

    CLINE_REPLACEMENTS = [
        ("Task tool", "sub-prompt"),
        ("Skill tool", "prompt reference"),
        ("subagent", "sub-prompt"),
        ("Subagent", "Sub-prompt"),
    ]

    def __init__(self):
        """Initialize the transformer."""
        self._yaml_imported = False

    @abstractmethod
    def transform(self, content: str, context: TransformContext) -> TransformResult:
        """
        Transform content for the target platform.

        Args:
            content: Source content to transform
            context: Transformation context

        Returns:
            TransformResult with transformed content
        """
        pass

    def validate(self, content: str, context: TransformContext) -> List[str]:
        """
        Validate content before transformation.

        Args:
            content: Content to validate
            context: Transformation context

        Returns:
            List of validation error messages (empty if valid)
        """
        errors = []

        if not content.strip():
            errors.append(f"Empty {context.component_type} content")

        return errors

    def extract_frontmatter(self, content: str) -> Tuple[Dict[str, Any], str]:
        """
        Extract YAML frontmatter from markdown content.

        Args:
            content: Markdown content with optional YAML frontmatter

        Returns:
            Tuple of (frontmatter dict, body content)
        """
        frontmatter: Dict[str, Any] = {}
        body = content

        # Skip leading HTML comment blocks and whitespace
        trimmed = content.lstrip()
        if trimmed.startswith("<!--"):
            comment_end = trimmed.find("-->")
            if comment_end != -1:
                trimmed = trimmed[comment_end + 3 :].lstrip()

        if trimmed.startswith("---"):
            end_marker = trimmed.find("---", 3)
            if end_marker != -1:
                yaml_content = trimmed[3:end_marker].strip()
                try:
                    if YAML_AVAILABLE:
                        frontmatter = yaml.safe_load(yaml_content) or {}
                except Exception:
                    pass
                body = trimmed[end_marker + 3 :].strip()
            else:
                body = trimmed
        else:
            body = trimmed

        return frontmatter, body

    def create_frontmatter(self, data: Dict[str, Any]) -> str:
        """
        Create YAML frontmatter string from dictionary.

        Args:
            data: Dictionary to convert to YAML frontmatter

        Returns:
            YAML frontmatter string with --- delimiters
        """
        if not data:
            return ""

        if not YAML_AVAILABLE:
            return ""

        yaml_str = yaml.dump(data, default_flow_style=False, allow_unicode=True, sort_keys=False)
        return f"---\n{yaml_str}---\n"

    def clean_yaml_string(self, text: str) -> str:
        """
        Clean up YAML multi-line string markers.

        Args:
            text: YAML string value

        Returns:
            Cleaned string
        """
        if not isinstance(text, str):
            return str(text) if text else ""
        # Remove | and > markers
        text = re.sub(r'^[|>]\s*', '', text)
        return text.strip()

    def to_title_case(self, text: str) -> str:
        """
        Convert text to title case, handling kebab-case and snake_case.

        Args:
            text: Input text

        Returns:
            Title-cased text
        """
        # Replace separators with spaces
        text = text.replace("-", " ").replace("_", " ")
        return text.title()

    def transform_body_for_cursor(self, body: str) -> str:
        """
        Transform body content for Cursor compatibility.

        Args:
            body: Original body content

        Returns:
            Transformed content with Cursor-specific terminology
        """
        result = body

        # Apply Cursor-specific replacements
        for old, new in self.CURSOR_REPLACEMENTS:
            result = result.replace(old, new)

        # Transform ring: references
        result = re.sub(
            r'`ring:([^`]+)`',
            lambda m: f"**{self.to_title_case(m.group(1))}**",
            result
        )

        return result

    def transform_body_for_cline(self, body: str) -> str:
        """
        Transform body content for Cline compatibility.

        Args:
            body: Original body content

        Returns:
            Transformed content with Cline-specific terminology
        """
        result = body

        # Apply Cline-specific replacements
        for old, new in self.CLINE_REPLACEMENTS:
            result = result.replace(old, new)

        # Transform ring: references to @ format
        result = re.sub(
            r'`ring:([^`]+)`',
            lambda m: f"@{m.group(1).lower().replace('_', '-')}",
            result
        )

        result = re.sub(
            r'"ring:([^"]+)"',
            lambda m: f'"@{m.group(1).lower().replace("_", "-")}"',
            result
        )

        return result

    def add_list_items(self, parts: List[str], text: str) -> None:
        """
        Add list items from YAML list or multi-line string.

        Args:
            parts: List to append items to
            text: Text containing list items
        """
        clean_text = self.clean_yaml_string(text)
        for line in clean_text.split("\n"):
            line = line.strip()
            if line:
                if line.startswith("-"):
                    parts.append(line)
                else:
                    parts.append(f"- {line}")


class TransformerPipeline:
    """
    Pipeline for composing multiple transformers.

    Allows transformers to be chained together, with each
    transformer receiving the output of the previous one.
    """

    def __init__(self, transformers: Optional[List[BaseTransformer]] = None):
        """
        Initialize the pipeline.

        Args:
            transformers: Optional list of transformers to add
        """
        self._transformers: List[BaseTransformer] = transformers or []

    def add(self, transformer: BaseTransformer) -> "TransformerPipeline":
        """
        Add a transformer to the pipeline.

        Args:
            transformer: Transformer to add

        Returns:
            Self for chaining
        """
        self._transformers.append(transformer)
        return self

    def transform(self, content: str, context: TransformContext) -> TransformResult:
        """
        Run content through all transformers in the pipeline.

        Args:
            content: Source content
            context: Transformation context

        Returns:
            Final TransformResult
        """
        current_content = content
        all_errors: List[str] = []
        all_warnings: List[str] = []
        combined_metadata: Dict[str, Any] = {}

        for transformer in self._transformers:
            result = transformer.transform(current_content, context)

            all_errors.extend(result.errors)
            all_warnings.extend(result.warnings)
            combined_metadata.update(result.metadata)

            if not result.success:
                return TransformResult(
                    content=current_content,
                    success=False,
                    errors=all_errors,
                    warnings=all_warnings,
                    metadata=combined_metadata
                )

            current_content = result.content

        return TransformResult(
            content=current_content,
            success=True,
            errors=all_errors,
            warnings=all_warnings,
            metadata=combined_metadata
        )

    def __len__(self) -> int:
        return len(self._transformers)


class PassthroughTransformer(BaseTransformer):
    """Transformer that returns content unchanged."""

    def transform(self, content: str, context: TransformContext) -> TransformResult:
        """Return content unchanged."""
        return TransformResult(content=content, success=True)


class TerminologyTransformer(BaseTransformer):
    """
    Transformer that replaces terminology based on platform conventions.
    """

    def __init__(self, terminology_map: Dict[str, str]):
        """
        Initialize with terminology mapping.

        Args:
            terminology_map: Mapping from Ring terms to platform terms
        """
        super().__init__()
        self.terminology_map = terminology_map

    def transform(self, content: str, context: TransformContext) -> TransformResult:
        """Replace terminology in content."""
        result = content

        for ring_term, platform_term in self.terminology_map.items():
            if ring_term != platform_term:
                # Case-sensitive replacements
                result = re.sub(rf'\b{ring_term}\b', platform_term, result)
                result = re.sub(rf'\b{ring_term.title()}\b', platform_term.title(), result)
                result = re.sub(rf'\b{ring_term.upper()}\b', platform_term.upper(), result)

        return TransformResult(content=result, success=True)


class FrontmatterTransformer(BaseTransformer):
    """
    Transformer that modifies YAML frontmatter fields.
    """

    def __init__(
        self,
        field_mapping: Optional[Dict[str, str]] = None,
        remove_fields: Optional[List[str]] = None,
        add_fields: Optional[Dict[str, Any]] = None
    ):
        """
        Initialize with frontmatter modifications.

        Args:
            field_mapping: Mapping to rename fields
            remove_fields: Fields to remove
            add_fields: Fields to add
        """
        super().__init__()
        self.field_mapping = field_mapping or {}
        self.remove_fields = remove_fields or []
        self.add_fields = add_fields or {}

    def transform(self, content: str, context: TransformContext) -> TransformResult:
        """Modify frontmatter according to configuration."""
        frontmatter, body = self.extract_frontmatter(content)

        if not frontmatter:
            return TransformResult(content=content, success=True)

        # Apply field mapping
        for old_name, new_name in self.field_mapping.items():
            if old_name in frontmatter:
                frontmatter[new_name] = frontmatter.pop(old_name)

        # Remove fields
        for field in self.remove_fields:
            frontmatter.pop(field, None)

        # Add fields
        frontmatter.update(self.add_fields)

        # Rebuild content
        new_content = self.create_frontmatter(frontmatter) + "\n" + body

        return TransformResult(content=new_content, success=True)
