#!/usr/bin/env bash

set -euo pipefail

nix build .#iso
sha256sum result/iso/*.iso > SHA256SUMS
