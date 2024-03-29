IN_IGNORE=$(grep -c '^fishtree-attempt/' .gitignore)
if [[ ! ${IN_IGNORE} -eq 0 ]]; then
  echo 
  echo "Testing the Lesson Transition Deployment"
  echo "----------------------------------------"
  echo 
  echo "**Please read** this carefully:"
  echo "$0 process produces a lot of commits and needs to be run inside of a new branch"
  echo
  echo "If you want to run this script, you must to the following MANUAL STEPS:"
  echo
  echo "1. create a new branch with git switch -c testing-branch"
  echo "2. remove the fishtree-attempt/* line from the .gitignore file"
  echo "3. run touch fishtree-attempt/znk-transition-test.R"
  echo "4. add a 'test-release' token to the vault"
  echo
  echo "When the process completes, you should switch back to main, delete the"
  echo "test repository and the test branch"
  echo
  exit 0
fi
echo "Beginning transition test in 5 seconds"
sleep 2
echo "Beginning transition test in 3 seconds"
sleep 1
echo "Beginning transition test in 2 seconds"
sleep 1
echo "Beginning transition test in 1 second"
sleep 1
make -B fishtree-attempt/znk-transition-test/.git
rm -rf release/fishtree-attempt/znk-transition-test*
RELEASE_PAT=$(./pat.sh test-release) make release/fishtree-attempt/znk-transition-test.json || echo "commit changes; switch back to main; delete the local test repo and try again"
echo "test complete. Inspect logs, commit changes, switch back to main, delete the test repo and test branch"


