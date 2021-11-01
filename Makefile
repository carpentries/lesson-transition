DIRS := swcarpentry \
	datacarpentry \
	librarycarpentry \
	carpentries-incubator \
	carpentries-lab \
	carpentries
INPUTS  := $(foreach dir, $(DIRS), $(wildcard $(dir)/*R))
MODULE  := $(patsubst %.R, %/, $(INPUTS))
CONVERT := $(patsubst %.R, sandpaper/%/, $(INPUTS))
TARGETS := $(patsubst %.R, %.txt, $(INPUTS))

.PHONY = all

all: template/ $(CONVERT) repos.md

template/ : renv.lock
	Rscript --no-init-file establish-template.R \
	  template/

# Get a submodule of a repository
%/ : 
	@echo -e "\033[1mChecking \033[38;5;208m$@\033[0;00m...\033[22m" && \
	git submodule add https://github.com/$@ $@ 2> /dev/null && \
	echo -e "... \033[1mNew submodule added in \033[38;5;208m$@\033[0;00m\033[22m"|| \
	echo -e "... \033[1mUpdating \033[38;5;208m$@\033[0;00m...\033[22m" && \
	git submodule update $@ && echo "... done"

sandpaper/%/ : %/ %.R transform-lesson.R
	@rm -rf $@
	@git clone https://github.com/$< $@
	@echo -e "\t\033[1mConverting \033[38;5;208m$@\033[0;00m...\033[22m"
	@cd $@ && \
	git-filter-repo \
	--invert-paths \
	--path _includes/ \
	--path _layouts/ \
	--path assets/ \
	--path js/ \
	--path tools/ \
	--path bin/boilerplate/ \
	--path bin/chunk-options.R \
	--path bin/dependencies.R \
	--path bin/generate_md_episodes.R \
	--path bin/install_r_deps.sh \
	--path bin/knit_lessons.sh \
	--path bin/lesson_check.py \
	--path bin/lesson_initialize.py \
	--path bin/markdown_ast.rb \
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
	--path-glob '*.gitkeep' \
	--path-regex 'fig/rmd[-].*[-][0-9]{1,2}.png$$'
	@echo "... done"

repos.md : $(TARGETS)
	rm -f repos.md
	for i in $^;\
	 do repo=$$(echo $$i | sed -e 's/.txt//');\
	 slug=$$(basename $$(echo $${repo} | sed -r -e "s_datacarpentry/([^R])_new-\1_"));\
	 account=$$(dirname $${repo});\
	 echo "- [$${repo}](https://github.com/$${repo}) -> [data-lessons/$${slug}](https://github.com/data-lessons/$${slug})" >> $@;\
	 done

# %.txt : %.R transform-lesson.R %.hash template/
# 	@echo hello


# Rscript transform-lesson.R \
#   --build \
#   --save   $(<D)/ \
#   --output $(<D)/sandpaper/ \
#     $* \
#     $< || echo "\n\n---\nErrors Occurred\n---\n\n"

# %.txt : ../% transform-lesson.R
# 	Rscript transform-lesson.R \
# 	  --build \
# 	  --save   ../$(@D)/ \
# 	  --output ../$(@D)/sandpaper/ \
# 	    $* \
# 	    $< || echo "\n\n---\nErrors Occurred\n---\n\n"

# datacarpentry/%.txt : ../datacarpentry/% transform-lesson.R
# 	Rscript transform-lesson.R \
# 	  --build \
# 	  --save   ../$(@D)/ \
# 	  --output ../$(@D)/sandpaper/new- \
# 	    datacarpentry/$* \
# 	    $(@D)/$*.R || echo "\n\n---\nErrors Occurred\n---\n\n"

# datacarpentry/R-ecology-lesson.txt : datacarpentry/R-ecology-lesson.R
# 	Rscript $< \
# 	  --build \
# 	  --save ../$(@D)/ \
# 	  --output ../$(@D)/sandpaper/ \
# 	    datacarpentry/R-ecology-lesson


