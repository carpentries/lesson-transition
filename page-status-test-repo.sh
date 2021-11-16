#!/usr/bin/env bash
set -euo pipefail

RECORD=${1%.*}
ORG="${2:-fishtree-attempt}"
TOKEN=$(./pat.sh)
NAME="$(basename ${RECORD})"
REPOSITORY="${ORG}/${NAME}"

STATUS=$(curl \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token ${TOKEN}" \
  https://api.github.com/repos/${REPOSITORY}/deployments?per_page=1 2> /dev/null \
  | jq -r '.[].statuses_url')

if [[ ${STATUS} ]]; then
  curl ${STATUS} 2> /dev/null | jq -r '.[].state'
else
  echo "No page built"
fi
