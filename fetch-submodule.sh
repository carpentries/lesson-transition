#!/usr/bin/env bash

REPO="${1%.*}"

BETA="beta/${REPO%%[/]}.json"
RELEASE="release/${REPO%%[/]}.json"
IN_MODULES=$(grep -c ${REPO%%[/]} .gitmodules)
IN_IGNORE=$(grep -c ${REPO%%[/]} .module-ignore)

if [[ "${IN_IGNORE}" -ne 0 || -e "${BETA}" || -e "${RELEASE}" ]]; then
  if [[ ${IN_MODULES} -ne 0 ]]; then
    echo -e "\033[1mRemoving \033[38;5;208m${REPO}\033[0;00m as a submodule\033[22m"
    git rm "${REPO}"
    rm -rf ".git/modules/${REPO}"
    git config --remove-section "submodule.${REPO%%[/]}" || echo ""
  else
    echo -e "\033[1mNothing to do for \033[38;5;208m${REPO}\033[0;00m.\033[22m"
  fi
  exit 0
fi

TOKEN=$(./pat.sh)

echo -e "\033[1mChecking \033[38;5;208m${REPO}\033[0;00m...\033[22m"
BRANCH=$(curl -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${TOKEN}" https://api.github.com/repos/${REPO%%[/]} | jq -r '.default_branch')

if [[ $(grep -c ${REPO} .gitmodules) -eq 0 ]]; then
    # if the repository does not exist, then we need to create it
    echo -e "... \033[1mCreating new submodule in \033[38;5;208m${REPO}\033[0;00m\033[22m"
    git submodule add -b ${BRANCH} https://github.com/${REPO} ${REPO} #2> /dev/null
else
    echo -e "... \033[1mUpdating \033[38;5;208m${REPO}\033[0;00m...\033[22m"
    git submodule add --force -b ${BRANCH} https://github.com/${REPO} ${REPO} #2> /dev/null
fi
echo "... done"
