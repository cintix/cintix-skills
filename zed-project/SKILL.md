---
description: Set up a project for Zed editor — auto-detects language and creates the right LSP/config files for Java, .NET/C#, PHP, C++, or PlatformIO/Arduino
argument-hint: [language]
arguments: language
---

This skill inspects a project and creates the files Zed needs for language server support: project descriptors, formatter config, and LSP hints. It auto-detects the language from the project contents unless `$language` is explicitly given.

## How it works

1. **Detect** the project language(s) from files on disk
2. **Inspect** sources, dependencies, and toolchain
3. **Generate** the appropriate config files for that ecosystem
4. **Validate** that everything resolves
5. **Report** what was created and any problems found

---

## Language detection (when `$language` is empty)

Scan the project root for these signals, in order. A project can match more than one — polyglot projects get all matching configs.

| Signal | Language |
|---|---|
| `*.java`, `build.xml` (Ant), `pom.xml` (Maven), `build.gradle` | **Java** |
| `*.cs`, `*.csproj`, `*.sln`, `*.csx` | **.NET / C#** |
| `*.php`, `composer.json` | **PHP** |
| `*.cpp`, `*.cc`, `*.cxx`, `*.c`, `*.h`, `*.hpp`, `CMakeLists.txt`, `Makefile` (with C++ targets), `compile_commands.json` | **C++** |
| `platformio.ini`, `*.ino` | **PlatformIO / Arduino** |

If unsure, ask the user which language(s) they want configured.

---

## Java

Do NOT configure if `pom.xml` or `build.gradle` exists — those build systems already provide full JDTLS support. Only configure for Ant-based or buildless Java projects.

### Inspect
1. Source roots — from `build.xml` `<javac srcdir="...">` or scan `src/`, `src/main/java/`, `tests/`.
2. JAR dependencies — scan `lib/` or the path in `build.xml` `<fileset dir="...">`.
3. JDK — `java -version` and `readlink -f $(which java)`.
4. Output dir — prefer existing `bin/`, else use `bin/`.

### Generate

**.project**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<projectDescription>
	<name>PROJECT_NAME</name>
	<comment></comment>
	<projects>
	</projects>
	<buildSpec>
		<buildCommand>
			<name>org.eclipse.jdt.core.javabuilder</name>
			<arguments>
			</arguments>
		</buildCommand>
	</buildSpec>
	<natures>
		<nature>org.eclipse.jdt.core.javanature</nature>
	</natures>
</projectDescription>
```

**.classpath**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<classpath>
	<classpathentry kind="src" path="src"/>
	<classpathentry kind="src" path="tests" output="bin-tests"/>  <!-- only if tests/ exists -->
	<classpathentry kind="con" path="org.eclipse.jdt.launching.JRE_CONTAINER"/>
	<classpathentry kind="lib" path="lib/example.jar"/>  <!-- one per JAR -->
	<classpathentry kind="output" path="bin"/>
</classpath>
```

**.settings/org.eclipse.jdt.core.prefs**:
```properties
eclipse.preferences.version=1
org.eclipse.jdt.core.compiler.codegen.targetPlatform=1.8
org.eclipse.jdt.core.compiler.compliance=1.8
org.eclipse.jdt.core.compiler.source=1.8
org.eclipse.jdt.core.formatter.lineSplit=400
org.eclipse.jdt.core.formatter.join_wrapped_lines=true
org.eclipse.jdt.core.formatter.alignment_for_arguments_in_method_invocation=0
org.eclipse.jdt.core.formatter.alignment_for_arguments_in_allocation_expression=0
org.eclipse.jdt.core.formatter.alignment_for_arguments_in_enum_constant=0
org.eclipse.jdt.core.formatter.alignment_for_arguments_in_explicit_constructor_call=0
org.eclipse.jdt.core.formatter.alignment_for_parameters_in_constructor_declaration=0
org.eclipse.jdt.core.formatter.alignment_for_parameters_in_method_declaration=0
org.eclipse.jdt.core.formatter.alignment_for_throws_clause_in_method_declaration=0
org.eclipse.jdt.core.formatter.continuation_indentation=1
org.eclipse.jdt.core.formatter.number_of_empty_lines_to_preserve=1
org.eclipse.jdt.core.formatter.tabulation.char=space
org.eclipse.jdt.core.formatter.tabulation.size=4
```
Match `targetPlatform`/`compliance`/`source` to the JDK or `build.xml` `--release` flag.

### Validate
- Every JAR in `.classpath` exists on disk.
- Grep for external imports (`com.google.*`, `org.*`, `dk.cintix.*`) and confirm the JAR providing each package is on the classpath. Flag missing ones.
- Package directories under source roots match `package` declarations.

### Rules
- **NEVER** create `org.eclipse.jdt.ui.prefs` or a formatter XML profile — those override `.settings/org.eclipse.jdt.core.prefs` and break formatting.
- **NEVER** set `alignment_for_arguments_in_method_invocation` to non-zero — it forces argument wrapping regardless of `lineSplit`.
- Do NOT create `.zed/settings.json` for Java.

---

## .NET / C#

### Inspect
1. Solution file (`*.sln`) — if exists, note it. OmniSharp uses it as the project root.
2. Project files (`*.csproj`) — these already tell OmniSharp everything about sources and dependencies. No extra project descriptor needed.
3. Check for `omnisharp.json` — if it exists, read it; if not, create it.
4. .NET SDK version — `dotnet --version` if available.

### Generate

**.editorconfig** (if not already present):
```ini
root = true

[*]
insert_final_newline = true
trim_trailing_whitespace = true
charset = utf-8
indent_style = space
indent_size = 4
tab_width = 4

[*.cs]
max_line_length = 400
dotnet_sort_system_directives_first = true
csharp_indent_case_contents = true
csharp_indent_switch_labels = true
csharp_new_line_before_open_brace = all
csharp_new_line_before_else = true
csharp_new_line_before_catch = true
csharp_new_line_before_finally = true
csharp_new_line_before_members_in_object_initializers = false
csharp_new_line_before_members_in_anonymous_types = false
```

**omnisharp.json** (create ONLY if not present):
```json
{
  "FormattingOptions": {
    "NewLine": "\\n",
    "UseTabs": false,
    "TabSize": 4,
    "IndentationSize": 4,
    "NewLinesForBracesInTypes": true,
    "NewLinesForBracesInMethods": true,
    "NewLinesForBracesInProperties": true,
    "NewLinesForBracesInAccessors": true,
    "NewLinesForBracesInAnonymousMethods": true,
    "NewLinesForBracesInControlBlocks": true,
    "NewLinesForBracesInAnonymousTypes": true,
    "NewLinesForBracesInObjectCollectionArrayInitializers": true,
    "NewLinesForBracesInLambdaExpressionBody": true,
    "NewLineForElse": true,
    "NewLineForCatch": true,
    "NewLineForFinally": true
  },
  "FileOptions": {
    "SystemExcludeSearchPatterns": ["**/node_modules/**", "**/bin/**", "**/obj/**"],
    "ExcludeSearchPatterns": []
  }
}
```

### Validate
- `dotnet restore` dry-run or check that NuGet packages are present.
- Flag any `.csproj` with missing `<PackageReference>` that source code imports.

---

## PHP

### Inspect
1. `composer.json` — if present, Intelephense uses it for autoload and dependency resolution. Run `composer install` if vendor dir is missing.
2. Source roots — typically `src/`, `app/`, `public/`, or the project root itself.
3. PHP version — `php --version` if available.

### Generate

**.editorconfig** (if not already present):
```ini
root = true

[*]
insert_final_newline = true
trim_trailing_whitespace = true
charset = utf-8
indent_style = space
indent_size = 4
tab_width = 4

[*.php]
max_line_length = 400

[*.blade.php]
indent_size = 2
```

Intelephense needs no extra project files — it reads `composer.json` directly.

### Validate
- If `composer.json` exists, check that `vendor/` exists. If not, suggest `composer install`.
- Flag any `namespace` declarations that don't match the PSR-4 autoload mapping in `composer.json`.

---

## C++

Two modes: **cmake** (generates `compile_commands.json`) and **simple** (uses `compile_flags.txt`). clangd is the default Zed LSP for C++.

### Inspect
1. Build system — `CMakeLists.txt` (cmake), `Makefile` (make), or neither (simple).
2. Source/extensions — which C++ standards are used (`--std=c++17`, etc.) from the build file.
3. Include paths — from `-I` flags in build config or common locations (`include/`, `src/`).

### Generate

**For cmake projects (`CMakeLists.txt` exists):**

Create or update **.editorconfig**:
```ini
root = true

[*]
insert_final_newline = true
trim_trailing_whitespace = true
charset = utf-8

[*.{cpp,cc,cxx,c,h,hpp}]
indent_style = space
indent_size = 4
tab_width = 4
max_line_length = 400
```

Tell the user to generate `compile_commands.json`:
```bash
cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
ln -sf build/compile_commands.json .
```

**For simple projects (no cmake):**

Create **.clangd**:
```yaml
CompileFlags:
  Add:
    - --std=c++17
    - -Iinclude
    - -Isrc
  Remove:
    - -m*
```

Create **compile_flags.txt** (clangd fallback, one flag per line):
```
--std=c++17
-Iinclude
-Isrc
```

Also create the **.editorconfig** as shown above.

Adjust the standard flag (`--std=c++17`) and include paths based on what's found in the project.

### Validate
- Check that include paths in `.clangd` or `compile_flags.txt` point to existing directories.
- Flag any `#include` directives referencing headers not found under those paths.

---

## PlatformIO / Arduino

PlatformIO projects have a `platformio.ini` at the root. Zed uses clangd for C++ code intelligence on these projects.

### Inspect
1. `platformio.ini` — read it. Extract `board`, `framework`, `platform`, and `lib_deps`.
2. Source dirs — typically `src/` and `lib/`. Some projects also have `include/`.
3. Check if `compile_commands.json` already exists in the project root.

### Generate

Create or update **.editorconfig**:
```ini
root = true

[*]
insert_final_newline = true
trim_trailing_whitespace = true
charset = utf-8

[*.{cpp,cc,cxx,c,h,hpp,ino}]
indent_style = space
indent_size = 4
tab_width = 4
max_line_length = 400
```

Create **.clangd** (tells clangd to use PlatformIO's compile_commands):
```yaml
CompileFlags:
  CompilationDatabase: .pio/build/PLATFORMIO_ENV/
```

Replace `PLATFORMIO_ENV` with the actual environment name from `platformio.ini` (the first `[env:...]` section).

Tell the user to generate the compilation database:
```bash
pio run -t compiledb
```
Or for newer PlatformIO:
```bash
pio project init
pio run
```
The `compile_commands.json` will be placed in `.pio/build/<env>/` and `.clangd` points to it.

If PlatformIO CLI is not installed, suggest: `pip install platformio`

### Validate
- `platformio.ini` is parseable and has at least one `[env:...]` section.
- The source directory (`src/`) exists with `.cpp` or `.ino` files.
- Flag if `lib/` folder is referenced but doesn't exist.

---

## Polyglot projects

When a project contains multiple languages, generate the configs for ALL detected languages. The `.editorconfig` should have sections for every language, merged into a single file:

```ini
root = true

[*]
insert_final_newline = true
trim_trailing_whitespace = true
charset = utf-8

[*.java]
indent_size = 4
max_line_length = 400

[*.php]
indent_size = 4
max_line_length = 400

[*.{cpp,hpp,ino}]
indent_size = 4
max_line_length = 400

[*.cs]
indent_size = 4
max_line_length = 400
```

---

## Final report

After generating everything, show:

| What | Detail |
|---|---|
| Detected languages | Java, PHP, etc. |
| Source roots | `src/` (12 files), `tests/` (3 files) |
| Build system | Ant, CMake, Composer, PlatformIO, etc. |
| Toolchain | JDK 25, .NET 9, PHP 8.3, g++ 14, etc. |
| Files created | `.project`, `.classpath`, `.editorconfig`, `.clangd`, etc. |
| Issues found | Missing JARs, unresolved includes, etc. |

End with: **"Genstart Zed eller kør `zed: restart language server` for at ændringerne slår igennem."**
