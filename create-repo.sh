#!/usr/bin/env bash

REPOSITORY=${1:data-lessons/znk-test}
TEAM=${2:bots}
ORG=$(dirname ${REPOSITORY})
NAME=$(basename ${REPOSITORY})

# This does two steps:
#
# 1. create the brand new repository called ${NAME}
curl \
  -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token ${NEW_TOKEN}" \
  https://api.github.com/orgs/${ORG}/repos \
  -d '{"name":"${NAME}"}'

# 2. assign the ${TEAM} to that repository 
curl \
  -X PUT \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token ${BOT_TOKEN}" \
  https://api.github.com/orgs/${ORG}/teams/${TEAM}/repos/${ORG}/${NAME} \
  -d '{"permission":"push"}'
