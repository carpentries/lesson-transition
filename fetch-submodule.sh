#!/usr/bin/env bash

REPO=${1%.*}

echo -e "\033[1mChecking \033[38;5;208m${REPO}\033[0;00m...\033[22m"
if [[ ! -d ${REPO} ]]; then
    echo -e "... \033[1mCreating new submodule in \033[38;5;208m${REPO}\033[0;00m\033[22m"
    git submodule add https://github.com/${REPO} ${REPO} 2> /dev/null 
elif [[ ! -f ${REPO}/.git ]]; then
    echo -e "... \033[1mCloning \033[38;5;208m${REPO}\033[0;00m\033[22m"
    git submodule update --init https://github.com/${REPO} ${REPO} 2> /dev/null 
else
    echo -e "... \033[1mUpdating \033[38;5;208m${REPO}\033[0;00m...\033[22m"
    git submodule update ${REPO}
fi
echo "... done"
