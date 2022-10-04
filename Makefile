SHELL = bash
DIRS := swcarpentry \
	datacarpentry \
	librarycarpentry \
	carpentries-incubator \
	carpentries-lab \
	carpentries
INPUTS  := $(foreach dir, $(DIRS), $(wildcard $(dir)/*R))
MODULE  := $(patsubst %.R, %/.git, $(INPUTS))
GITHUB  := $(patsubst %.R, sandpaper/%-status.json, $(INPUTS))
TARGETS := $(patsubst %.R, sandpaper/%.json, $(INPUTS))
PREREQS := renv/library/ template/ filter-and-transform.sh functions.R

.PHONY = all
.PHONY = modules
.PHONY = template
.PHONY = update
.PHONY = github
.PHONY = info

all: restore template/ $(TARGETS) repos.md
modules: $(MODULE)
	git submodule foreach 'git checkout main || git checkout gh-pages'
	git submodule foreach 'git pull'

template: template/
github: $(GITHUB)
update:
	@GITHUB_PAT=$$(./pat.sh) Rscript -e 'renv::record(paste0("renv@", packageVersion("renv"))); renv::restore(library = renv::paths$$library()); renv::update(library = renv::paths$$library()); renv::snapshot()'
restore:
	@GITHUB_PAT=$$(./pat.sh) Rscript -e 'renv::restore(library = renv::paths$$library())'

bump: 
	@for i in $(GITHUB); \
		do j="$${i%%-status.json}"; \
			gh workflow run sandpaper-main.yaml --repo "fishtree-attempt/$${j##*/}" -f reset=true; \
		done

info: 
	@for i in $(GITHUB); \
		do [[ -e $${i} ]] && printf "$$(jq .created_at < $${i})\t$${i##sandpaper/}\n" || echo "$${i} does not exist"; \
		done

status:
	@for i in $(GITHUB); \
		do [[ -e $${i} ]] && printf "$$(./page-status-test-repo.sh $${i/-status//})\t$${i##sandpaper/}\n" || echo '$${i} does not exist'; \
		done

touchy:
	@for i in $(TARGETS); do touch $${i}; done

sandpaper/%-status.json : sandpaper/%.json create-test-repo.sh delete-test-repo.sh
	@echo "Creating $@"
	@bash delete-test-repo.sh $* || echo "No repository to delete"
	@NEW_TOKEN=$$(./pat.sh) bash create-test-repo.sh $* bots fishtree-attempt

renv/library/ :
	@GITHUB_PAT=$$(./pat.sh) Rscript -e 'renv::restore()'

template/ : establish-template.R renv.lock renv/library/
	@GITHUB_PAT=$$(./pat.sh) Rscript $< -w workbench-beta-phase.yml $@

# $(MODULE) Get a submodule of a repository
%/.git : %.R
	bash fetch-submodule.sh $@

# $(TARGETS) Copy and transform a lesson
sandpaper/%.json : %.R %/.git $(PREREQS) transform-lesson.R
	PATH="$(PWD)/git-filter-repo/git-filter-repo:${PATH}" bash filter-and-transform.sh $@ $<

sandpaper/datacarpentry/R-ecology-lesson.json : datacarpentry/R-ecology-lesson.R datacarpentry/R-ecology-lesson/.git $(PREREQS)
	bash filter-and-transform.sh $@ $< || echo "UGH"

repos.md : $(TARGETS)
	@rm -f repos.md
	@for i in $^;\
	 do repo=$$(echo $$i | sed -e 's/.json//');\
	 slug=$$(basename $${repo});\
	 account=$$(dirname $${repo});\
	 echo "- [$${repo##sandpaper/}](https://github.com/$${repo##sandpaper/}) -> [fishtree-attempt/$${slug}](https://github.com/fishtree-attempt/$${slug})" >> $@;\
	 done



