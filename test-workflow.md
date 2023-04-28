## Testing the workbench transition release

Testing the workbench transition release process, we make a copy of an
inconsequential lesson repository to the fishtree-attempt organisation, create
a pull request from an account without access, and then run the release
workflow. 

### Motivation 

When we run tests that go into the `sandpaper/` directory, the commits are
modified by the contents of `message-callback.txt`, which will mask any explicit
references to users or pull requests. This way, when we push these tests to 
GitHub, users do not get extra notifications that they were mentioned in a new
commit and pull requests do not get new commits referencing them.

When testing the release workflow, however, it's difficult to do this because we
actually want to test to make sure that the process will run without the commit
message filtering. Thus, we use a donor repository. In this case, we use
<https://github.com/sgibson91/cross-stitch-carpentry> as a baseline. This was a
testing repository initially and it is a good candidate because the contributors
did not mention user IDs in commits, so they would not be notified If I push
their commits up. Moreover, it was a test repository for the Turing Way that
they no longer use.

### Provisioning

There are two scripts used to provision the repository and the external pull
request: [`create-transition-test.R`](create-transition-test.R) and 
[`create-ravmakz-pr.R`](create-ravmakz-pr.R). 

#### Create Transition Test

This script will destroy and then create the `znk-transition-test` repository
from <https://github.com/sgibson91/cross-stitch-carpentry>. Note that this can
also be used to create a transition test a different repository, but I have not
tested it. 

There are two steps:

1. Obtain a Fine Grained PAT with access to all repositories in the 
   <https://github.com/fishtree-attempt> organisation. It must have Read and
   Write access to actions, administration, code, pages, pull requests, and
   workflows and to members.
2. run the script with the token set to `SETUP_PAT`

```sh
 SETUP_PAT=github_XXXX Rscript create-transition-test.R
```


The output will look something like this:

<details>
<summary>Output of create-transition-test.R</summary>

```
Linking to libgit2 v1.4.2, ssh support: YES
Global config: /home/zhian/.gitconfig
Default user: Zhian N. Kamvar <zkamvar@gmail.com>
ℹ creating a new repository called `fishtree-attempt/znk-transition-test`
ℹ importing `sgibson91/cross-stitch-carpentry` to `fishtree-attempt/znk-transition-test`
ℹ Setting gh-pages as default
ℹ Setting permissions
trying URL 'https://github.com/carpentries/actions/raw/main/update-styles/update-styles.sh'
Content type 'text/plain; charset=utf-8' length 2448 bytes
==================================================
downloaded 2448 bytes

Running bash /tmp/RtmpaLsTG4/file99447fafb9ef
::group::Fetch Styles
From https://github.com/carpentries/styles
 * [new branch]      gh-pages   -> styles-ref
 * [new branch]      gh-pages   -> styles/gh-pages
::endgroup::
::group::Synchronize Styles
There are 238 changes upstream
Testing merge using recursive strategy, accepting upstream changes without committing
Automatic merge went well; stopped before committing as requested
Creating squash commit later
/tmp/RtmpaLsTG4/file99447fafb9ef: line 80: $GITHUB_OUTPUT: ambiguous redirect
Error in "callr::run(\"bash\", run_styles, echo = TRUE, echo_cmd = TRUE)" : 
  ! System command 'bash' failed
Error in eval(handler$expr, handler$envir) : 
  argument is missing, with no default
Calls: <Anonymous> -> deferred_run -> execute_handlers
```

</details>

This might error, but that's okay. You can check to make sure the repository is
up and running by going to <https://github.com/fishtree-attempt/znk-transition-test>.

#### Create ravmakz PR

To create the PR from an external account, we use the `ravmakz` GitHub account, 
which does not have permissions in the organization to create a pull request.
This demonstrates what happens to open pull requests after the transition.

Because this involves a separate account, we obtain the token interactively.
To run this, open R and run:

```r
source("create-ravmakz-pr.R")
```

This will prompt you to create a token and paste it into your R console. After
that, it will create the Pull Request.

Once you have completed these two steps, you will be ready to test the transition.

### Transition

The transition step uses the same machinery as the release process. Once this is
done, if you want to try again, you must go back to the [provisioning 
instructions](#provisioning) to reset the source repository.

#### Setup 

To set up the transition test, it's best to be in a new branch unless you want
to damange things (you don't, trust me). 

1. create a new branch and remove `fishtree-attempt/*` from the `.gitignore`
2. create a `fishtree-attempt/znk-transition-test.R` file
3. Get a token for the release process (see [the release workflow
   documentation](release-workflow.md#fine-grained-pat-preferred)) for the
   `fishtree-attempt` organisation
4. Get an _additional_ GitHub token that has admin and repository rights that
   will allow you to destroy and set up the repository. I suggest a
   fine-grained token:
   To create a new token, head over to <https://github.com/settings/personal-access-tokens/new> and then set the resources this way:
   
  | parameter | value | notes |
  | --------- | ----- | ----- |
  | Resource owner | fishtree-attempt | |
  | Repository access | All repositories | we are deleting and re-forming a repository; this is necessary |
  | Repository permissions | Read and Write on **actions, administration, contents, pages, pull requests, workflows** |  |
  | Organization permissions | Read and Write access to members |  |

#### Running

Once you do that, you will want to create a `test-release` key in your vault
store that will be read as the `RELEASE_PAT` environment variable in the release
process. Head to: <https://github.com/settings/tokens?type=beta> and edit the
token so that it ONLY has access to the `fishtree-attempt/znk-transition-test`
repository. Add this token to the `test-release` in your vault (see the release
workflow for details)

From here, you can run the workflow by running:

```sh
bash run-transition-test.sh
```


> **Note**
> 
> If you have previously run this test _and you **should**_, then there will be
> an interactive step that will do a merge commit update of the submodule that
> will be hiding in the `.git/modules` folder. This is normal. Just accept the
> merge when the commit message window pops up.

The output should look something like this.

<details>
<summary>output of workflow</summary>


```sh
$ bash run-transition-test.sh 
Beginning transition test in 5 seconds
Beginning transition test in 3 seconds
Beginning transition test in 2 seconds
Beginning transition test in 1 second
bash fetch-submodule.sh fishtree-attempt/znk-transition-test/.git
Nothing to do for fishtree-attempt/znk-transition-test/.
ℹ creating a new sandpaper lesson
ℹ Updating workflows
ℹ Workflows/files updated:
- .github/workflows/pr-close-signal.yaml (modified)
- .github/workflows/pr-comment.yaml (modified)
- .github/workflows/pr-post-remove-branch.yaml (modified)
- .github/workflows/pr-preflight.yaml (modified)
- .github/workflows/pr-receive.yaml (modified)
- .github/workflows/README.md (modified)
- .github/workflows/sandpaper-main.yaml (modified)
- .github/workflows/sandpaper-version.txt (modified)
- .github/workflows/update-cache.yaml (modified)
- .github/workflows/update-workflows.yaml (modified)
ℹ Removing boilerplate
ℹ Provisioning pandoc
✔ Version '2.19.2' is now the active one.
ℹ Pandoc version also activated for rmarkdown functions.
pandoc 2.19.2
Compiled with pandoc-types 1.22.2.1, texmath 0.12.5.2, skylighting 0.13,
citeproc 0.8.0.1, ipynb 0.2, hslua 2.2.1
Scripting engine: Lua 5.4
User data directory: /home/zhian/.pandoc
Copyright (C) 2006-2022 John MacFarlane. Web: https://pandoc.org
This is free software; see the source for copying conditions. There is no
warranty, not even for merchantability or fitness for a particular purpose.
bash fetch-submodule.sh fishtree-attempt/znk-transition-test/.git
Checking fishtree-attempt/znk-transition-test/...
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  8257  100  8257    0     0  28870      0 --:--:-- --:--:-- --:--:-- 28870
... Creating new submodule in fishtree-attempt/znk-transition-test/
Reactivating local git directory for submodule 'fishtree-attempt/znk-transition-test'
... checking out 'gh-pages' branch
Already on 'gh-pages'
Your branch is up to date with 'origin/gh-pages'.
... pulling in changes
remote: Enumerating objects: 549, done.
remote: Counting objects: 100% (7/7), done.
remote: Compressing objects: 100% (3/3), done.
remote: Total 549 (delta 4), reused 7 (delta 4), pack-reused 542
Receiving objects: 100% (549/549), 69.74 MiB | 27.75 MiB/s, done.
Resolving deltas: 100% (302/302), completed with 4 local objects.
From https://github.com/fishtree-attempt/znk-transition-test
 + b1d2dc2...8fb7789 gh-pages   -> origin/gh-pages  (forced update)
Merge made by the 'ort' strategy.
... done
Rscript final-transition.R fishtree-attempt/znk-transition-test release/fishtree-attempt/znk-transition-test.json
Linking to libgit2 v1.4.2, ssh support: YES
Global config: /home/zhian/.gitconfig
Default user: Zhian N. Kamvar <zkamvar@gmail.com>
No repository exists.
Running git rev-parse HEAD
e4cb4939fbef08eab6a5b292f7b1b5f49e4e3cc3
Running bash filter-and-transform.sh \
  release/fishtree-attempt/znk-transition-test.json \
  fishtree-attempt/znk-transition-test.R \
  /home/zhian/Documents/Carpentries/Git/carpentries/lesson-transition/filter-list.txt \
  'return message
'
Cloning into 'release/fishtree-attempt/znk-transition-test'...
Converting release/fishtree-attempt/znk-transition-test...
Parsed 1065 commitsHEAD is now at 993d249 Merge pull request #52 from sgibson91/malvikasharan-typo-fix
con-16x16.png' to 'favicons/lc/favicon-16x16.png'
New history written in 0.33 seconds; now repacking/cleaning...
Repacking your repo and cleaning out old unneeded objects
Completely finished after 1.60 seconds.
Setting origin to https://github.com/fishtree-attempt/znk-transition-test.git...
Setting default branch from gh-pages to main...
... done
✔ Version '2.19.2' is now the active one.
ℹ Pandoc version also activated for rmarkdown functions.
── OLD: 'fishtree-attempt/znk-transition-test' ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────
── NEW: 'release/fishtree-attempt/znk-transition-test' ─────────────────────────────────────────────────────────────────────────────────────────────────────────
Linking to libgit2 v1.4.2, ssh support: YES
Global config: /home/zhian/.gitconfig
Default user: Zhian N. Kamvar <zkamvar@gmail.com>
Copying '../../../../../../../../../.cache/R/renv/cache/v5/R-4.2/x86_64-pc-linux-gnu/v
Attaching package: ‘purrr’
le-150x150.png' to 'favicons/lc/mstile-150x150.png'
The following object is masked from ‘package:jsonlite’:
arnish/0.2.16/0f5b2f34aa334e57dbd3199a1d5b65f9/varnish/pkgdown/assets/favicons/lc/msti
    flatten
Copying '../../../../../../../../../.cache/R/renv/cache/v5/R-4.2/x86_64-pc-linux-gnu/v
here() starts at /home/zhian/Documents/Carpentries/Git/carpentries/lesson-transition
le-310x310.png' to 'favicons/lc/mstile-310x310.png'
── Reading in lesson with pegboard ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
le-70x70.png' to 'favicons/lc/mstile-70x70.png'
── Reading configuration file ──
arnish/0.2.16/0f5b2f34aa334e57dbd3199a1d5b65f9/varnish/pkgdown/assets/favicons/swc/app
! Could not copy '/home/zhian/Documents/Carpentries/Git/carpentries/lesson-transition/template/episodes/data'
! `path` must be a directory
! Could not copy '/home/zhian/Documents/Carpentries/Git/carpentries/lesson-transition/template/episodes/fig'
! `path` must be a directory
! Could not copy '/home/zhian/Documents/Carpentries/Git/carpentries/lesson-transition/template/episodes/files'
! `path` must be a directory
le-touch-icon-152x152.png' to 'favicons/swc/apple-touch-icon-152x152.png'
── Processing index ──
arnish/0.2.16/0f5b2f34aa334e57dbd3199a1d5b65f9/varnish/pkgdown/assets/favicons/swc/app
Warning message:
In yaml::yaml.load(x, handlers = list(seq = function(x) { :
  NAs introduced by coercion: . is not a real
── Processing README ──
Copying '../../../../../../../../../.cache/R/renv/cache/v5/R-4.2/x86_64-pc-linux-gnu/v
── copying instructor and learner materials ──
le-touch-icon-72x72.png' to 'favicons/swc/apple-touch-icon-72x72.png'
! Could not process '/home/zhian/Documents/Carpentries/Git/carpentries/lesson-transition/fishtree-attempt/znk-transition-test/_extras/design.md': the file '/home/zhian/Documents/Carpentries/Git/carpentries/lesson-transition/fishtree-attempt/znk-transition-test/_extras/design.md' does not exist
! Could not delete '/home/zhian/Documents/Carpentries/Git/carpentries/lesson-transition/release/fishtree-attempt/znk-transition-test/_extras/design.md'
! Could not process '/home/zhian/Documents/Carpentries/Git/carpentries/lesson-transition/fishtree-attempt/znk-transition-test/_extras/exercises.md': the file '/home/zhian/Documents/Carpentries/Git/carpentries/lesson-transition/fishtree-attempt/znk-transition-test/_extras/exercises.md' does not exist
! Could not delete '/home/zhian/Documents/Carpentries/Git/carpentries/lesson-transition/release/fishtree-attempt/znk-transition-test/_extras/exercises.md'
! Could not delete '/home/zhian/Documents/Carpentries/Git/carpentries/lesson-transition/release/fishtree-attempt/znk-transition-test/_extras/figures.md'
Warning message:
In yaml::yaml.load(x, handlers = list(seq = function(x) { :
  NAs introduced by coercion: . is not a real
Warning message:
In yaml::yaml.load(x, handlers = list(seq = function(x) { :
  NAs introduced by coercion: . is not a real
icon.ico' to 'favicons/swc/favicon.ico'
── copying figures, files, and data ──
arnish/0.2.16/0f5b2f34aa334e57dbd3199a1d5b65f9/varnish/pkgdown/assets/favicons/swc/mst
! Could not copy '/home/zhian/Documents/Carpentries/Git/carpentries/lesson-transition/release/fishtree-attempt/znk-transition-test/img'
! `path` must be a directory
! Could not delete '/home/zhian/Documents/Carpentries/Git/carpentries/lesson-transition/release/fishtree-attempt/znk-transition-test/img'
! Could not copy '/home/zhian/Documents/Carpentries/Git/carpentries/lesson-transition/release/fishtree-attempt/znk-transition-test/images'
! `path` must be a directory
! Could not delete '/home/zhian/Documents/Carpentries/Git/carpentries/lesson-transition/release/fishtree-attempt/znk-transition-test/images'
! Could not copy '/home/zhian/Documents/Carpentries/Git/carpentries/lesson-transition/release/fishtree-attempt/znk-transition-test/data'
! `path` must be a directory
! Could not delete '/home/zhian/Documents/Carpentries/Git/carpentries/lesson-transition/release/fishtree-attempt/znk-transition-test/data'
ng' to 'mstile-150x150.png'
── Setting the configuration parameters in config.yaml ─────────────────────────────────────────────────────────────────────────────────────────────────────────
ℹ Writing to '/home/zhian/Documents/Carpentries/Git/carpentries/lesson-transition/release/fishtree-attempt/znk-transition-test/config.yaml'
→ title: 'Lesson Title' # FIXME -> title: 'Cross Stitch Carpentry'
→ source: 'https://github.com/carpentries/workbench-template-rmd' # FIXME -> source: 'https://github.com/fishtree-attempt/znk-transition-test/'
→ contact: 'team@carpentries.org' # FIXME -> contact: 'sgibson@turing.ac.uk'
→ life_cycle: 'pre-alpha' # FIXME -> life_cycle: 'transition-step-2'
→ carpentry: 'incubator' -> carpentry: 'cp'
→ NA -> url: 'https://preview.carpentries.org/znk-transition-test'
→ NA -> analytics: 'carpentries'
→ NA -> lang: 'en'
→ NA -> workbench-beta: 'true'
Writing 'instructor/02-image-basics.html'
── Transforming Episodes ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
ℹ Converting 'fishtree-attempt/znk-transition-test/_episodes/01-prerequisities.md' to sandpaper
✔ Converting 'fishtree-attempt/znk-transition-test/_episodes/01-prerequisities.md' to sandpaper ... done
Writing '05-creating-histograms.html'
ℹ Writing ''release/fishtree-attempt/znk-transition-test/episodes'/'01-prerequisities.md''
✔ Writing ''release/fishtree-attempt/znk-transition-test/episodes'/'01-prerequisities.md'' ... done
Writing 'instructor/08-connected-components.html'
ℹ Converting 'fishtree-attempt/znk-transition-test/_episodes/02-getting-started.md' to sandpaper
✔ Converting 'fishtree-attempt/znk-transition-test/_episodes/02-getting-started.md' to sandpaper ... done
Writing 'discuss.html'
ℹ Writing ''release/fishtree-attempt/znk-transition-test/episodes'/'02-getting-started.md''
✔ Writing ''release/fishtree-attempt/znk-transition-test/episodes'/'02-getting-started.md'' ... done
Writing 'instructor/reference.html'
ℹ Converting 'fishtree-attempt/znk-transition-test/_episodes/03-how-to-cross-stitch.md' to sandpaper
✔ Converting 'fishtree-attempt/znk-transition-test/_episodes/03-how-to-cross-stitch.md' to sandpaper ... done
Writing '404.html'
ℹ Writing ''release/fishtree-attempt/znk-transition-test/episodes'/'03-how-to-cross-stitch.md''
✔ Writing ''release/fishtree-attempt/znk-transition-test/episodes'/'03-how-to-cross-stitch.md'' ... done
── Creating homepage ─────────────────────────────────────────────────────────────────
ℹ Converting 'fishtree-attempt/znk-transition-test/_episodes/04-finishing-off.md' to sandpaper
✔ Converting 'fishtree-attempt/znk-transition-test/_episodes/04-finishing-off.md' to sandpaper ... done
──────────────────────────────────────────────────────────────────────────
ℹ Writing ''release/fishtree-attempt/znk-transition-test/episodes'/'04-finishing-off.md''
✔ Writing ''release/fishtree-attempt/znk-transition-test/episodes'/'04-finishing-off.md'' ... done
Writing ''instructor/aio.html''
ℹ Committing...
ℹ Running '/home/zhian/Documents/Carpentries/Git/carpentries/lesson-transition/fishtree-attempt/znk-transition-test.R'
ℹ Consent for package cache revoked. Use `use_package_cache()` to undo.
── Validating Fenced Divs ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
── Validating Internal Links and Images ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
! There were errors in 1/107 links
◌ Avoid uninformative link phrases <https://webaim.org/techniques/hypertext/link_text#uninformative>
arnish/0.2.16/0f5b2f34aa334e57dbd3199a1d5b65f9/varnish/pkgdown/assets/assets/fonts/mul
learners/setup.md:9 [uninformative link text]: [here](files/Beginner-Pattern-Chart_Binder-logo.pdf)
◉ pandoc found
  version : 2.19.2
  path    : '/home/zhian/.local/share/r-pandoc/2.19.2'
-- Initialising site -----------------------------------------------------------
Copying '../../../../../../../../../.cache/R/renv/cache/v5/R-4.2/x86_64-pc-linux-gnu/pkgdown/2.0.7/16fa15449c930bf3a7761d3c68f8abf9/pkgdown/BS3/assets/bootstrap-toc.css' to 'bootstrap-toc.css'

[ SNIP ]

Copying '../../../../../../../../../.cache/R/renv/cache/v5/R-4.2/x86_64-pc-linux-gnu/varnish/0.2.16/0f5b2f34aa334e57dbd3199a1d5b65f9/varnish/pkgdown/assets/site.webmanifest' to 'site.webmanifest'
── Scanning episodes to rebuild ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
Writing 'instructor/CODE_OF_CONDUCT.html'
Writing 'CODE_OF_CONDUCT.html'
Writing 'instructor/LICENSE.html'
Writing 'LICENSE.html'
Writing 'instructor/01-prerequisities.html'
Writing '01-prerequisities.html'
Writing 'instructor/02-getting-started.html'
Writing '02-getting-started.html'
Writing 'instructor/03-how-to-cross-stitch.html'
Writing '03-how-to-cross-stitch.html'
Writing 'instructor/04-finishing-off.html'
Writing '04-finishing-off.html'
Writing 'instructor/motivation.html'
Writing 'motivation.html'
Writing 'instructor/discuss.html'
Writing 'discuss.html'
Writing 'instructor/reference.html'
Writing 'reference.html'
── Creating 404 page ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
Writing 'instructor/404.html'
Writing '404.html'
── Creating learner profiles ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
Writing 'instructor/profiles.html'
Writing 'profiles.html'
── Creating homepage ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
Writing 'instructor/index.html'
Writing 'index.html'
── Creating keypoints summary ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
Writing ''instructor/key-points.html''
Writing ''key-points.html''
── Creating All-in-one page ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
Writing ''instructor/aio.html''
Writing ''aio.html''
── Creating Images page ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
Writing ''instructor/images.html''
Writing ''images.html''
── Creating Instructor Notes ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
Writing ''instructor/instructor-notes.html''
Writing ''instructor-notes.html''
── Creating sitemap.xml ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
con.ico' to 'favicons/cp/favicon.ico'
Output created: /home/zhian/Documents/Carpentries/Git/carpentries/lesson-transition/release/fishtree-attempt/znk-transition-test/site/docs/index.html
→ Writing list of modified files to '/home/zhian/Documents/Carpentries/Git/carpentries/lesson-transition/release/fishtree-attempt/znk-transition-test.json'
── Conversion finished ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
ℹ Browse the old lesson in 'fishtree-attempt/znk-transition-test'
ℹ The converted lesson is ready in 'release/fishtree-attempt/znk-transition-test'
ℹ Copying filter output
ℹ recording e83e2c9 to release/fishtree-attempt/znk-transition-test-invalid.hash
ℹ removing workbench beta phase yaml (inserted by template)
ℹ Writing to /home/zhian/Documents/Carpentries/Git/carpentries/lesson-transition/release/fishtree-attempt/znk-transition-test/config.yaml
→ source: 'https://github.com/fishtree-attempt/znk-transition-test/' -> source: 'https://github.com/fishtree-attempt/znk-transition-test'
→ url: https://preview.carpentries.org/znk-transition-test -> url: 'https://fishtree-attempt.github.io/znk-transition-test'
$status
[1] 0
arnish/0.2.16/0f5b2f34aa334e57dbd3199a1d5b65f9/varnish/pkgdown/assets/favicons/dc/appl
$stdout
[1] "[main ccd4b55] [automation] final workbench updates\n 2 files changed, 2 insertions(+), 63 deletions(-)\n delete mode 100644 .github/workflows/workbench-beta-phase.yml\n"
Copying '../../../../../../../../../.cache/R/renv/cache/v5/R-4.2/x86_64-pc-linux-gnu/v
$stderr
[1] ""
Copying '../../../../../../../../../.cache/R/renv/cache/v5/R-4.2/x86_64-pc-linux-gnu/v
$timeout
[1] FALSE
Copying '../../../../../../../../../.cache/R/renv/cache/v5/R-4.2/x86_64-pc-linux-gnu/v
→ preparing to run `setup_github(path = 'release/fishtree-attempt/znk-transition-test', owner = 'fishtree-attempt', repo = 'znk-transition-test')` in
→ 5...
→ 4...
→ 3...
→ 2...
→ 1...
e-touch-icon-76x76.png' to 'favicons/dc/apple-touch-icon-76x76.png'
── Credentials ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────n-128.png' to 'favicons/dc/favicon-128.png'
{
  "name": "Zhian N. Kamvar",
  "login": "zkamvar",
  "html_url": "https://github.com/zkamvar",
  "token": "gith...x02C"
} 
Copying '../../../../../../../../../.cache/R/renv/cache/v5/R-4.2/x86_64-pc-linux-gnu/v
── Setting up repository ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────pying '../../../../../../../../../.cache/R/renv/cache/v5/R-4.2/x86_64-pc-linux-gnu/v
ℹ Writing to /home/zhian/Documents/Carpentries/Git/carpentries/lesson-transition/release/fishtree-attempt/znk-transition-test/config.yaml
→ created:  -> created: '2023-04-25'
Running git add config.yaml
Running git commit --amend --no-edit
[main 17a109e] [automation] final workbench updates
 Date: Tue Apr 25 08:59:13 2023 -0700
 2 files changed, 3 insertions(+), 64 deletions(-)
 delete mode 100644 .github/workflows/workbench-beta-phase.yml
ℹ renaming default branch (gh-pages) to legacy/gh-pages
POST /repos/fishtree-attempt/znk-transition-test/branches/gh-pages/rename
ℹ enabling github actions to be run
ℹ fetching and pruning branches
Running git fetch --prune origin
From https://github.com/fishtree-attempt/znk-transition-test
 * [new branch]      change-prereq-box -> origin/change-prereq-box
 * [new branch]      legacy/gh-pages   -> origin/legacy/gh-pages
 * [new tag]         2016-06           -> 2016-06
 * [new tag]         v9.1.0            -> v9.1.0
 * [new tag]         v9.1.1            -> v9.1.1
 * [new tag]         v9.1.2            -> v9.1.2
 * [new tag]         v9.2.0            -> v9.2.0
 * [new tag]         v9.2.1            -> v9.2.1
 * [new tag]         v9.2.2            -> v9.2.2
 * [new tag]         v9.2.3            -> v9.2.3
 * [new tag]         v9.2.4            -> v9.2.4
 * [new tag]         v9.3.0            -> v9.3.0
 * [new tag]         v9.3.0rc          -> v9.3.0rc
 * [new tag]         v9.3.1            -> v9.3.1
 * [new tag]         v9.4.0            -> v9.4.0
 * [new tag]         v9.5.0            -> v9.5.0
 * [new tag]         v9.5.0-rc.1       -> v9.5.0-rc.1
 * [new tag]         v9.5.1            -> v9.5.1
 * [new tag]         v9.5.2            -> v9.5.2
 * [new tag]         v9.5.3            -> v9.5.3

── Setting up default branch ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
→ New origin: <https://zkamvar@github.com/fishtree-attempt/znk-transition-test.git>
ℹ pushing the main branch
ℹ setting main branch as default
ℹ protecting the main branch
ℹ creating empty gh-pages branch and forcing it up
Running git checkout --orphan gh-pages
Switched to a new branch 'gh-pages'
Running git rm -rf .
ℹ Adding the workflow to prevent pull requests
Running git add .github/workflows/close-pr.yaml
Running git commit --allow-empty -m 'Intializing gh-pages branch'
[gh-pages (root-commit) 0aaf4fd] Intializing gh-pages branch
 1 file changed, 61 insertions(+)
 create mode 100755 .github/workflows/close-pr.yaml
Running git push --force origin 'HEAD:gh-pages'
remote: 
remote: Create a pull request for 'gh-pages' on GitHub by visiting:        
remote:      https://github.com/fishtree-attempt/znk-transition-test/pull/new/gh-pages        
remote: 
remote: Heads up! The branch 'gh-pages' that you pushed to was renamed to 'legacy/gh-pages'.        
remote: 
To https://github.com/fishtree-attempt/znk-transition-test.git
 * [new branch]      HEAD -> gh-pages
Running git switch main
Your branch is up to date with 'origin/main'.
Switched to branch 'main'
ℹ locking legacy branches
ℹ locking legacy/gh-pages
ℹ Closing open pull requests
→ Found 1 pull requests
→ Pull Requests Managed
rm fishtree-attempt/znk-transition-test/.git
test complete. Inspect logs, commit changes, switch back to main, delete the test repo and test branch
```

</details>

NOTE: if you don't have vault setup, then you will need to modify this to allow
access to the RELEASE_PAT environment variable.


If this works, then congratulations, you are able to run the workflow!
