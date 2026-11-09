#!/bin/bash
# Prints the OBS Blade Remote version - it must be the same in the core
# (Cargo.toml), the plugin (buildspec.json) and the standalone
# (CMakeLists.txt); with an argument (a tag like remote-v0.4.0) it must
# match that too.
set -euo pipefail
cd "$(dirname "$0")"
core=$(sed -n 's/^version = "\(.*\)"/\1/p' core/Cargo.toml | head -1)
plugin=$(sed -n 's/^    "version": "\(.*\)",$/\1/p' plugin/buildspec.json | tail -1)
standalone=$(sed -n 's/^project(obs-blade-remote-standalone VERSION \([0-9.]*\) .*/\1/p' standalone/CMakeLists.txt)
if [[ $core != "$plugin" || $core != "$standalone" ]]; then
  echo "versions differ: core $core, plugin $plugin, standalone $standalone" >&2
  exit 1
fi
if [[ $# -gt 0 && ${1#remote-v} != "$core" ]]; then
  echo "tag $1 doesn't match version $core" >&2
  exit 1
fi
echo "$core"
