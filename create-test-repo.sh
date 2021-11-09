#!/usr/bin/env bash
# This script will create a test repository and assign a team to that repository
#
# Usage:
#   NEW_TOKEN=$(./pat.sh) BOT_TOKEN=<token> bash create-test-repo.sh repo/name team new-org
#
# The above command will create new-org/repo and assign it to "team".
set -euo pipefail

REPOSITORY=${1:-fishtree-attempt/znk-test}
TEAM=${2:-bots}
ORG="${3:-fishtree-attempt}"
NAME="$(basename ${REPOSITORY})"
OUT="sandpaper/${REPOSITORY}-status.json"
echo "from ${REPOSITORY} to ${ORG}/${NAME} (${TEAM})"

# This does two steps:
#
# 1. create the brand new repository called ${NAME}
curl \
  -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token ${NEW_TOKEN}" \
  https://api.github.com/orgs/${ORG}/repos \
  -d "{\"name\":\"${NAME}\"}" > ${OUT}

# 2. assign the ${TEAM} to that repository 
curl \
  -X PUT \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token ${BOT_TOKEN}" \
  https://api.github.com/orgs/${ORG}/teams/${TEAM}/repos/${ORG}/${NAME} \
  -d '{"permission":"push"}'

# 3. push the repository to the new lesson
cd sandpaper/${REPOSITORY}
git push -u origin main
