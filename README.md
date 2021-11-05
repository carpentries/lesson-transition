# Transitioning Carpentries Lessons

This repository will contain scripts for transitioning Carpentries lessons built
from [the all-in-one infrastructure](https://github.com/carpentries/styles) (aka 
"The Lesson Template") to [the decoupled/centralised 
infrastructure](https://carpentries.github.io/sandpaper-docs) (aka "The Lesson
Infrastructure"). The process works in the following steps:

1. (manual step) create file named `program/lesson.R` (e.g. `swcarpentry/r-novice-gapminder.R`)
1. provision template with [`establish-template.R`](establish-template.R)
1. add/fetch git submodule of the repository for reference with [`fetch-submodule.sh`](fetch-submodule.sh)
1. run [`filter-and-transform.sh`](filter-and-transform.sh), which does the following
   i. performs a fresh clone of the repository into `sandpaper/program/lesson/`
   ii. filter commits with [`git-filter-repo`](https://htmlpreview.github.io/?https://github.com/newren/git-filter-repo/blob/docs/html/git-filter-repo.html)
   iii. apply transformations in [`transform-lesson.R`](transform-lesson.R)
   iv. apply additional needed transformations in `program/lesson.R`
   v. creates commits and records them in `sandpaper/program/lesson.json`


**Note: Not all of the repositories represented here are official Carpentries Lessons. Only swcarpentry, datacarpentry, librarycarpentry, and carpentries lessons are official**

These scripts require a setup with R and access to the internet. It is currently
a work in progress and may evolve in the future.

The repositories that have previously been transferred can be found in [repos.md](repos.md).

## Usage

To add a lesson for translation, there are two steps:

1. add an R script with the repository name under a folder with the organisation
   name (e.g. `swcarpentry/r-novice-gapminder.R` or 
  `datacarpentry/R-ecology-lesson.R`). 
2. run `make`

To make an individual target, run 

```bash
make sandpaper/datacarpentry/new-R-ecology-lesson.json
```

To run everything from scratch with 7 threads

```bash
rm -rf sandpaper/
make -j7
```

For the curious, this is the path of the makefile for a single target:

![an example of the target sandpaper/swcarpentry/r-novice-gapminder.json](example-path.png)


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

This repository has package management via {renv} and you can install the 
package via {renv} by opening R and running:

```r
renv::restore()
```

This will restore the renv session to the correct state so that you can convert
the lessons contained. 

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

