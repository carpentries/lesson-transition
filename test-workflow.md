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

### Setup 

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

### Running

There are three steps to the process:

1. delete and reset the repository (optional: add pull request)
2. re-add fishtree-attempt/znk-transition-test to the token
3. run the release process

Once you are in your new branch, and have your tokens set up in vault or
wherever, you can run the setup script via:

```bash
# make sure you have a setup key in your vault
SETUP_PAT=$(./pat.sh setup) Rscript create-transition-test.R
```

NOTE: If this errors, just try to run it again, sometimes network issues bite
you.

Once you do that, you will want to go to your RELEASE_PAT token
<https://github.com/settings/tokens?type=beta> and edit it so that it has access
to the `fishtree-attempt/znk-transition-test` repository.

From here, you can run the workflow by running:

```sh
bash run-transition-test.sh
```

NOTE: if you don't have vault setup, then you will need to modify this to allow
access to the RELEASE_PAT environment variable.


If this works, then congratulations, you are able to run the workflow!
