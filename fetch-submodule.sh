#!/usr/bin/env bash

REPO=${1}

echo -e "\033[1mChecking \033[38;5;208m${REPO}\033[0;00m...\033[22m"
if [[ -d ${REPO} ]]; then
    git submodule add https://github.com/${REPO} ${REPO} 2> /dev/null 
    echo -e "... \033[1mNew submodule added in \033[38;5;208m${REPO}\033[0;00m\033[22m"
else
    echo -e "... \033[1mUpdating \033[38;5;208m${REPO}\033[0;00m...\033[22m"
    git submodule update ${REPO}
    echo "... done"
fi
