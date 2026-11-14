#!/usr/bin/env bash
# Fails if app code styles text outside the design system.
# Allowed: .hbText(...) everywhere; raw .font(...) only inside Sources/HushbalmDesignSystem.
set -euo pipefail
cd "$(dirname "$0")/.."

violations=$(grep -rn --include='*.swift' -E '\.font\(|Font\.custom|UIFont' . \
  | grep -v '^./Sources/HushbalmDesignSystem/' || true)

if [ -n "$violations" ]; then
  echo "Font rule violated. Use .hbText(_:) instead of .font(...):"
  echo "$violations"
  exit 1
fi
echo "Font check passed: all text uses the design system."
