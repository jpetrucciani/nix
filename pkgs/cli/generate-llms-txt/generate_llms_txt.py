#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Generate ``llms.txt`` and ``llms-full.txt`` from Python docstrings.

This is a portable, standard-library-only documentation generator intended to
be shared by multiple Python repositories. It reads source files with
``ast.parse`` and never imports the target package, so unresolved native
libraries, service credentials, and import-time side effects are harmless.

Requirements
------------

* Python 3.11 or newer.
* `uv <https://docs.astral.sh/uv/>`_ when executing this file directly through
  its shebang. There are no third-party Python dependencies.
* A package source directory and its import name.

Basic usage
-----------

Generate an index directly into an already-built documentation site::

    ./generate_llms.py src/widget_tools \
        --package widget_tools \
        --project widget-tools \
        --summary "Widget construction and inspection helpers." \
        --base-url /docs/widget-tools \
        --out-dir docs/build/html \
        --url-template "{base}/api/{qualname}.html"

Include reviewed usage examples from a repository-local snapshot::

    ./generate_llms.py src/widget_tools \
        --package widget_tools \
        --project widget-tools \
        --summary "Widget construction and inspection helpers." \
        --base-url /docs/widget-tools \
        --usage docs/usage_examples.json \
        --out-dir docs/build/html \
        --url-template "{base}/api/{qualname}.html" \
        --max-examples 2

The URL template accepts ``{base}``, ``{qualname}``, ``{module}``, and
``{path}``. ``path`` is the module name with dots replaced by slashes. Relative
URLs are valid, so a site-root index can use a template such as
``api/{qualname}.html``.

Usage snapshot
--------------

Usage mining is intentionally separate from documentation generation. Mining a
large examples corpus can be slow and may require data unavailable in CI. Commit
a reviewed, portable snapshot with this shape instead::

    {
      "schema_version": 1,
      "generated_at": "2026-09-04T18:30:00Z",
      "source": {
        "name": "examples-repository",
        "revision": "0123456789abcdef",
        "files_scanned": 22641
      },
      "generator": {
        "name": "python-docstrings/mine.py",
        "selection": "reviewed representative examples"
      },
      "usage": {
        "widget_tools.load_widget": {
          "call_count": 12,
          "file_count": 7,
          "examples": [
            {"snippet": "widget = load_widget(path, strict=True)"}
          ]
        }
      }
    }

Every snippet is parsed as standalone Python. Duplicate snippets, invalid
counts, malformed records, and records for API objects no longer present in the
source tree are rejected. Metadata is retained for provenance but is not copied
into the generated API text.

Nix integration
---------------

Package this file once in shared Nix tooling, then keep project-specific flags
and usage snapshots in each consuming repository. For example::

    generate_llms = writeBashBin "generate_llms" ''
      ${generateLlms}/bin/generate-llms src/widget_tools \\
        --package widget_tools \\
        --project widget-tools \\
        --summary "Widget construction and inspection helpers." \\
        --usage docs/usage_examples.json \\
        --out-dir docs/build/html \\
        --url-template "api/{qualname}.html"
    '';

Run the generator after Sphinx when writing directly into ``docs/build/html``.
Alternatively, generate before Sphinx into a directory listed by
``html_extra_path``. Generated ``llms*.txt`` files should normally be ignored;
the reviewed usage snapshot is a build input and should normally be committed.
"""

from __future__ import annotations

import argparse
import ast
import json
import os
import tempfile
import warnings
from collections.abc import Sequence
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Literal, NoReturn

GENERATOR_VERSION = "1.0.0"
ObjectKind = Literal["class", "function", "method"]
DefinitionNode = ast.ClassDef | ast.FunctionDef | ast.AsyncFunctionDef
FunctionNode = ast.FunctionDef | ast.AsyncFunctionDef


class GenerationError(ValueError):
    """Report invalid source, configuration, or usage-snapshot data."""


@dataclass(frozen=True)
class ApiObject:
    """Describe one generated API object.

    Attributes:
        qualname: Fully qualified Python name.
        kind: Definition kind used for validation and reporting.
        signature: Source-derived signature, empty for classes.
        docstring: Cleaned source docstring.
        decorators: Source-like decorator names in declaration order.
    """

    qualname: str
    kind: ObjectKind
    signature: str
    docstring: str
    decorators: tuple[str, ...]


@dataclass(frozen=True)
class ApiModule:
    """Describe a package module and its generated objects.

    Attributes:
        qualname: Fully qualified module name.
        docstring: Cleaned module docstring.
        objects: Public objects in source order.
    """

    qualname: str
    docstring: str
    objects: tuple[ApiObject, ...]


@dataclass(frozen=True)
class UsageRecord:
    """Store selected usage examples for one API object.

    Attributes:
        call_count: Number of calls observed by the source miner.
        file_count: Number of source files containing those calls, when known.
        examples: Deduplicated, syntax-valid snippets in review order.
    """

    call_count: int
    file_count: int | None
    examples: tuple[str, ...]


@dataclass(frozen=True)
class UsageSnapshot:
    """Store validated usage records and optional provenance.

    Attributes:
        records: Usage evidence keyed by fully qualified API name.
        generated_at: UTC snapshot timestamp when supplied.
        source_revision: Source-corpus revision when supplied.
    """

    records: dict[str, UsageRecord]
    generated_at: str | None = None
    source_revision: str | None = None


@dataclass(frozen=True)
class Configuration:
    """Store validated command-line configuration.

    Attributes:
        source: Package source directory.
        package: Import name represented by ``source``.
        project: Heading used in generated files.
        summary: One-line project description.
        base_url: Documentation URL available to the link template.
        output_directory: Destination for both generated files.
        url_template: Module documentation URL template.
        full_url: Link from ``llms.txt`` to ``llms-full.txt``.
        usage_path: Optional reviewed usage snapshot.
        max_examples: Maximum selected examples rendered per object.
        include_private: Whether conventionally private definitions are emitted.
    """

    source: Path
    package: str
    project: str
    summary: str
    base_url: str
    output_directory: Path
    url_template: str
    full_url: str
    usage_path: Path | None
    max_examples: int
    include_private: bool


@dataclass(frozen=True)
class GenerationResult:
    """Describe generated files and their record counts.

    Attributes:
        index_path: Generated ``llms.txt`` path.
        full_path: Generated ``llms-full.txt`` path.
        module_count: Number of emitted modules.
        object_count: Number of emitted API objects.
        usage_object_count: Number of objects with selected usage examples.
        usage_example_count: Number of selected examples rendered.
    """

    index_path: Path
    full_path: Path
    module_count: int
    object_count: int
    usage_object_count: int
    usage_example_count: int


def is_public(name: str) -> bool:
    """Return whether a Python name is conventionally public.

    Args:
        name: Unqualified Python definition name.

    Returns:
        Whether the name is public or a double-underscore protocol method.
    """
    return not name.startswith("_") or (name.startswith("__") and name.endswith("__"))


def unparse(node: ast.AST) -> str:
    """Render an AST node as Python source.

    Args:
        node: Parsed Python syntax node.

    Returns:
        Normalized source representation.
    """
    return ast.unparse(node)


def parse_python(source: str, filename: str) -> ast.Module:
    """Parse Python while leaving source-code linting to the caller's linter.

    ``ast.parse`` can emit ``SyntaxWarning`` for valid legacy source, such as
    non-raw regular-expression strings. Those warnings do not affect static API
    extraction and would otherwise make documentation builds noisy.

    Args:
        source: Python source text.
        filename: Context included in syntax errors.

    Returns:
        Parsed module tree.
    """
    with warnings.catch_warnings():
        warnings.simplefilter("ignore", SyntaxWarning)
        return ast.parse(source, filename=filename)


def render_argument(
    argument: ast.arg,
    default: ast.expr | None = None,
    prefix: str = "",
) -> str:
    """Render one function argument.

    Args:
        argument: Parsed argument definition.
        default: Optional default-value expression.
        prefix: Positional marker such as ``*`` or ``**``.

    Returns:
        Python-like argument text including annotation and default.
    """
    rendered = prefix + argument.arg
    if argument.annotation is not None:
        rendered += f": {unparse(argument.annotation)}"
    if default is not None:
        separator = " = " if argument.annotation is not None else "="
        rendered += separator + unparse(default)
    return rendered


def format_signature(node: FunctionNode) -> str:
    """Render a function signature without importing its module.

    Args:
        node: Parsed function or asynchronous-function definition.

    Returns:
        Parenthesized signature with annotations and return type.
    """
    arguments = node.args
    rendered: list[str] = []
    positional = [*arguments.posonlyargs, *arguments.args]
    defaults: list[ast.expr | None] = [None] * (
        len(positional) - len(arguments.defaults)
    ) + list(arguments.defaults)

    for index, (argument, default) in enumerate(zip(positional, defaults, strict=True)):
        rendered.append(render_argument(argument, default))
        if arguments.posonlyargs and index == len(arguments.posonlyargs) - 1:
            rendered.append("/")

    if arguments.vararg is not None:
        rendered.append(render_argument(arguments.vararg, prefix="*"))
    elif arguments.kwonlyargs:
        rendered.append("*")

    for argument, default in zip(
        arguments.kwonlyargs, arguments.kw_defaults, strict=True
    ):
        rendered.append(render_argument(argument, default))

    if arguments.kwarg is not None:
        rendered.append(render_argument(arguments.kwarg, prefix="**"))

    return_annotation = (
        f" -> {unparse(node.returns)}" if node.returns is not None else ""
    )
    return f"({', '.join(rendered)}){return_annotation}"


def decorator_names(node: DefinitionNode) -> tuple[str, ...]:
    """Return source-like names for a definition's decorators.

    Args:
        node: Parsed class or function definition.

    Returns:
        Decorator names in source order, without leading ``@`` characters.
    """
    names: list[str] = []
    for decorator in node.decorator_list:
        target = decorator.func if isinstance(decorator, ast.Call) else decorator
        names.append(unparse(target))
    return tuple(names)


def module_exports(tree: ast.Module) -> set[str] | None:
    """Return the literal contents of a module's ``__all__``.

    Dynamic declarations cannot be resolved safely without importing the module,
    so they fall back to conventional underscore visibility.

    Args:
        tree: Parsed module.

    Returns:
        Literal exported names, or ``None`` when no static declaration is found.
    """
    for node in tree.body:
        if isinstance(node, ast.Assign):
            targets = node.targets
            value = node.value
        elif isinstance(node, ast.AnnAssign):
            targets = [node.target]
            value = node.value
        else:
            continue
        if not any(
            isinstance(target, ast.Name) and target.id == "__all__"
            for target in targets
        ):
            continue
        if not isinstance(value, (ast.List, ast.Tuple, ast.Set)):
            return None
        return {
            element.value
            for element in value.elts
            if isinstance(element, ast.Constant) and isinstance(element.value, str)
        }
    return None


def should_include(
    name: str,
    exports: set[str] | None,
    include_private: bool,
) -> bool:
    """Return whether a top-level definition belongs in the output.

    Args:
        name: Source-level definition name.
        exports: Static ``__all__`` contents when present.
        include_private: Whether underscore-prefixed definitions are requested.

    Returns:
        Whether the definition should be emitted.
    """
    if exports is not None:
        return name in exports
    return include_private or is_public(name)


def get_module_name(path: Path, source: Path, package: str) -> str:
    """Build the import name represented by a source path.

    Args:
        path: Python file below ``source``.
        source: Directory corresponding exactly to ``package``.
        package: Import name represented by ``source``.

    Returns:
        Fully qualified module name.
    """
    relative = path.relative_to(source).with_suffix("")
    parts = list(relative.parts)
    if parts and parts[-1] == "__init__":
        parts.pop()
    return ".".join([package, *parts])


def make_api_object(node: DefinitionNode, qualname: str, kind: ObjectKind) -> ApiObject:
    """Build a generated API record from a definition.

    Args:
        node: Parsed class or function definition.
        qualname: Fully qualified Python name.
        kind: Definition kind used for reporting.

    Returns:
        Immutable API record.
    """
    signature = ""
    if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
        signature = format_signature(node)
    return ApiObject(
        qualname=qualname,
        kind=kind,
        signature=signature,
        docstring=ast.get_docstring(node, clean=True) or "",
        decorators=decorator_names(node),
    )


def parse_module(path: Path) -> ast.Module:
    """Parse a Python source file with a contextual error.

    Args:
        path: Python source file.

    Raises:
        GenerationError: The file cannot be decoded or parsed.

    Returns:
        Parsed module tree.
    """
    try:
        source = path.read_text(encoding="utf-8")
        return parse_python(source, filename=str(path))
    except (OSError, SyntaxError, UnicodeError) as error:
        raise GenerationError(f"cannot parse {path}: {error}") from error


def collect_modules(
    source: Path,
    package: str,
    include_private: bool = False,
) -> tuple[ApiModule, ...]:
    """Collect API modules and definitions from a package tree.

    Args:
        source: Directory corresponding exactly to ``package``.
        package: Import name represented by ``source``.
        include_private: Whether underscore-prefixed objects should be emitted.

    Raises:
        GenerationError: The source is not a directory or a file cannot be
            parsed.

    Returns:
        Modules ordered by name, with definitions in source order.
    """
    if not source.is_dir():
        raise GenerationError(f"package source directory does not exist: {source}")

    modules: list[ApiModule] = []
    for path in sorted(source.rglob("*.py")):
        if "__pycache__" in path.parts:
            continue
        tree = parse_module(path)
        module_name = get_module_name(path, source, package)
        exports = module_exports(tree)
        objects: list[ApiObject] = []

        for node in tree.body:
            if isinstance(node, ast.ClassDef) and should_include(
                node.name, exports, include_private
            ):
                class_name = f"{module_name}.{node.name}"
                objects.append(make_api_object(node, class_name, "class"))
                for child in node.body:
                    if not isinstance(child, (ast.FunctionDef, ast.AsyncFunctionDef)):
                        continue
                    if not (
                        include_private
                        or is_public(child.name)
                        or child.name == "__init__"
                    ):
                        continue
                    objects.append(
                        make_api_object(child, f"{class_name}.{child.name}", "method")
                    )
            elif isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)) and (
                should_include(node.name, exports, include_private)
            ):
                objects.append(
                    make_api_object(node, f"{module_name}.{node.name}", "function")
                )

        module_docstring = ast.get_docstring(tree, clean=True) or ""
        if objects or module_docstring:
            modules.append(
                ApiModule(
                    qualname=module_name,
                    docstring=module_docstring,
                    objects=tuple(objects),
                )
            )
    return tuple(sorted(modules, key=lambda module: module.qualname))


def require_mapping(value: object, description: str) -> dict[str, object]:
    """Validate a JSON object with string keys.

    Args:
        value: Decoded JSON value.
        description: Human-readable location used in errors.

    Raises:
        GenerationError: The value is not an object with string keys.

    Returns:
        Validated mapping.
    """
    if not isinstance(value, dict):
        raise GenerationError(f"{description} must be a JSON object")
    result: dict[str, object] = {}
    for key, item in value.items():
        if not isinstance(key, str):
            raise GenerationError(f"{description} must be a JSON object")
        result[key] = item
    return result


def require_nonnegative_integer(value: object, description: str) -> int:
    """Validate a nonnegative JSON integer.

    Args:
        value: Decoded JSON value.
        description: Human-readable location used in errors.

    Raises:
        GenerationError: The value is a boolean, non-integer, or negative.

    Returns:
        Validated integer.
    """
    if isinstance(value, bool) or not isinstance(value, int) or value < 0:
        raise GenerationError(f"{description} must be a nonnegative integer")
    return value


def optional_string(mapping: dict[str, object], key: str) -> str | None:
    """Read an optional string from a JSON mapping.

    Args:
        mapping: Decoded JSON object.
        key: Field name to read.

    Raises:
        GenerationError: The supplied field is not a string.

    Returns:
        Field value, or ``None`` when absent.
    """
    value = mapping.get(key)
    if value is None:
        return None
    if not isinstance(value, str):
        raise GenerationError(f"{key} must be a string")
    return value


def validate_timestamp(value: str | None) -> str | None:
    """Validate an optional timezone-aware ISO 8601 timestamp.

    Args:
        value: Timestamp string, or ``None``.

    Raises:
        GenerationError: The value is not ISO 8601 or lacks a timezone.

    Returns:
        Original timestamp string when valid.
    """
    if value is None:
        return None
    try:
        parsed = datetime.fromisoformat(value)
    except ValueError as error:
        raise GenerationError("generated_at must be an ISO 8601 timestamp") from error
    if parsed.tzinfo is None:
        raise GenerationError("generated_at must include a timezone")
    return value


def source_revision(document: dict[str, object]) -> str | None:
    """Read an optional source revision from snapshot metadata.

    Args:
        document: Decoded usage-snapshot document.

    Raises:
        GenerationError: Source metadata or its revision is malformed.

    Returns:
        Source revision, or ``None`` when unavailable.
    """
    source = document.get("source")
    if source is None or isinstance(source, str):
        return None
    source_mapping = require_mapping(source, "source")
    return optional_string(source_mapping, "revision")


def validate_snippet(snippet: object, qualname: str) -> str:
    """Validate a standalone usage-example snippet.

    Args:
        snippet: Decoded snippet value.
        qualname: API object associated with the example.

    Raises:
        GenerationError: The snippet is empty or invalid Python.

    Returns:
        Validated snippet text.
    """
    if not isinstance(snippet, str) or not snippet.strip():
        raise GenerationError(f"example for {qualname} must contain a snippet")
    try:
        parse_python(snippet, filename=f"<usage:{qualname}>")
    except SyntaxError as error:
        raise GenerationError(
            f"example for {qualname} must be standalone valid Python: {error}"
        ) from error
    return snippet


def load_usage(path: Path | None) -> UsageSnapshot:
    """Load and validate an optional usage-example snapshot.

    Args:
        path: Snapshot JSON path, or ``None`` to omit usage examples.

    Raises:
        GenerationError: The file cannot be decoded or violates the schema.

    Returns:
        Validated usage records and provenance.
    """
    if path is None:
        return UsageSnapshot(records={})
    try:
        raw_document: object = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise GenerationError(f"cannot load usage snapshot {path}: {error}") from error

    document = require_mapping(raw_document, "usage snapshot")
    schema_version = document.get("schema_version")
    if schema_version is not None and schema_version != 1:
        raise GenerationError("usage snapshot schema_version must be 1")
    generated_at = validate_timestamp(optional_string(document, "generated_at"))
    revision = source_revision(document)
    raw_usage = require_mapping(document.get("usage"), "usage")

    records: dict[str, UsageRecord] = {}
    for qualname, raw_record in raw_usage.items():
        record = require_mapping(raw_record, f"usage record for {qualname}")
        call_count = require_nonnegative_integer(
            record.get("call_count"), f"call_count for {qualname}"
        )
        raw_file_count = record.get("file_count")
        file_count = (
            None
            if raw_file_count is None
            else require_nonnegative_integer(
                raw_file_count, f"file_count for {qualname}"
            )
        )
        if file_count is not None and file_count > call_count:
            raise GenerationError(f"file_count for {qualname} cannot exceed call_count")
        raw_examples = record.get("examples")
        if not isinstance(raw_examples, list):
            raise GenerationError(f"examples for {qualname} must be a JSON array")

        examples: list[str] = []
        seen: set[str] = set()
        for index, raw_example in enumerate(raw_examples):
            example = require_mapping(raw_example, f"example {index} for {qualname}")
            snippet = validate_snippet(example.get("snippet"), qualname)
            if snippet in seen:
                raise GenerationError(f"duplicate usage example for {qualname}")
            seen.add(snippet)
            examples.append(snippet)
        if examples and call_count == 0:
            raise GenerationError(
                f"call_count for {qualname} must be positive when examples exist"
            )
        records[qualname] = UsageRecord(
            call_count=call_count,
            file_count=file_count,
            examples=tuple(examples),
        )
    return UsageSnapshot(
        records=records,
        generated_at=generated_at,
        source_revision=revision,
    )


def validate_usage_targets(
    modules: tuple[ApiModule, ...], snapshot: UsageSnapshot
) -> None:
    """Reject usage records for objects absent from the generated API.

    Args:
        modules: Collected API modules.
        snapshot: Validated usage snapshot.

    Raises:
        GenerationError: One or more usage names are stale or misspelled.
    """
    public_names = {
        api_object.qualname for module in modules for api_object in module.objects
    }
    stale_names = sorted(snapshot.records.keys() - public_names)
    if stale_names:
        raise GenerationError(
            "usage snapshot references unknown API objects: " + ", ".join(stale_names)
        )


def first_line(docstring: str) -> str:
    """Return the first nonempty docstring line.

    Args:
        docstring: Cleaned Python docstring.

    Returns:
        Summary line, or an empty string for an empty docstring.
    """
    return next((line.strip() for line in docstring.splitlines() if line.strip()), "")


def module_url(module: ApiModule, config: Configuration) -> str:
    """Render a module documentation URL from configuration.

    Args:
        module: Module being linked.
        config: Generator configuration.

    Raises:
        GenerationError: The template contains an unsupported placeholder.

    Returns:
        Rendered module URL.
    """
    try:
        return config.url_template.format(
            base=config.base_url.rstrip("/"),
            qualname=module.qualname,
            module=module.qualname,
            path=module.qualname.replace(".", "/"),
        )
    except (AttributeError, IndexError, KeyError, ValueError) as error:
        raise GenerationError(f"invalid URL template: {error}") from error


def render_index(modules: tuple[ApiModule, ...], config: Configuration) -> str:
    """Render the concise module index.

    Args:
        modules: Collected API modules.
        config: Generator configuration.

    Returns:
        Markdown contents for ``llms.txt``.
    """
    lines = [
        f"# {config.project}",
        "",
        f"> {config.summary}",
        "",
        "## API reference",
        "",
    ]
    for module in modules:
        description = first_line(module.docstring)
        suffix = f": {description}" if description else ""
        lines.append(f"- [{module.qualname}]({module_url(module, config)}){suffix}")
    lines.extend(
        [
            "",
            "## Optional",
            "",
            (
                f"- [Full API text]({config.full_url}): every generated public "
                "signature, docstring, and selected usage example"
            ),
        ]
    )
    return "\n".join(lines) + "\n"


def usage_heading(record: UsageRecord) -> str:
    """Render an observed-call summary for a usage record.

    Args:
        record: Validated usage record.

    Returns:
        Human-readable call and file counts.
    """
    call_noun = "call site" if record.call_count == 1 else "call sites"
    heading = f"Selected examples from {record.call_count} observed {call_noun}"
    if record.file_count is not None:
        file_noun = "file" if record.file_count == 1 else "files"
        heading += f" in {record.file_count} {file_noun}"
    return heading + ":"


def render_full(
    modules: tuple[ApiModule, ...],
    snapshot: UsageSnapshot,
    config: Configuration,
) -> str:
    """Render the complete API document.

    Args:
        modules: Collected API modules.
        snapshot: Validated usage snapshot.
        config: Generator configuration.

    Returns:
        Markdown contents for ``llms-full.txt``.
    """
    provenance = "Generated from source docstrings. Signatures are authoritative."
    if snapshot.records:
        provenance = (
            "Generated from source docstrings and selected usage evidence. "
            "Signatures are authoritative."
        )
    lines = [f"# {config.project}", "", f"> {config.summary}", "", provenance, ""]

    for module in modules:
        lines.extend([f"## {module.qualname}", ""])
        if module.docstring:
            lines.extend([module.docstring.strip(), ""])
        for api_object in module.objects:
            lines.extend([f"### `{api_object.qualname}{api_object.signature}`", ""])
            if api_object.decorators:
                decorators = ", ".join(
                    f"`@{decorator}`" for decorator in api_object.decorators
                )
                lines.extend([f"Decorators: {decorators}", ""])
            lines.extend([api_object.docstring.strip() or "_No docstring._", ""])

            usage = snapshot.records.get(api_object.qualname)
            if usage is None or not usage.examples:
                continue
            lines.extend([usage_heading(usage), ""])
            for snippet in usage.examples[: config.max_examples]:
                lines.extend(["```python", snippet, "```", ""])
    return "\n".join(lines) + "\n"


def write_text_atomic(path: Path, content: str) -> None:
    """Replace a generated text file atomically.

    Args:
        path: Destination path.
        content: Complete UTF-8 file contents.
    """
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(
        dir=path.parent,
        prefix=f".{path.name}.",
        suffix=".tmp",
        text=True,
    )
    temporary_path = Path(temporary_name)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8", newline="\n") as handle:
            handle.write(content)
        temporary_path.replace(path)
    except BaseException:
        temporary_path.unlink(missing_ok=True)
        raise


def generate(config: Configuration) -> GenerationResult:
    """Generate both LLM-facing documentation files.

    Args:
        config: Validated generator configuration.

    Raises:
        GenerationError: Source, snapshot, or URL configuration is invalid.

    Returns:
        Generated paths and record counts.
    """
    modules = collect_modules(config.source, config.package, config.include_private)
    if not modules:
        raise GenerationError(
            f"no documented Python modules found below package source: {config.source}"
        )
    snapshot = load_usage(config.usage_path)
    validate_usage_targets(modules, snapshot)

    index_path = config.output_directory / "llms.txt"
    full_path = config.output_directory / "llms-full.txt"
    write_text_atomic(index_path, render_index(modules, config))
    write_text_atomic(full_path, render_full(modules, snapshot, config))

    object_count = sum(len(module.objects) for module in modules)
    usage_records = [
        snapshot.records[api_object.qualname]
        for module in modules
        for api_object in module.objects
        if api_object.qualname in snapshot.records
        and snapshot.records[api_object.qualname].examples
    ]
    return GenerationResult(
        index_path=index_path,
        full_path=full_path,
        module_count=len(modules),
        object_count=object_count,
        usage_object_count=len(usage_records),
        usage_example_count=sum(
            min(len(record.examples), config.max_examples) for record in usage_records
        ),
    )


def positive_integer(value: str) -> int:
    """Parse a positive command-line integer.

    Args:
        value: Raw command-line value.

    Raises:
        argparse.ArgumentTypeError: The value is not a positive integer.

    Returns:
        Parsed integer.
    """
    try:
        parsed = int(value)
    except ValueError as error:
        raise argparse.ArgumentTypeError("must be an integer") from error
    if parsed < 1:
        raise argparse.ArgumentTypeError("must be at least 1")
    return parsed


def build_parser() -> argparse.ArgumentParser:
    """Build the command-line parser.

    Returns:
        Configured argument parser.
    """
    parser = argparse.ArgumentParser(
        description="Generate llms.txt and llms-full.txt from Python docstrings.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""examples:
  generate-llms src/pkg --package pkg --project pkg \\
    --summary "Package summary." --out-dir docs/build/html

  generate-llms src/widget_tools --package widget_tools --project widget-tools \\
    --summary "Widget helpers." --base-url /docs/widget-tools \\
    --usage docs/usage_examples.json --out-dir docs/build/html \\
    --url-template "{base}/api/{qualname}.html"
""",
    )
    parser.add_argument("source", type=Path, help="package source directory")
    parser.add_argument(
        "--package", required=True, help="import name represented by source"
    )
    parser.add_argument("--project", required=True, help="generated document title")
    parser.add_argument("--summary", required=True, help="one-line project description")
    parser.add_argument(
        "--base-url", default=".", help="documentation base URL, default: ."
    )
    parser.add_argument(
        "--out-dir",
        required=True,
        type=Path,
        help="directory receiving llms.txt and llms-full.txt",
    )
    parser.add_argument(
        "--url-template",
        default="{base}/api/{qualname}.html",
        help=("module URL template using {base}, {qualname}, {module}, or {path}"),
    )
    parser.add_argument(
        "--full-url",
        default="./llms-full.txt",
        help="llms-full.txt URL written into llms.txt",
    )
    parser.add_argument(
        "--usage", type=Path, help="optional reviewed usage-snapshot JSON"
    )
    parser.add_argument(
        "--max-examples",
        type=positive_integer,
        default=2,
        help="maximum usage snippets per API object, default: 2",
    )
    parser.add_argument(
        "--include-private",
        action="store_true",
        help="include conventionally private definitions",
    )
    parser.add_argument(
        "--version", action="version", version=f"%(prog)s {GENERATOR_VERSION}"
    )
    return parser


def parse_configuration(
    parser: argparse.ArgumentParser, argv: Sequence[str] | None = None
) -> Configuration:
    """Parse command-line arguments into an immutable configuration.

    Args:
        parser: Configured argument parser.
        argv: Optional arguments excluding the executable name.

    Returns:
        Immutable generator configuration.
    """
    args = parser.parse_args(argv)
    return Configuration(
        source=args.source,
        package=args.package,
        project=args.project,
        summary=args.summary,
        base_url=args.base_url,
        output_directory=args.out_dir,
        url_template=args.url_template,
        full_url=args.full_url,
        usage_path=args.usage,
        max_examples=args.max_examples,
        include_private=args.include_private,
    )


def fail(parser: argparse.ArgumentParser, error: Exception) -> NoReturn:
    """Terminate the CLI with a concise generator error.

    Args:
        parser: Command-line parser used to report the error.
        error: Generation failure.
    """
    parser.error(str(error))


def main(argv: Sequence[str] | None = None) -> int:
    """Run the command-line generator.

    Args:
        argv: Optional arguments excluding the executable name.

    Returns:
        Successful process exit status.
    """
    parser = build_parser()
    config = parse_configuration(parser, argv)
    try:
        result = generate(config)
    except (GenerationError, OSError) as error:
        fail(parser, error)

    print(
        f"generated {result.index_path} and {result.full_path} from "
        f"{result.module_count} modules and {result.object_count} objects; "
        f"rendered {result.usage_example_count} selected examples for "
        f"{result.usage_object_count} objects"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
