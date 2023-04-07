#!/usr/bin/env bash

# Create or update a submodule in this repository
# 
# This is intended to reduce the amount of effort needed to create submodules
# of Carpentries Lessons for conversion. To add a new submodule to this
# repository, one simply has to add a script with the name of the repository
# to the folder of the organisation name and this script will take care of
# the rest.
#
# Usage:
#
# bash fetch-submodule.sh <org>/<repo>.R
#
#
# Details
# =======
#
# This will behave differently based on these situations:
#
#
# The submodule does not exist in the repository
# -----------------------------------------------
#
# In this case, there are a few options depending on if we have seen this
# repository before or not.
#
# #### We want to add a new lesson
#
# When we want a new submodule, that means we just added a new file to the
# repository and this script will add the submodule in the same folder.
#
# #### We explicitly ignore this lesson in `.module-ignore`
#
# There are some repositories that we do not want to transform to using The
# Workbench. To prevent these repositories from cluttering up the submodules,
# we can add them to the `.module-ignore` file and then the module will be
# skipped when this script is run
#
#
# #### We have completed a release of this lesson
#
# In this case, the lesson has already gone through the release process and
# is now a Workbench lesson. We no longer need to keep track of this lesson and
# we can safely remove the module. 
#
# The submodule exists in the repository
# ---------------------------------------
#
# If we still want the submodule, then it will be updated. If we DO NOT want
# the submodule, then it will be removed according to 
# https://stackoverflow.com/a/1260982/2752888
#
# NOTE: the changes will be staged and you will have to write a commit message
# if the submodule is removed
REPO="${1%.*}"

BETA="beta/${REPO%%[/]}-invalid.hash"
RELEASE="release/${REPO%%[/]}-invalid.hash"
IN_MODULES=$(grep -c ${REPO%%[/]} .gitmodules)
IN_IGNORE=$(grep -c ${REPO%%[/]} .module-ignore)

# DELETE SUBMODULE ------------------------------------------------------------
# If we are ignoring the repository, or it has been released, then we want to
# shortcut out of here OR delete it. 
if [[ "${IN_IGNORE}" -ne 0 || -e "${BETA}" || -e "${RELEASE}" ]]; then
  if [[ ${IN_MODULES} -ne 0 ]]; then
    echo -e "\033[1mRemoving \033[38;5;208m${REPO}\033[0;00m as a submodule\033[22m"
    git rm -rf "${REPO}"
    rm -rf ".git/modules/${REPO}"
    git config --remove-section "submodule.${REPO%%[/]}" || echo ""
  else
    echo -e "\033[1mNothing to do for \033[38;5;208m${REPO}\033[0;00m.\033[22m"
  fi
  exit 0
fi

# UPDATE SUBMODULE ------------------------------------------------------------
# If we are not ignoring the repository, then we need to download it.

# CHECK DEFAULT BRANCH
TOKEN=$(./pat.sh)
echo -e "\033[1mChecking \033[38;5;208m${REPO}\033[0;00m...\033[22m"
BRANCH=$(curl -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${TOKEN}" https://api.github.com/repos/${REPO%%[/]} | jq -r '.default_branch')

set -e

if [[ $(grep -c ${REPO} .gitmodules) -eq 0 ]]; then
    # if the repository does not exist, then we need to create it
    echo -e "... \033[1mCreating new submodule in \033[38;5;208m${REPO}\033[0;00m\033[22m"
    rm -rf "${REPO}"
    git submodule add --force -b ${BRANCH} https://github.com/${REPO} ${REPO} || exit 0 #2> /dev/null
elif [[ ! -e ${REPO}/.git ]]; then
    # if the folder exists, but no repository exists, we need to create it. 
    git submodule update --init ${REPO} || exit 0
else
    echo -e "... \033[1mUpdating \033[38;5;208m${REPO}\033[0;00m...\033[22m"
    git submodule add --force -b ${BRANCH} https://github.com/${REPO} ${REPO} || exit 0 #2> /dev/null
fi

# Running a subshell so we don't accidenatlly change our working directory
(
    set -e
    cd "${REPO}"
    echo -e "... \033[1mchecking out '${BRANCH}' branch\033[0;00m\033[22m"
    git checkout ${BRANCH} || git checkout main || git checkout gh-pages
    echo -e "... \033[1mpulling in changes\033[0;00m\033[22m"
    git pull
)

echo "... done"
