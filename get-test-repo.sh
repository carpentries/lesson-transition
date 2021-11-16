#!/usr/bin/env bash
set -euo pipefail

RECORD=${1}
ORG="${2:-fishtree-attempt}"
TOKEN=$(./pat.sh)
NAME="$(basename ${RECORD})"
REPOSITORY="${ORG}/${NAME}"

curl \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token ${TOKEN}" \
  https://api.github.com/repos/${REPOSITORY} 
