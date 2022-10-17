#!/usr/bin/env bash
# 
# This will remove a test repository so that we can quickly iterate recreating
# repositories. The only risk is that we do not want to delete the original
# repository, so the input is the slug for the record 
# (e.g. swcarpentry/r-novice-gapminder). From there, we delete the repository
# called fishtree-attempt/r-novice-gapminder
set -euo pipefail

RECORD=${1}
FILE=sandpaper/${RECORD}-status.json
ORG="${2:-fishtree-attempt}"
NAME="$(basename ${RECORD})"
REPOSITORY="${ORG}/${NAME}"

# This is a mechanism to prevent repositories from accidentally being deleted.
# 
# When we create new repositories, we will write the new repository output to
# sandpaper/ORG/REPO-status.json. 
# 
# When we read in this json file, we can get the created at time
echo "jq '.created_at' < ${FILE}"
CREATED=$(jq '.created_at' < ${FILE})
if [[ ! -n ${CREATED} ]]; then
  echo "No record for ${REPOSITORY}"
  echo "This is the information we have recorded:"
  jq < ${FILE}
  exit 0
else
  echo "${REPOSITORY}, was created at ${CREATED} according to ${FILE}"
fi

if [[ -z ${DEL_TOKEN} ]]; then
  echo "This process needs a delete token"
  exit 1
fi

# The TIME variable stores the live created at time of the repository from the 
# GitHub API. This will fail if the token is invalid.
TIME=$(curl \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Authorization: token ${DEL_TOKEN}" \
    https://api.github.com/repos/${REPOSITORY} | jq '.created_at')

# If the creation time of the repo we are about to delete is confirmed, then we
# can delete it. 
if [[ ${TIME} == ${CREATED} ]]; then 
  echo "Deleting ${REPOSITORY}, which was created at ${CREATED} according to ${FILE}"
  curl \
    -X DELETE \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Authorization: token ${DEL_TOKEN}" \
    https://api.github.com/repos/${REPOSITORY}
  rm -f ${FILE}
elif [[ ${TIME} ]]; then
  echo "The time ${REPOSITORY} was created does not match the time we have recorded in ${FILE}"
  echo ""
  echo "expected: ${CREATED}"
  echo "actual  : ${TIME}"
  exit 1
else
  echo "${REPOSITORY} does not yet exist"
fi
