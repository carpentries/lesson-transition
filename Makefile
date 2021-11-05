DIRS := swcarpentry \
	datacarpentry \
	librarycarpentry \
	carpentries-incubator \
	carpentries-lab \
	carpentries
INPUTS  := $(foreach dir, $(DIRS), $(wildcard $(dir)/*R))
MODULE  := $(patsubst %.R, %/, $(INPUTS))
TARGETS := $(patsubst %.R, sandpaper/%.json, $(INPUTS))
TARGETS := $(patsubst sandpaper/datacarpentry/new-%, sandpaper/datacarpentry/%, $(TARGETS))
PREREQS := template/ transform-lesson.R filter-and-transform.sh functions.R

.PHONY = all

all: template/ $(TARGETS) repos.md

template/ : establish-template.R renv.lock
	Rscript --no-init-file $< $@

# $(MODULE) Get a submodule of a repository
%/ : %.R
	bash fetch-submodule.sh $@

# $(TARGETS) Copy and transform a lesson
sandpaper/%.json : %.R %/ $(PREREQS)
	bash filter-and-transform.sh $@ $<

sandpaper/datacarpentry/new-%.json : datacarpentry/%.R datacarpentry/%/ $(PREREQS)
	bash filter-and-transform.sh $@ $<

sandpaper/datacarpentry/new-R-ecology-lesson.json : datacarpentry/R-ecology-lesson.R datacarpentry/R-ecology-lesson/ $(PREREQS)
	bash filter-and-transform.sh $@ $<

repos.md : $(TARGETS)
	@rm -f repos.md
	@for i in $^;\
	 do repo=$$(echo $$i | sed -e 's/.json//');\
	 slug=$$(basename $$(echo $${repo} | sed -r -e "s_datacarpentry/([^R])_new-\1_"));\
	 account=$$(dirname $${repo});\
	 echo "- [$${repo}](https://github.com/$${repo}) -> [data-lessons/$${slug}](https://github.com/data-lessons/$${slug})" >> $@;\
	 done



