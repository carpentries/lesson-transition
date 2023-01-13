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




