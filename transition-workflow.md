## Workflow for transitioning lessons

Note: this is not the process for _releasing_ lessons. This is the iteration
process for setting up the lesson transitions for release. If a lesson is ready
to be released to The Workbench, see the [Release Workflow](release-workflow.md).

To get a list of lessons and the tasks to complete, run the following in R:

```r
source("functions.R")
get_tasks()
```

### Register a lesson submodule to this repository

To register a lesson submodule, uset the following steps:

1. run `./add-lesson.sh <org>/<repo>`. This will add an R script that will
   serve as lesson-specific modificatons after the generic `transform()`
   function from [`functions.R`](functions.R).
2. open an issue with https://github.com/carpentries/lesson-transition/issues/new
   and give it the same title as the lesson you are transitioning in the
   `<org>/<repo>` format. Tag this issue with the `lesson` and `run pending` 
   tags.

### First transition test

The transition will do the following things to the lesson after creating a copy:

 - remove infrastructure commits from the lesson
 - rename folders
 - update syntax from kramdown -> pandoc
 - fix http -> https links
 - fix level 1 -> level 2 headings
 - fix non-sequential headings
 - fix custom heading IDs
 - split contents of the `_extras` folder to `learners` and `instructors`

#### Running

To run the first transition test for this lesson, make sure you have R installed
and then run, replacing `<org>/<repo>` with the lesson of interest

```sh
make sandpaper/<org>/<repo>.json
```

For example, here's how to process the librarycarpentry shell lesson:

```sh
make sandpaper/librarycarpentry/lc-shell.json
```

There will be a lot of output from the transition. It may work it may not. 

#### Detecting Issues

You should be able to detect issues for a given run by searching for the 
reporting patterns from {pegboard}:

```sh
grep -e '^.*md:' sandpaper/<org>/<repo>-filter.log
```

For example, here's the librarycarpentry shell lesson:


```sh
grep -e '^.*md:' sandpaper/librarycarpentry/lc-shell-filter.log
```


Note: this will NOT catch issues with lessons that do not build. 

There will be some common issues that you [should report](#reporting-issues) and
fix in one of three ways:

1. make a one-off fix in the lesson script
2. minor, but annoying syntax --- open a pull request for the maintainers to fix (this is for minor syntax issues)
3. issues that keep popping up --- modify the `transform()` function in `functions.R`

##### missing files

A lot of times, a missing file is due to the transition script missing some
jekyll-formatted links (e.g. `_extras/some-file.md`). The solution is to use the
`validate_links()` function to find these links, modify them in place, and then
write them back to markdown. 

##### missing anchors

When you get a missing anchor reference and it is in the `reference.md` file, it
is likely due to the fact that Jekyll auto-links definition lists while pandoc
does not. To fix this, use `dl_auto_id(to("learners", "reference.md"))` in the
lesson-specific script. This will fix those anchors 

#### renv issues

If you are working on an R-based lesson, then you might run into issues with
{renv} that will be reported like so:

```r
sandpaper/swcarpentry/r-novice-gapminder-es/episodes/06-data-subsetting.Rmd
-----------------------------------------------------------------------------------------------------------------------------------------------

ERROR 1: <text>:103:1: unexpected '<'
102: 
103: <
     ^

sandpaper/swcarpentry/r-novice-gapminder-es/episodes/13-dplyr.Rmd
-------------------------------------------------------------------------------------------------------------------------------------

ERROR 1: <text>:207:1: unexpected '>'
206: 
207: >
     ^

sandpaper/swcarpentry/r-novice-gapminder-es/episodes/15-knitr-markdown.Rmd
----------------------------------------------------------------------------------------------------------------------------------------------

ERROR 1: <text>:1:11: unexpected '\\'
1: round(some\
```

The first two errors means that something went wrong with the translation process
and some block quotes with code inside them still exist. Some of these can be
fixed via code (see [`swcarpentry/r-novice-gapminder.R`](swcarpentry/r-novice-gapminder.R))
but often some are better fixed by deleting a single line (see 
[swcarpentry/r-novice-gapminder-es#136](https://github.com/swcarpentry/r-novice-gapminder-es/pull/136)).

#### Reporting issues

When the run is complete you can open the `sandpaper/<org>/<repo>-filter.log`
file that is produced by the run (though it's never committed). In this file,
you will see the output you saw when you ran the test script. You will want to
make sure to check the link validation section.

Here's an example from [swcarpentry/git-novice](https://github.com/carpentries/lesson-transition/issues/72)

```markdown
── Validating Internal Links and Images ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
! There were errors in 32/220 links
◌ Some link anchors for relative links (e.g. [anchor]: link) are missing
◌ Some linked internal files do not exist
◌ Images need alt-text <https://webaim.org/techniques/hypertext/link_text#alt_link>
◌ Avoid uninformative link phrases <https://webaim.org/techniques/hypertext/link_text#uninformative>

episodes/01-basics.md:25 [image missing alt-text]: fig/phd101212s.png
episodes/05-history.md:303 [image missing alt-text]: fig/git_staging.svg
episodes/07-github.md:39 [missing file]: [](fig/github-create-repo-01.png)
episodes/07-github.md:48 [missing file]: [](fig/github-create-repo-02.png)
episodes/07-github.md:53 [missing file]: [](fig/github-create-repo-03.png)
episodes/14-supplemental-rstudio.md:85 [image missing alt-text]: fig/RStudio_screenshot_navigateexisting.png
episodes/14-supplemental-rstudio.md:98 [image missing alt-text]: fig/RStudio_screenshot_editfiles.png
episodes/14-supplemental-rstudio.md:112 [image missing alt-text]: fig/RStudio_screenshot_review.png
episodes/14-supplemental-rstudio.md:134 [image missing alt-text]: fig/RStudio_screenshot_viewhistory.png
index.md:20 [missing file]: [version control](reference.md#version-control)
instructors/instructor-notes.md:39 [uninformative link text]: [this](https://github.com/rgaiacs/swc-shell-split-window)
learners/reference.md:21 [missing anchor]: [commit](#commit)
learners/reference.md:21 [missing anchor]: [version control](#version-control)
learners/reference.md:22 [missing anchor]: [repository](#repository)
learners/reference.md:25 [missing anchor]: [changeset](#changeset)
learners/reference.md:26 [missing anchor]: [version control](#version-control)
learners/reference.md:26 [missing anchor]: [repository](#repository)
learners/reference.md:32 [missing anchor]: [version control system](#version-control)
learners/reference.md:34 [missing anchor]: [resolve](#resolve)
learners/reference.md:38 [missing anchor]: [Protocol](#protocol)
learners/reference.md:43 [missing anchor]: [repository](#repository)
learners/reference.md:47 [missing anchor]: [HTTP](#http)
learners/reference.md:47 [missing anchor]: [SSH](#ssh)
learners/reference.md:50 [missing anchor]: [repository](#repository)
learners/reference.md:51 [missing anchor]: [commits](#commit)
learners/reference.md:54 [missing anchor]: [version control](#version-control)
learners/reference.md:55 [missing anchor]: [commits](#commit)
learners/reference.md:59 [missing anchor]: [conflicts](#conflict)
learners/reference.md:60 [missing anchor]: [version control](#version-control)
learners/reference.md:63 [missing anchor]: [commit](#commit)
learners/reference.md:73 [missing anchor]: [protocol](#protocol)
learners/reference.md:80 [missing anchor]: [commit](#commit)
```



We notice a few issues that we cannot fix with the automation (`image missing alt text`)
and some issues that we must fix (`missing file` and `missing anchor`).

To report these issues, copy this list, and paste it into the issue you created
above with a tasklist:

````markdown

 - [ ] fix broken image links
 - [ ] fix definition list glossary references (not shown)

```markdown
── Validating Internal Links and Images ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
! There were errors in 32/220 links
◌ Some link anchors for relative links (e.g. [anchor]: link) are missing
◌ Some linked internal files do not exist
◌ Images need alt-text <https://webaim.org/techniques/hypertext/link_text#alt_link>
◌ Avoid uninformative link phrases <https://webaim.org/techniques/hypertext/link_text#uninformative>

episodes/01-basics.md:25 [image missing alt-text]: fig/phd101212s.png
episodes/05-history.md:303 [image missing alt-text]: fig/git_staging.svg
episodes/07-github.md:39 [missing file]: [](fig/github-create-repo-01.png)
episodes/07-github.md:48 [missing file]: [](fig/github-create-repo-02.png)
episodes/07-github.md:53 [missing file]: [](fig/github-create-repo-03.png)
episodes/14-supplemental-rstudio.md:85 [image missing alt-text]: fig/RStudio_screenshot_navigateexisting.png
episodes/14-supplemental-rstudio.md:98 [image missing alt-text]: fig/RStudio_screenshot_editfiles.png
episodes/14-supplemental-rstudio.md:112 [image missing alt-text]: fig/RStudio_screenshot_review.png
episodes/14-supplemental-rstudio.md:134 [image missing alt-text]: fig/RStudio_screenshot_viewhistory.png
index.md:20 [missing file]: [version control](reference.md#version-control)
instructors/instructor-notes.md:39 [uninformative link text]: [this](https://github.com/rgaiacs/swc-shell-split-window)
```
````


As you continue to modify the lesson-specific script, you can continue to add
checks to the checklist and run `get_tasks()` from `functions.R` to monitor what
needs to be complete.



