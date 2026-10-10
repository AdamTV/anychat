#!/usr/bin/env bash
# Point git at this repository's hooks directory (repo-local core.hooksPath,
# no global git configuration is touched).
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
git config core.hooksPath .githooks
chmod +x .githooks/pre-commit
echo "Enabled .githooks/pre-commit (git config core.hooksPath .githooks)."
