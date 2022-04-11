# Transitioning Carpentries Lessons

This repository will contain scripts for transitioning Carpentries lessons built
from [the all-in-one infrastructure](https://github.com/carpentries/styles) (aka 
"The Lesson Template") to [the decoupled/centralised 
infrastructure](https://carpentries.github.io/sandpaper-docs) (aka "The Lesson
Infrastructure"). 

![A diagram showing the transition between the former lesson structure (styles) to the new lesson structure (workbench).
It shows episodes flowing to episodes, extras flowing to learners and instructors, and figures, data, and files flowing
to subfolders under episodes. Other folders are in grey with no arrows indicating that they are discarded.](fig/folder-flow.svg)


The process works in the following steps:

1. (manual step) create file named `program/lesson.R` (e.g. `swcarpentry/r-novice-gapminder.R`)
1. provision template with [`establish-template.R`](establish-template.R)
1. add/fetch git submodule of the repository for reference with [`fetch-submodule.sh`](fetch-submodule.sh)
1. run [`filter-and-transform.sh`](filter-and-transform.sh), which does the following
   i. performs a fresh clone of the submodule into `sandpaper/program/lesson/`
   ii. filter commits with [`git-filter-repo`](https://htmlpreview.github.io/?https://github.com/newren/git-filter-repo/blob/docs/html/git-filter-repo.html)
   iii. apply transformations in [`transform-lesson.R`](transform-lesson.R)
   iv. apply additional needed transformations in `program/lesson.R`
   v. creates commits and records them in `sandpaper/program/lesson.json`


**Note: Not all of the repositories represented here are official Carpentries Lessons. Only swcarpentry, datacarpentry, librarycarpentry, and carpentries lessons are official**

These scripts require a setup with R and access to the internet. It is currently
a work in progress and may evolve in the future.

The repositories that have previously been transferred can be found in [repos.md](repos.md).

## Usage

### Adding a new lesson

To add a lesson for translation, there are two steps:

1. add an R script with the repository name under a folder with the organisation
   name (e.g. `swcarpentry/r-novice-gapminder.R` or 
  `datacarpentry/R-ecology-lesson.R`). 
2. run `make`

### Bootstrapping infrastructure

To bootstrap the infrastructure without converting lessons, you can run the
following targets:

```bash
make template modules
```

This will bootstrap the packages used for the scripts, create the sandpaper 
template, and update the git submodules

### Updating R packages

To update the R packages used for translation, you can run `make update`

### Individual targets

To make an individual target, run 

```bash
make sandpaper/datacarpentry/new-R-ecology-lesson.json
```

### Parallel processing

To run everything from scratch with 7 threads

```bash
rm -rf sandpaper/
make -j7
```

For the curious, this is the path of the makefile for a single target:

![an example of the target sandpaper/swcarpentry/r-novice-gapminder.json](example-path.png)


### Sending lessons to GitHub

Because my changes will be stacked on top of the last commit of the previous
lesson, every time a new commit is added or I change something in the build
process, I will need to burn it all down and rebuild these lessons so that I do
not end up with weird merge conflicts or a force-pushed history, thus I need to
be able to do the following from the command line:

1. create repositories 
2. assign the repositories to bot teams.
3. destroy repositories that are outdated in the past.

I have created a sandbox organisation where I know I can break things if I need
to set up or tear down things. I have given the 
[Carpentries Apprentice](https://github.com/znk-machine) admin access so that I
do not risk my own token being used to create and delete repositories.

To send lessons to GitHub, you need to make sure you have the correct tokens
set up from GitHub in addition to your GitHub PAT, which will give you repo
access:

 - [NEW\_TOKEN](https://github.com/settings/tokens/new?scopes=repo,workflow&description=GITHUB_NEW) to create and push the new repository
 - [BOT\_TOKEN](https://github.com/settings/tokens/new?scopes=admin:org&description=GITHUB_BOT) to assign the bots team to the repository
 - [DEL\_TOKEN](https://github.com/settings/tokens/new?scopes=delete_repo&description=GITHUB_DEL) to delete a repository.

In testing, I set these tokens to expire the next day.

Because I do not want to keep these hanging around my BASH environment, and 
because I want to be difficult, I am using a [vault secrets engine called
tr](https://learn.hashicorp.com/tutorials/vault/getting-started-secrets-engines?in=vault/getting-started) by running `vault server -dev` in a separate window and then:

```bash
vault secrets enable -path=tr kv && \
vault kv put tr/auth bot=<token> del=<token> new=<token>
```

From there, I can use [`./pat.sh bot`](pat.sh) to extract the bot token so that
it can be used with the [`create-test-repo.sh`](create-test-repo.sh) script:

```bash
BOT_TOKEN=$(./pat.sh bot) NEW_TOKEN=$(./pat.sh new) \
create-test-repo.sh carpentries-incubator/citable-software bots fishtree-attempt
```

There is also the `github` target which will first delete any repositories you
have created with this script and then re-create and upload them:

```bash
BOT_TOKEN=$(./pat.sh bot) DEL_TOKEN=$(./pat.sh del) \
make github
```

### Notes

The `transform-lesson.R` script is meant to serve as a generalized method for
converting lesson content from one engine to the other. It does the majority of
the heavy lifting, but it can not completely convert lessons perfectly. Because
each lesson is built in a _slightly_ different way and kramdown (Jekyll's 
markdown parser) allows for patterns that would be invalid in any other parser,
the conversion is not 100%. This additional R script allows you to make
additional changes such as moving files or fixing errors. This file can be blank
if there are no changes you wish to make

If your lesson is in a repository that does not belong to an official carpentries
account, you will need to append the `DIRS` varaible in the makefile.

## Requirements

This repository has package management via {renv}, so there are two steps to
getting set up:

1. install R
2. Run `make renv/library/`
 
This will restore the renv session to the correct state so that you can convert
the lessons contained with `make`

The packages used in this script are the same packages that are used in 
{sandpaper}, you can [follow the setup instructions to get this script working
](https://carpentries.github.io/sandpaper-docs/setup).

## Post translation

After a lesson is translated it lives in a brand new repository that will have
three commits:

1. the bootstrap of the new lesson
2. the first pass of `transform-lesson.R`
3. Any other changes dictated by your custom script. 

To get this to GitHub, I like to use the {usethis} package. For this operation,
you _will need_ to set up your GitHub PAT. [I wrote up a tutorial to set up your
PAT via R that may be helpful](https://carpentries.github.io/sandpaper-docs/github-pat.html).

If, however, you are on Linux and find yourself in credentials hell, you might
find solace in [Danielle Navarro's blog post from August on setting up credentials for Ubuntu](https://blog.djnavarro.net/posts/2021-08-08_git-credential-helpers/)


### Steps for uploading the lesson and activating github pages

Here, I'm using the [data-lessons](https://github.com/data-lessons), which was
the organisation that eventually migrated to DataCarpentry and now serves as a
kind of sandbox for The Carpentries. 

You should use your own account for this as you will likely not have access to
the data-lessons organisation.

```r
# In the directory of the new lesson
library(usethis)
use_github(organization = "data-lessons")
```

After a few minutes, the lesson will be sent to GitHub and build the site, but
the pages need to be activated, which you can do via usethis:

```r
# In the directory of the new lesson
library(usethis)
use_github_pages()
```

