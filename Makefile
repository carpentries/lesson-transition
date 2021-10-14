TARGETS := swcarpentry/r-novice-gapminder.txt


.PHONY = all

all: $(TARGETS)

swcarpentry/%.txt : swcarpentry/%.R transform-lesson.R
	Rscript transform-lesson.R \
		--save    ../$(@D)/ \
		--output  ../$(@D)/sandpaper/ \
		          $(@D)/$* \
		          $<
	touch $@

