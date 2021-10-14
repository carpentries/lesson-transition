DIRS := swcarpentry \
	datacarpentry \
	librarycarpentry \
	carpentries-incubator \
	carpentries-lab \
	carpentries
INPUTS  := $(foreach dir, $(DIRS), $(wildcard $(dir)/*R))
TARGETS := $(patsubst %.R, %.txt, $(INPUTS))

.PHONY = all

all: $(TARGETS)

%.txt : %.R transform-lesson.R
	Rscript transform-lesson.R \
	  --build \
	  --save   ../$(@D)/ \
	  --output ../$(@D)/sandpaper/ \
	    $* \
	    $<
	touch $@

