### Preparing a Release (SNAPSHOT)
- clone the repository
```bash
$ git clone https://github.com/ucb-bar/chisel-release.git
```
- checkout the (typically) master version of the top module and submodules.
```bash
$ git checkout master
$ git pull
$ git submodule foreach 'git checkout master && git pull"
```
- The internal versions should end with the string "SNAPSHOT". This flags the external repository management code that:
  - this is a changing release,
  - it isn't staged,
  - it will overwrite an existing release of the same version.

- verify that the internal version of each submodule is a SNAPSHOT version:
```bash
$ grep -E '\<version\> :=' */build.sbt
```
- verify that the project dependencies refer to Chisel SNAPSHOT versions:
```bash
$ gawk -e 'FNR == 1 { print FILENAME }' -e '/val defaultVersions = Map\(/,/\)/' */build.sbt
```

- If you need to make edits:
  - submit them as PRs to the individual repositories
  - wait for the updated PRs to be accepted into master, then repeat the intial submodule checkout and pull

- clean the .ivy2 cache of old versions
```bash
$ rm -rf ~/.ivy2/{cache,local}/edu.berkeley.cs
```

- build and run tests
```bash
$ make +clean +test
```
- if the tests generate errors, you'll need to select compatible versions, or fix the cause of the errors.
```bash
$ cd chisel-testers
$ git checkout -b fixbroken
$ vi src/main/scala/broken.scala
$ git add src/main/scala/broken.scala
$ git commit -m "Fix broken code"
$ git push --set-upstream origin fixbroken
```
- wait for updated PRs to be accepted into master, then repeat the intial submodule checkout and pull

Once all tests pass, you can tag and publish the release.

### Committing, Tagging and Publishing a Release (SNAPSHOT)
At this point, all tests pass and each submodule is at a stable commit (typically HEAD of master).
- record the state of each submodule in the parent.
```bash
$ git add -u
$ git commit -m "Bump submodules."
```

- generate tags for every release. SNAPSHOT releases typically contain the date and end with the string "SNAPSHOT".
```bash
$ git submodule foreach 'eval git tag `../genTag.sh YYYY-MM-DD-SNAPSHOT`'
$ eval git tag `./genTag.sh YYYYY-MM-DD-SNAPSHOT`
```

- you shouldn't have to push the individual submodule commits, since they should reflect the appropriate state of the remote repository, but we do need to push the top (chisel-release) project commit and the generated tags.
```bash
$ git push
$ git submodule foreach 'git push origin `git describe`'
$ git push origin `git describe`
```
- finally, publish the individual submodules to Sonatype/maven:
```bash
$ make +publishSigned
```
