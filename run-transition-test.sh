IN_IGNORE=$(grep -c '^fishtree-attempt/' .gitignore)
if [[ ! ${IN_IGNORE} -eq 0 ]]; then
  echo 
  echo "$0 process produces a lot of commits and needs to be run inside of a new branch"
  echo
  echo "If you want to run this,"
  echo
  echo "1. create a new branch with git switch -c testing-branch"
  echo "2. remove the fishtree-attempt/* line from the .gitignore file"
  echo "3. run touch fishtree-attempt/znk-transition-test.R"
  echo "4. add a 'test-release' token to the vault"
  echo
  exit 0
fi
make -B fishtree-attempt/znk-transition-test/.git
rm -rf release/fishtree-attempt/znk-transition-test*
RELEASE_PAT=$(./pat.sh test-release) make release/fishtree-attempt/znk-transition-test.json

