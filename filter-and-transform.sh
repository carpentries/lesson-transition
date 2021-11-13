#!/usr/bin/env bash

# for the makefile, the output is a json file, but we want to make it a directory,
# so we are using parameter expansion
# https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html
OUT=${1%.*} # No file extension
CWD=$(pwd)
SCRIPT=${2}

REPO=$(sed -e 's/\.R$//' <<< ${SCRIPT})
BASE=$(basename ${REPO})
GHP="$(./pat.sh)"

# Move out the site/ directory in case it has previously been built (keeping the memory alive)
if [[ -d ${OUT}site/ ]]; then
  mv ${OUT}site/ ${OUT}../site-${BASE} || echo "" > /dev/null
fi
# removing the directory to make a fresh clone for git-filter-repo
rm -rf ${OUT}
# the clones must be FRESH
git clone .git/modules/${REPO} ${OUT}

BLANK=""
echo -e "\033[1mConverting \033[38;5;208m${OUT}\033[0;00m...\033[22m"
cd ${OUT}
git-filter-repo \
  --path-rename _episodes:episodes \
  --path-rename _episodes_rmd:episodes \
  --invert-paths \
  --path _config_dev.yml \
  --path _site/ \
  --path _includes/ \
  --path _layouts/ \
  --path bootstrap/ \
  --path assets/ \
  --path css/ \
  --path js/ \
  --path favicon/ \
  --path tools/ \
  --path bin/boilerplate/ \
  --path bin/chunk-options.R \
  --path bin/dependencies.R \
  --path bin/extract_figures.py \
  --path bin/generate_md_episodes.R \
  --path bin/install_r_deps.sh \
  --path bin/knit_lessons.sh \
  --path bin/lesson_check.py \
  --path bin/lesson_initialize.py \
  --path bin/markdown_ast.rb \
  --path bin/markdown-ast.rb \
  --path bin/repo_check.py \
  --path bin/reporter.py \
  --path bin/run-make-docker-serve.sh \
  --path bin/test_lesson_check.py \
  --path bin/util.py \
  --path bin/workshop_check.py \
  --path 404.md \
  --path aio.md \
  --path Makefile \
  --path Gemfile \
  --path .gitignore \
  --path .github \
  --path .travis.yml \
  --path tic.R \
  --path build_lesson.R \
  --path _site.yml \
  --path-glob '*html' \
  --path-glob '*.css' \
  --path-glob '*.gitkeep' \
  --path-glob '*.ico' \
  --path-regex '^fig/.*[-][0-9]{1,2}.png$' \
  --path-regex '^img/.*[-][0-9]{1,2}.png$' \
  --path-regex '^img/R-ecology-*$' \
  --message-callback 'return \
re.sub(b"https://github.com/'${REPO%%${BASE}}'", b"=/='${REPO%%${BASE}}'=/=", \
re.sub(b"#(\d+? ?)", b"'${BLANK}'/issues/\\1", \
message.replace(b"@", b" =@=")))'

# Update our branch and remote
ORIGIN=https://github.com/fishtree-attempt/${BASE}.git
CURRENT_BRANCH=$(git branch --show-current)
echo -e "\033[1mSetting origin to \033[38;5;208m${ORIGIN}\033[0;00m...\033[22m"
if [[ $(git remote -v) ]]; then
  git remote set-url origin ${ORIGIN}
else
  git remote add origin ${ORIGIN}
fi
if [[ ${CURRENT_BRANCH} != 'main' ]]; then 
  echo -e "\033[1mSetting default branch from \033[38;5;208m${CURRENT_BRANCH}\033[0;00m to \033[38;5;208mmain\033[0;00m...\033[22m"
fi
git branch -m main

# Back to our home and move the site back where it belongs
cd ${CWD}
if [[ -d ${OUT}../site-${BASE} ]]; then
  mv ${OUT}../site-${BASE} ${OUT}site/ || echo "" > /dev/null
fi

echo -e "... \033[1m\033[38;5;208mdone\033[0;00m\033[22m"

if [[ ${SCRIPT} == 'datacarpentry/R-ecology-lesson.R' ]]; then
  GITHUB_PAT="${GHP}" Rscript ${SCRIPT} \
    --build \
    --funs functions.R \
    --template template/ \
    --output ${OUT} \
    ${REPO} 
else
  GITHUB_PAT="${GHP}" Rscript transform-lesson.R \
    --build \
    --fix-liquid \
    --funs functions.R \
    --template template/ \
    --output ${OUT} \
    ${REPO} \
    ${SCRIPT} || echo "\n\n---\nErrors Occurred\n---\n\n"
fi

