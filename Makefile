DIRS := swcarpentry \
	datacarpentry \
	librarycarpentry \
	carpentries-incubator \
	carpentries-lab \
	carpentries
INPUTS  := $(foreach dir, $(DIRS), $(wildcard $(dir)/*R))
TARGETS := $(patsubst %.R, %.txt, $(INPUTS))
REPOS   := $(patsubst %.R, %.hash, $(INPUTS))

.PHONY = all

all: template/ $(REPOS) repos.md

template/ : 
	Rscript establish-template.R \
	  template/

repos.md : $(TARGETS) 
	rm -f repos.md
	for i in $^;\
	 do repo=$$(echo $$i | sed -e 's/.txt//');\
	 slug=$$(basename $$(echo $${repo} | sed -r -e "s_datacarpentry/([^R])_new-\1_"));\
	 account=$$(dirname $${repo});\
	 echo "- [$${repo}](https://github.com/$${repo}) -> [data-lessons/$${slug}](https://github.com/data-lessons/$${slug})" >> $@;\
	 done

%.hash: 
	Rscript fetch-repo.R \
	  --save ../$(@D)/ \
	  $(@D)/$(*F)

%.txt : %.R transform-lesson.R %.hash template/
	@ echo hello
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


