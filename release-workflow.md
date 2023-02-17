## Transition Release Workflow

The transition release workflow consists of four steps:

1. alerting the maintainers of the impending release
2. restricting access for maintainers
3. creating the release
4. committing artifacts and tagging the release

### Requirements

To get this running, you need the requirements for this repo:

 - git
 - python version >= 3
 - R version >= 4.1

You must also have a GitHub PAT readily available from your credential store. 
I have created [a tutorial if you do not have one](https://carpentries.github.io/sandpaper-docs/github-pat.html#creating-a-new-github-personal-access-token)

Your token should have the following scopes: `repo,user,workflow`.

You must also have _admin access_ to whatever organisation you wish to deploy to
.

### Alerting the maintainers and restricting access

The `create-collab-notice.R` script takes a repository name as its argument and
gives you markdown text for you to paste into a comment: 

```bash
$ Rscript create-collab-notice.R carpentries/maintainer-onboarding
ℹ Gathering collaborators for carpentries/maintainer-onboarding with at least push access

── displaying to screen ───────────────────────────────────────────────────────────────
This lesson will be converted to use [The Carpentries Workbench][workbench]
To prevent accidental reversion of the changes, we are temporarily revoking
write access for all collaborators on this lesson:

 - [ ] @chendaniely (push)
 - [ ] @katrinleinweber (push)
 - [ ] @vinisalazar (push)

If you no longer wish to have write access to this repository, you do not
need to do anything further.

1. What you can expect from the transition 📹: https://carpentries.github.io/workbench/beta-phase.html#beta
2. How to update your local clone 💻: https://carpentries.github.io/workbench/beta-phase.html#updating-clone
3. How to update (delete) your fork (if you have one) 📹: https://carpentries.github.io/workbench/faq.html#update-fork-from-styles

If you wish to regain write access, please re-clone the repository on your machine and
then comment here with `I am ready for write access :rocket:` and the
admin maintainer of this repository will restore your permissions.

If you have any questions, please reply here and tag @zkamvar

[workbench]: https://carpentries.github.io/workbench

── MANUAL STEP ────────────────────────────────────────────────────────────────────────
ℹ Visit <https://github.com/carpentries/maintainer-onboarding/settings/access> and set everyone's access to `read`

── DONE ───────────────────────────────────────────────────────────────────────────────
```

You also have a link to the access settings where you can set everyone's access
to "read". Note that you should leave one maintainer as admin to grant the others
access ([example comment to admin](https://github.com/carpentries-incubator/bioc-project/issues/48#issuecomment-1435372672)).

### Creating the Release

To create the release, you will use the following command:

```bash
make release/[org]/[repo].json
```

where `[org]` is the organisattion and `[repo]` is the lesson name. For example,
this created the release for the bioc intro lesson for carpentries incubator:

```
make release/carpentries-incubator/bioc-intro.json
```

The release process will take a few minutes depending on the speed of your
processor and the speed of your connection. When it is finished, you will have
[a set of files with a `*.hash`
extension](https://github.com/carpentries/lesson-transition/commit/747030b61359a61bd01e299ab2d7ff5714af69d9).
These are the outputs from the commit process.

### Commit and create tag

You should commit these release hash files:

```sh
git add release/
git commit -m 'release [org]/[lesson]'
```

Once you do that, you can tag it. If you use gpg on your machine, I would highly
recommend that you _sign_ your tag:

```sh
git tag -s release_[abbrev]/[lesson] -m '[your message here]'
```

You can use `git tag -n` to view the previous tags to get an idea of the naming
conventions.


Once you do that, then you can push the commit and tag up with:

```sh
git push
git push --tags
```

If you have a set of releases that you want to do, I would recommend to not push
until you are finished. This way, when the submodules update on the remote, you 
don't have to worry about conflicts due to the changed histories of the lessons
that you just converted.
