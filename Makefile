SHELL = bash
DIRS := swcarpentry \
	datacarpentry \
	librarycarpentry \
	carpentries-incubator \
	carpentries-lab \
	MonashDataFluency \
	carpentries
# INPUTS gives you a list of R files that are used to transform the lesson
INPUTS  := $(foreach dir, $(DIRS), $(wildcard $(dir)/*R))
# Workbench Beta Phase
#
# This is divided up into three stages (but two important ones for our
# transformations): The pre-beta, where there are two repositories, and the beta
# where there is one repository. Because our process up until now has been to 
# destroy and rebuild the lessons, we now need to incorporate steps that will
# allow folks to be able to work with the lessons and not lose their work
# because I accidentally hit make all and then everything was deleted. By 
# creating two new, curated lists of targets, we will be able to filter them out
# from our targets and make sure they are always up to date. 
#
# Pre-beta: these are lessons that will enter into pre-beta stage, so they
#   should be filtered out and handled differently than the normal targets.
#   These lessons are now part of the beta stage and need to be handled and 
#   stored differently.
PREBETA = datacarpentry/R-ecology-lesson.R \
	datacarpentry/r-socialsci.R \
	datacarpentry/r-raster-vector-geospatial.R \
	carpentries/instructor-training.R \
	librarycarpentry/lc-shell.R \
	datacarpentry/python-ecology-lesson-es.R
#
# Beta: This one is tricky. For lessons that enter this phase, we will make a
#   lesson release, get the gh-pages branch and covert it to legacy, and then
#   force-push the main branch. 
BETA = zkamvar/transition-test-2.R \
	datacarpentry/r-socialsci.R \
	datacarpentry/r-raster-vector-geospatial.R \
	carpentries/instructor-training.R \
	datacarpentry/python-ecology-lesson-es.R
# MODULE are the git submodules for each lesson
MODULE  := $(patsubst %.R, %/.git, $(INPUTS))
# Filter out the pre-beta from the inputs
TARGETS := $(patsubst %.R, sandpaper/%.json, $(filter-out $(PREBETA), $(INPUTS)))
GITHUB  := $(patsubst %.R, sandpaper/%-status.json, $(filter-out $(PREBETA), $(INPUTS)))
# Filter out the beta from the pre-beta
PREBETA_TARGETS := $(patsubst %.R, prebeta/%.json, $(filter-out $(BETA), $(PREBETA)))
PREBETA_GITHUB := $(patsubst %.R, prebeta/%-status.json, $(filter-out $(BETA), $(PREBETA)))
BETA_TARGETS := $(patsubst %.R, beta/%.json, $(BETA))
BETA_GITHUB := $(patsubst %.R, prebeta/%-status.json, $(BETA))
PREREQS := renv/library/ template/ filter-and-transform.sh functions.R filter-list.txt

.PHONY = all
.PHONY = modules
.PHONY = template
.PHONY = update
.PHONY = github
.PHONY = info

# variables so that I can add colours to the output
BOLD ?= "\\033[1m"
U ?= "\\033[4m"
END ?= "\\033[22m"
ORANGE ?= "\\033[38\;5\;208m"
CLEAR ?= "\\033[0\;00m"
PINK ?= "\\033[38\;5\;206m"
GREEN ?= "\\033[38\;5\;64m"

all:  #restore template/ $(TARGETS) repos.md
	@echo -e
	@echo -e 'Welcome to the Lesson Transition Workflow'
	@echo -e '-----------------------------------------'
	@echo -e 
	@echo -e 'Add an R script of the lesson repository name to the folder of the GitHub organisation it is in.'
	@echo -e
	@echo -e 'Example: '
	@echo -e
	@echo -e "    $(BOLD)Adding $(ORANGE)swcarpentry/git-novice.R$(CLEAR) will allow the transtion workflow to $(END)"
	@echo -e "    transition $(BOLD)$(U)<https://github.com/swcarpentry/git-novice>$(CLEAR) to use $(END)"
	@echo -e '    the workbench'
	@echo -e
	@echo -e "Then you can use either:"
	@echo -e
	@echo -e "    $(BOLD)make $(GREEN)sandpaper/$(CLEAR)$(BOLD)<org>/<lesson>.json$(CLEAR) to test a lesson transition$(END)"
	@echo -e
	@echo -e "    $(BOLD)make $(PINK)release/$(CLEAR)$(BOLD)<org>/<lesson>.json$(CLEAR) to $(PINK)$(BOLD)$(U)transition and release$(CLEAR) a lesson$(END)"
	@echo
	@echo

modules: $(MODULE)

# $(MODULE) Get a submodule of a repository
%/.git : %.R
	bash fetch-submodule.sh $@

# $(TARGETS) Copy and transform a lesson
sandpaper/%.json : %.R %/.git $(PREREQS) transform-lesson.R
	PATH="$(PWD)/git-filter-repo/git-filter-repo:${PATH}" bash filter-and-transform.sh $@ $<

prebeta/%.json : %.R %/.git $(PREREQS) transform-lesson.R pre-beta.R
	Rscript pre-beta.R $* $@ beta-phase.csv

beta/%.json : %.R %/.git $(PREREQS) transform-lesson.R beta.R
	Rscript beta.R $* $@ beta-phase.csv

release/%.json : %.R %/.git $(PREREQS) transform-lesson.R final-transition.R
	Rscript final-transition.R $* $@

sandpaper/datacarpentry/R-ecology-lesson.json : datacarpentry/R-ecology-lesson.R datacarpentry/R-ecology-lesson/.git $(PREREQS)
	PATH="$(PWD)/git-filter-repo/git-filter-repo:${PATH}" bash filter-and-transform.sh $@ $<

prebeta/datacarpentry/R-ecology-lesson.json : datacarpentry/R-ecology-lesson.R datacarpentry/R-ecology-lesson/.git $(PREREQS)
	Rscript pre-beta.R datacarpentry/R-ecology-lesson $@ beta-phase.csv

renv/library/ :
	@GITHUB_PAT=$$(./pat.sh) Rscript -e 'renv::restore()'
update:
	@GITHUB_PAT=$$(./pat.sh) Rscript renv_update.R
restore:
	@GITHUB_PAT=$$(./pat.sh) Rscript -e 'renv::restore(library = renv::paths$$library())'

template: template/
template/ : establish-template.R renv.lock renv/library/
	@GITHUB_PAT=$$(./pat.sh) Rscript $< -w workbench-beta-phase.yml $@


github: $(GITHUB)
sandpaper/%-status.json : sandpaper/%.json create-test-repo.sh delete-test-repo.sh
	@echo "Creating $@"
	@bash delete-test-repo.sh $* || echo "No repository to delete"
	@NEW_TOKEN=$$(./pat.sh) bash create-test-repo.sh $* bots fishtree-attempt

bump: 
	@for i in $(GITHUB); \
		do j="$${i%%-status.json}"; \
			gh workflow run sandpaper-main.yaml --repo "fishtree-attempt/$${j##*/}" -f reset=true; \
		done

info: 
	@echo "Repositories not yet in Beta ------------------------------------------"
	@for i in $(GITHUB); \
		do [[ -e $${i} ]] && printf "$$(jq .created_at < $${i} | xargs date -d)\t$${i##sandpaper/}\n" || echo "$${i} does not exist"; \
		done
	@echo "Repositories Pre-Beta -------------------------------------------------"
	@for i in $(PREBETA_GITHUB); \
		do [[ -e $${i} ]] && printf "$$(jq .created_at < $${i} | xargs date -d)\t$${i##sandpaper/}\n" || echo "$${i} does not exist"; \
		done
	@echo "Repositories Beta -----------------------------------------------------"
	@for i in $(BETA_GITHUB); \
		do [[ -e $${i} ]] && printf "$$(jq .created_at < $${i} | xargs date -d)\t$${i##sandpaper/}\n" || echo "$${i} does not exist"; \
		done

status:
	@for i in $(GITHUB); \
		do [[ -e $${i} ]] && printf "$$(./page-status-test-repo.sh $${i/-status//})\t$${i##sandpaper/}\n" || echo '$${i} does not exist'; \
		done

touchy:
	@for i in $(TARGETS); do touch $${i}; done

repos.md : $(TARGETS)
	@rm -f repos.md
	@for i in $^;\
	 do repo=$$(echo $$i | sed -e 's/.json//');\
	 slug=$$(basename $${repo});\
	 account=$$(dirname $${repo});\
	 echo "- [$${repo##sandpaper/}](https://github.com/$${repo##sandpaper/}) -> [fishtree-attempt/$${slug}](https://github.com/fishtree-attempt/$${slug})" >> $@;\
	 done



