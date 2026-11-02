#!/usr/bin/env bash
#
# Validate Claude Code skill definitions in this repository.
#
# Checks each */SKILL.md for:
#   - YAML frontmatter delimited by ---
#   - a name matching the skill directory and the allowed character set
#   - a non-empty description of at most 1024 characters
#   - every references/... path mentioned in SKILL.md existing on disk
#
# Usage: ./scripts/validate-skills.sh
# Exit code: 0 when every skill passes, 1 otherwise.

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
errors=0
warnings=0
checked=0

fail() {
    printf '  FAIL: %s\n' "$1"
    errors=$((errors + 1))
}

warn() {
    printf '  WARN: %s\n' "$1"
    warnings=$((warnings + 1))
}

shopt -s nullglob

for skill_dir in "$root"/*/; do
    skill_dir="${skill_dir%/}"
    file="$skill_dir/SKILL.md"
    [ -f "$file" ] || continue

    checked=$((checked + 1))
    dir_name="$(basename "$skill_dir")"
    printf '%s\n' "$dir_name"

    if [ "$(head -n 1 "$file")" != "---" ]; then
        fail "SKILL.md must start with YAML frontmatter (---)"
        continue
    fi

    frontmatter="$(awk 'NR == 1 && $0 == "---" { inside = 1; next }
                        inside && $0 == "---" { exit }
                        inside { print }' "$file")"

    if [ -z "$frontmatter" ]; then
        fail "frontmatter block is empty"
        continue
    fi

    name="$(printf '%s\n' "$frontmatter" | sed -n 's/^name:[[:space:]]*//p' | head -n 1)"
    description="$(printf '%s\n' "$frontmatter" | sed -n 's/^description:[[:space:]]*//p' | head -n 1)"

    name="${name%\"}"; name="${name#\"}"
    name="${name%\'}"; name="${name#\'}"
    description="${description%\"}"; description="${description#\"}"
    description="${description%\'}"; description="${description#\'}"

    if [ -z "$name" ]; then
        fail "frontmatter is missing 'name'"
    else
        if [ "$name" != "$dir_name" ]; then
            fail "name '$name' does not match directory '$dir_name'"
        fi
        if ! printf '%s' "$name" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$'; then
            fail "name '$name' must use lowercase letters, digits, and single hyphens"
        fi
        if [ "${#name}" -gt 64 ]; then
            fail "name '$name' exceeds 64 characters"
        fi
    fi

    if [ -z "$description" ]; then
        fail "frontmatter is missing 'description'"
    elif [ "${#description}" -gt 1024 ]; then
        fail "description is ${#description} characters (limit: 1024)"
    elif [ "${#description}" -lt 20 ]; then
        warn "description is very short; make the trigger conditions explicit"
    fi

    line_count="$(wc -l < "$file")"
    if [ "$line_count" -gt 500 ]; then
        warn "SKILL.md is $line_count lines; move detail into references/ (progressive disclosure)"
    fi

    # Every references/... path mentioned must exist.
    while IFS= read -r ref; do
        [ -n "$ref" ] || continue
        if [ ! -f "$skill_dir/$ref" ]; then
            fail "referenced file is missing: $ref"
        fi
    done < <(grep -oE 'references/[A-Za-z0-9._/-]+' "$file" | sed 's/[.,;:)]*$//' | sort -u)

    printf '  ok\n'
done

printf '\n%s skill(s) checked, %s error(s), %s warning(s)\n' "$checked" "$errors" "$warnings"

if [ "$checked" -eq 0 ]; then
    printf 'No skills found under %s\n' "$root" >&2
    exit 1
fi

[ "$errors" -eq 0 ]
