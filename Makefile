DIRS := swcarpentry \
	datacarpentry \
	librarycarpentry \
	carpentries-incubator \
	carpentries-lab \
	carpentries
INPUTS  := $(foreach dir, $(DIRS), $(wildcard $(dir)/*R))
MODULE  := $(patsubst %.R, %/, $(INPUTS))
CONVERT := $(patsubst %.R, sandpaper/%/, $(INPUTS))
TARGETS := $(patsubst %.R, sandpaper/%.json, $(INPUTS))

.PHONY = all

all: template/ $(CONVERT) $(TARGETS) repos.md

template/ : renv.lock
	Rscript --no-init-file establish-template.R $@

# $(MODULE) Get a submodule of a repository
%/ : %.R
	bash fetch-submodule.sh $@

# $(CONVERT) Copy and transform a lesson
sandpaper/%/ : %.R %/ template/ transform-lesson.R filter-and-transform.sh
	bash filter-and-transform.sh $@ $<

# Get a json log of the changed files (this is provided for the previous
# template, but is needed for the rule)
# $(TARGET)
sandpaper/%.json : sandpaper/%/
	@touch $@


repos.md : $(TARGETS)
	@rm -f repos.md
	@for i in $^;\
	 do repo=$$(echo $$i | sed -e 's/.json//');\
	 slug=$$(basename $$(echo $${repo} | sed -r -e "s_datacarpentry/([^R])_new-\1_"));\
	 account=$$(dirname $${repo});\
	 echo "- [$${repo}](https://github.com/$${repo}) -> [data-lessons/$${slug}](https://github.com/data-lessons/$${slug})" >> $@;\
	 done

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


