#!/usr/bin/env bash
# Fails if app code styles text or icons outside the design system.
# Allowed: .hbText(...) and .hbIcon(...) everywhere; raw .font(...) only inside the design-system package.
set -euo pipefail
cd "$(dirname "$0")/.."

violations=$(grep -rn --include='*.swift' -E '\.font\(|Font\.custom|UIFont' . \
  | grep -v '^./Packages/HushbalmDesignSystem/' || true)

if [ -n "$violations" ]; then
  echo "Font rule violated. Use .hbText(_:) or .hbIcon(_:) instead of .font(...):"
  echo "$violations"
  exit 1
fi
echo "Font check passed: all text and icons use the design system."
