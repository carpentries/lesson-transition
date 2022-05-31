#!/usr/bin/env bash
set -euo pipefail

NAME=${1:-new}

if [[ "${CI}" ]]; then
  printf "${GITHUB_TOKEN}"
  exit 0
fi

if [[ $(vault kv get -field=${NAME} tr/auth 2> /dev/null) ]]; then
  vault kv get -field=${NAME} tr/auth
elif [[ ${NAME} == 'new' ]]; then
  printf "url=https://github.com\n" | git credential fill | grep password | awk -F= '{print $2}'
else
  exit 1
fi
