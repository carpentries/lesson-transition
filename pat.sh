#!/usr/bin/env bash
if [[ ${GITHUB_PAT} ]]; then
  echo ${GITHUB_PAT}
else
  printf "protocol=https\nhost=github.com\n" | git credential fill | grep password | awk -F= '{print $2}'
fi
