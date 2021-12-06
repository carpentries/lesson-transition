#!/usr/bin/env bash

REPO=${1%.*}
TOKEN=$(./pat.sh)

echo -e "\033[1mChecking \033[38;5;208m${REPO}\033[0;00m...\033[22m"
BRANCH=$(curl -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${TOKEN}" https://api.github.com/repos/${REPO} | jq -r '.default_branch')

if [[ $(grep -c ${REPO} .gitmodules) -eq 0 ]]; then
    # if the repository does not exist, then we need to create it
    echo -e "... \033[1mCreating new submodule in \033[38;5;208m${REPO}\033[0;00m\033[22m"
    git submodule add -b ${BRANCH} https://github.com/${REPO} ${REPO} 2> /dev/null
else
    echo -e "... \033[1mUpdating \033[38;5;208m${REPO}\033[0;00m...\033[22m"
fi
echo "... done"
