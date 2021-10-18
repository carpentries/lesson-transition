DIRS := swcarpentry \
	datacarpentry \
	librarycarpentry \
	carpentries-incubator \
	carpentries-lab \
	carpentries
INPUTS  := $(foreach dir, $(DIRS), $(wildcard $(dir)/*R))
TARGETS := $(patsubst %.R, %.txt, $(INPUTS))

.PHONY = all

all: repos.md

repos.md : $(TARGETS)
	rm -f repos.md
	for i in $^; do echo "- [$$i](https://github.com/data-lessons/$$i)" |\
	  sed -r -e "s_.com/([^/]+)/[^/]+_.com/\1_" |\
	  sed -e "s/.txt//g" >> $@; done

%.txt : %.R transform-lesson.R
	Rscript transform-lesson.R \
	  --build \
	  --save   ../$(@D)/ \
	  --output ../$(@D)/sandpaper/ \
	    $* \
	    $<

datacarpentry/R-ecology-lesson.txt : datacarpentry/R-ecology-lesson.R
	Rscript $< \
	  --build \
	  --save ../$(@D)/ \
	  --output ../$(@D)/sandpaper/ \
	    datacarpentry/R-ecology-lesson


