### Preparing a Release
- clone the repository
```bash
$ git clone https://github.com/ucb-bar/chisel-release.git
```
- checkout the appropriate pre-release branch. \
If this is a brand-new major release, you will need to create the major release branches. \
This will typically be `z.y.x` where `z.y` is one greater than the last major release and `x` is the character **x** (e.g. `3.1.x`, `3.2.x`). \
You will need to decide if you're going to clone from master or from the prior release branch. \
If this is a minor release (you'll use the same `z.y` as the previous release and increment the last digit of the release), \
you'll continue with the existing `z.y.x` branch.
  - new major release cloned from master
```bash
$ git checkout master
$ git pull
$ git submodule --init --update
$ git checkout -b 3.1.x
```
-
  - new major release cloned from previous release
```bash
$ git checkout 3.0.x
$ git pull
$ git submodule --init --update
$ git checkout -b 3.1.x
```
  - for new major releases, you'll need to enter each submodule and create the new major release branch. \
As with the top-level project, you'll need to decide if it's better to clone from the previous release branch, or the master branch. \
NOTE: We push the initial state of the new release of each submodule so we don't need to explicitly mention the new branch in subsequent actions.
```bash
$ (cd submodule; git checkout <master or previous>; git pull; git checkout -b <new release>; git push --set-upstream origin <new release>)
```
  - new minor release continuing on current release branch
```bash
$ git checkout 3.1.x
$ git pull
$ git submodule --init --update
```
- edit the versions in `build.sbt` and `*/build.sbt` to bump the individual version numbers
- for each individual submodule, merge in the appropriate changes from master. \
These may be cherry-picks, but be careful. \
A combination of cherry-picks will unlikely have undergone much testing.
- The internal versions should **NOT** end with the string "SNAPSHOT". \
This flags the external repository management code that:
  - this is a stable release,
  - it will be staged,
  - it will **NOT** overwrite an existing release of the same version.

- verify that the internal version of each submodule is **NOT** a SNAPSHOT version:
```bash
$ grep -E '\<version\> :=' */build.sbt
```
- verify that the project dependencies refer to Chisel stable versions:
```bash
$ gawk -e 'FNR == 1 { print FILENAME }' -e '/val defaultVersions = Map\(/,/\)/' */build.sbt
```

- clean the .ivy2 cache of old versions
```bash
$ rm -rf ~/.ivy2/{cache,local}/edu.berkeley.cs
```

- build and run tests
```bash
$ make +clean +test
```
- if the tests generate errors, you'll need to cherry-pick commits from the relative master branch.
```bash
$ cd chisel-testers
$ git cherry-pick -e -n <commit>
```
- if you need to go back and update a submodule that you've previously successfully tested,
you'll need to remove its locally published version in order to overwrite it.
```bash
$ rm -rf ~/.ivy2/local/edu.berkeley.cs/chisel3*
```

Once all tests pass, you can commit, tag and publish the release.

### Committing, Tagging and Publishing a Release (stable)
At this point, all tests pass and each submodule has its correct new version number.
- commit the current state of submodules.
```bash
$ git submodule foreach 'git commit -a'
```
- push the submodules upstream
```bash
$ git submodule foreach 'git push'
```
- record the state of each submodule in the parent.
```bash
$ git add -u
$ git commit -m "Release 3.1.x."
```

- generate tags for every release.
```bash
$ git submodule foreach 'eval git tag `../genTag.sh`'
$ eval git tag `./genTag.sh` #FIXME
```

- push the top (chisel-release) project commit and the generated tags.
```bash
$ git push
$ git submodule foreach 'git push origin `git describe`'
$ git push origin `git describe`
```
- publish the individual submodules to Sonatype/maven:
```bash
$ make +publishSigned
```
- log in to Sonatype and close and release the staged changes.
