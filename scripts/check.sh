#!/usr/bin/env bash
# Pre-commit sanity check for humans and agents. Usage: scripts/check.sh
# Builds the site exactly like production and validates content conventions.
set -euo pipefail
cd "$(dirname "$0")/.."

fail=0
err() { echo "ERROR: $*" >&2; fail=1; }

# 1. Hugo version matches the one Vercel uses.
want=$(sed -n 's/.*"HUGO_VERSION": *"\([^"]*\)".*/\1/p' vercel.json)
have=$(hugo version | sed -n 's/^hugo v\([0-9.]*\).*/\1/p')
[[ "$want" == "$have" ]] || echo "WARN: local Hugo $have differs from vercel.json $want" >&2

# 2. Production build into a temp dir; any Hugo warning fails the check.
out=$(mktemp -d)
trap 'rm -rf "$out"' EXIT
if ! hugo --gc --panicOnWarning --quiet -d "$out"; then
  err "hugo build failed"
fi

# 3. Front matter conventions for every post.
for f in content/posts/*.md content/posts/*/index.md; do
  [[ -e "$f" ]] || continue
  fm=$(awk 'NR==1 && /^---$/ {fm=1; next} fm && /^---$/ {exit} fm {print}' "$f")
  grep -q '^title:' <<<"$fm" || err "$f: missing title"
  grep -q '^date:' <<<"$fm" || err "$f: missing date"
  if ! grep -q '^draft: *true' <<<"$fm"; then
    grep -q '^description:' <<<"$fm" || err "$f: published post missing description"
    grep -q 'One-sentence summary' <<<"$fm" && err "$f: placeholder description left in a published post"
    grep -q '^tags:' <<<"$fm" || err "$f: published post missing tags"
  fi
done

# 4. Images: no third-party hosting, and every bundle image reference resolves.
if grep -rnE 'dropbox\.com|imgur\.com|googleusercontent\.com' content >&2; then
  err "third-party-hosted images found above; store images in the post's bundle folder"
fi
while IFS= read -r ref; do
  file=${ref%%:*}
  src=$(sed -nE 's/.*src="([^"]+)".*/\1/p' <<<"${ref#*:}")
  [[ "$src" == *://* || "$src" == /* ]] && continue
  [[ -e "$(dirname "$file")/$src" ]] || err "$file: figure src \"$src\" not found next to the post"
done < <(grep -rnoE '\{\{< *figure [^>]*src="[^"]+"' content --include=index.md | sed -E 's/^([^:]+):[0-9]+:/\1:/')
while IFS= read -r line; do
  file=${line%%:*}; cover=$(sed -E 's/^[^:]+:cover: *//; s/["'"'"']//g' <<<"$line")
  [[ -e "$(dirname "$file")/$cover" ]] || err "$file: cover \"$cover\" not found next to the post"
done < <(grep -rH '^cover:' content/posts --include=index.md)

[[ $fail -eq 0 ]] && echo "OK: build and content checks passed"
exit $fail
