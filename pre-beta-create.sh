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
OUT="prebeta/${REPOSITORY}-status.json"
echo "from ${REPOSITORY} to ${ORG}/${NAME} (${TEAM})"

# This does three steps:
# 1. create the brand new repository called ${NAME}
curl \
  -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token ${NEW_TOKEN}" \
  https://api.github.com/orgs/${ORG}/repos \
  -d "{\"name\":\"${NAME}\", \"homepage\":\"https://${ORG}.github.io/${NAME}/\"}" > ${OUT}
# 2. create a new team in the fishtree-attempt organisation that is dedicated to
#    this repository
curl \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${BOT_TOKEN}" \
  https://api.github.com/orgs/${ORG}/teams \
  -d '{"repo_names": ["'${ORG}/${NAME}'"],"name":"'"${NAME}"'-maintainers","description":"Maintainers of the '"${NAME}"' beta test","privacy":"closed"}'
#
# 2. assign the ${TEAM} to that repository 
curl \
  -X PUT \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token ${BOT_TOKEN}" \
  https://api.github.com/orgs/${ORG}/teams/${TEAM}/repos/${ORG}/${NAME} \
  -d '{"permission":"push"}'

curl \
  -X PUT \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token ${BOT_TOKEN}" \
  https://api.github.com/orgs/${ORG}/teams/${NAME}-maintainers/repos/${ORG}/${NAME} \
  -d '{"permission":"maintain"}'

URL=$(jq -r .html_url < ${OUT})
# 3. push the repository to the new lesson
cd sandpaper/${REPOSITORY}
git push -u origin main
Rscript -e "usethis::use_github_pages()"

echo "Browse the repository at ${URL}"
