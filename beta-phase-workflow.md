## Rationale

The beta phase involves the methodical transition of a lesson from using
[carpentries/styles](https://github.com/carpentries/styles) to using [The
Workbench](https://carpentries.github.io/workbench). 

The [lesson transition workflow repository](https://github.com/carpentries/lesson-transition)
is responsible for coallating the scripts required for performing the transition
and pushing lessons to https://github.com/fishtree-attempt and is core to the 
beta phase of The Workbench.

This document is an attempt to document the different stages of the beta phase
and the steps that are required in each part:

**NOTE:** This assumes that the scripts to build these lessons have been
established, cleaned up, and tested on GitHub using the `make github` workflow.

### Pre-Beta stage

In this stage a _snapshot_ of a lesson is transformed and pushed to the
fishtree-attempt organisation. It has (an extra workflow)[workbench-beta-phase.yml]
that will push the lesson to the preview domain. 

The steps for releasing a lesson to the pre-beta stage are roughly this:

#### Prepare the styles lesson

1. update styles. You can use any method you want, but I prefer to use this in my fork:
   ```sh
   git switch -c update-styles
   curl -L https://github.com/carpentries/actions/raw/main/update-styles/update-styles.sh | bash /dev/stdin/
   ```
2. add the variables to `_config.yml` (make sure the dates are correct)
  - life_cycle: "transition-step-1"
  - transition_date_prebeta: '2022-12-12' # pre-beta stage (two repos, two sites)
  - transition_date_beta: '2023-02-06' # beta stage (one repo, two sites)
  - transition_date_prerelease: '2023-04-03' # pre-release stage (one repo, one site)
3. Tag the maintainers in the pull request(s)

#### Run the transformation

At the moment, the transformation is _mostly_ automated, but because it only has
to be done once weekly, it is okay for these steps to be manual.

1. Open [The Makefile](Makefile)
2. Remove the first `#` after the `PREBETA` variable (line 25) to enter the next
   lesson into pre-beta
3. Run `make prebeta/<carpentry>/<lesson>.json` to generate the pre-beta version.
4. Double check to make sure everything is transformed correctly.
5. add the hash inside `prebeta/<carpentry>/<lesson>-invalid.hash` to [invalid-hashes.json](https://github.com/carpentries/reactables/blob/main/workbench/invalid-hashes.json)
6. Enter the newly-created repository. Run `push --force --set-upstream origin main`
7. Move back to the main folder
8. Run `curl https://api.github.com/fishtree-attempt/<lesson> > prebeta/<carpentry>/<lesson>-status.json`
9. Commit the new files
10. Run `git tag -s pre-beta_<lp>/<lesson>` and add a message about this being the state of this repository when the lesson went into pre-beta
11. Go to to https://github.com/fishtree-attempt/<lesson>/settings/secrets/actions and update the AWS tokens


### Beta Stage


Lessons in this stage will undergo a lesson release of the styles version and a
snapshot of the repository, including issues and pull requests, will be
archived. The default branches (`gh-pages` and `main`) will be renamed and a
transformation of the default branch will be inserted as `main`:

| branch | transformation | new name |
| ------ | -------------- | -------- |
| `gh-pages` | none | `legacy/gh-pages` |
| `main` | none | `legacy/main` |
| [default] | [remove styles commits](README.md#motivation); transform syntax to Workbench | `main` |

The default lesson URL will still be served from the `legacy/gh-pages` branch
during this period. **All new changes to the lesson will be made to the
workbench version.**

Here are the steps for the transition to the beta stage:

### Backup Lesson repository (a week before the transition)

GitHub provides a mechanism for exporting the entire lesson repository as a
GitHub backup. This will backup not only the Git repository, but also the
associated pull requests, issues, and other metadata.

This can be achieved with https://github.com/ropensci-org/gitcellar, but I have
to test and come up with the workflow.

### Prepare Lesson Release (a week before the transition)

1. merge latest styles into the lesson
2. clone the latest version of https://github.com/carpentries/chisel
3. insert the shared mailmap file (from lastpass) into `chisel/inst/mailmap/mailmap.txt`
4. open R in the `chisel/` directory
  1. if needed, install devtools with `install.packages("devtools")`
5. load chisel with `devtools::load_all()`
6. Generate lesson release zenodo file in this manner (example for datacarpentry/r-raster-vector-geospatial):
  ```r
  res <- tibble::tribble( # constructs a table visually
    ~name,      ~owner,          ~repo,
    "main",     "datacarpentry", "r-raster-vector-geospatial",
    "template", "carpentries",   "styles"
  ) |>
    generate_zenodo_json( # updates the zenodo JSON from the table
      local_path = "~/Documents/Carpentries/Git/datacarpentry/r-raster-vector-geospatial",
      editors = c("jsta", "drakeasberry", "arreyves"),
      ignore = c("francois.michonneau@gmail.com", "zkamvar@carpentries.org")
    )
  ```
  where the following variables mean the following things:
  - `local_path` the path to your local copy of the lesson. The purpose of this is purely to deposit the zenodo json file
  - `editors` these are the **Maintainers** github handles
  - `ignore` emails for people whose commits will still appear in the lesson after filtering out commits from styles
7. commit and push that zenodo json file to GitHub and create a release. It should automatically update on GitHub


### Transform the Lesson


The transformation steps is very similar to the prebeta stage with the exception
that this will also automatically transform the GitHub repository (see 
`setup_github()` in [functions.R](functions.R). It will do the following:

1. transform `gh-pages` (and `main` if it exists) to be `legacy/` branches and **lock** them
2. enabling github actions (if not enabled already)
3. **force-pushing the main branch** and setting it as default
4. add **branch protection for the main branch** requiring pull requests
5. **force-pushing the gh-pages branch** from an orphan branch containing a
   workflow that will auto-close any new PRs to that branch:
   [close-pr.yaml](close-pr.yaml)
6. set the maintainer team to **read only** (TODO)

Because MANY of these operations require the GitHub API with appropriate
permissions, only those with admin access to a repository can perform these
actions. My personal access token allows for this with the following scopes:
`repo, user, workflow`

When the maintainers are ready for access, I they will comment on the issue
that entered them into the beta phase and then I will grant them access.

NOTE: it is currently not possible to have fine-grained permissions in teams,
so I will add them to a new team that _does_ have write access until everyone
has completed the checkin. 

### What to Expect

A repository that recently update to use the beta stage of the workbench can 
be a bit bewildering. When you visit the GitHub page, you will notice that the
default branch is now called `main` and the folder structure looks different. 

When you look at the list of branches you will notice a few things:

1. The main branch is protected. This means that you will need to make a pull
   request before you can push to the main branch.
2. There is a `legacy/gh-pages` branch. For most lessons, this used to be the
   default branch, but in the beta phase, we have renamed it and locked it.
   There should be no need to edit this branch.

#### Pull Requests

Before the second stage of the beta phase, **it is important to resolve all of
the open pull requests.** Remeber that it's okay to say no and to invite the
contributor to open an issue, citing the pending transformation of your lesson.

Any pull requests left open before the transition will point to the locked
`legacy/` branch and must be re-opened from a brand new fork in order to be
considered.

For example, someone suggested a change a week before the transition and none
of the maintainers had the capacity to address the pull request. Because of
this, the pull request is now in a state where the only path foward is to close
it because the base branch of the pull request is locked.

Speaking from experience, addressing really old issues or pull requests is hard
because it can feel like you are letting the contributor down, but it is
important to remember that telling someone that their pull request is no longer
valid is far more demotivating than gently saying and providing instructions to
follow up in an issue.

I'm going to provide a small script that you can use when addressing these pull
requests. This will include instructions for a contributor to delete and 
re-fork their copy of the repository.

As a reminder, a **clone** is a copy of a lesson repository to your computer and
a **fork** is a copy of a lesson repository to your GitHub account. We will talk
about clones later.

#### Forks

Anyone who has created a fork of the lesson and intends to continue contributions
must delete and re-fork. To do that, they can go to settings, scroll all the way
down to the "Danger Zone" section, click "Delete this repository", write the
name of the repository in the box and then click "I understand the consequences,
delete the repository".

After deleting their fork, they can re-fork using the same process they used 
previously, by clicking the fork button at the top of the lesson repository. 

Again, this is the ONLY way to update a fork. To illustrate why, I will show you
what happens if you try to use GitHub's method of "synchronizing a fork". 

All GitHub forks will have a button that allows you to synchronize the default
branch of your fork with the corresponding branch of the lesson repository. 

The problem is: the corresponding branch has a completely different commit
history and git WILL merge it, regardless of how nonsensical the lesson
repository becomes.

If someone has changes they want to contribute, synchronises their branch, and
then attempts to create a pull request, that pull request will automatically
close, giving them instructions they can use to delete and re-fork their 
repository.


#### Clones aka, working on a lesson locally

If you have a clone, like a fork, the easiest thing to do is to re-clone the
repository. You will want to move your old repository to a new folder called
`old-[repository-name]`. I can not stress this enough: make a copy before you do
anything. That way if something unexpected happens, you can restore from the 
copy.

After you change the name of your existing repository, you can clone the new
version using the standard `git clone` command.

As I said, it _is_ possible to update your local repository, and it involves the
same process that GitHub recommends when you change a branch name. I've
documented the steps needed for both markdown and R Markdown-based lessons, and
you are free to try them at your own risk.

Now I want to show you what happens if you attempt to pull from the repository
without first re-cloning or moving the branch names.

When you run `git pull`, you might see a few new branches created and then git
will give you an error saying that it cannot merge branches with unrelated
histories.









