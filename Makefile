DIRS := swcarpentry \
	datacarpentry \
	librarycarpentry \
	carpentries-incubator \
	carpentries-lab \
	carpentries
INPUTS  := $(foreach dir, $(DIRS), $(wildcard $(dir)/*R))
MODULE  := $(patsubst %.R, %/, $(INPUTS))
TARGETS := $(patsubst %.R, %.txt, $(INPUTS))

.PHONY = all

all: template/ $(MODULE) repos.md

template/ : renv.lock
	Rscript --no-init-file establish-template.R \
	  template/

# Get a submodule of a repository
%/ : 
	@echo -e "\033[1mChecking \033[38;5;208m$@\033[0;00m...\033[22m" && \
	git submodule add https://github.com/$@ $@ 2> /dev/null && \
	echo -e "\t\033[1mNew submodule added in \033[38;5;208m$@\033[0;00m\033[22m"|| \
	echo -e "\t\033[1mUpdating \033[38;5;208m$@\033[0;00m...\033[22m" && \
	git submodule update $@

repos.md : $(TARGETS)
	rm -f repos.md
	for i in $^;\
	 do repo=$$(echo $$i | sed -e 's/.txt//');\
	 slug=$$(basename $$(echo $${repo} | sed -r -e "s_datacarpentry/([^R])_new-\1_"));\
	 account=$$(dirname $${repo});\
	 echo "- [$${repo}](https://github.com/$${repo}) -> [data-lessons/$${slug}](https://github.com/data-lessons/$${slug})" >> $@;\
	 done

%.txt : %.R transform-lesson.R %.hash template/
	@echo hello


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


