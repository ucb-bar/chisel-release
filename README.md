# chisel-release

## Chisel release tooling
This repository contains the main Chisel repositories as git submodules, and some simple tools to manage release generation, testing, and publishing.

We try to guarantee that all submodule versions (SNAPSHOT and release) are in sync.

There is a top level Makefile that is used to reflect submodule dependencies and invoke sbt to correctly clean, compile, test, and publish individual sub-modules.

While in principle, this could be accomplished with the "correct" top-level build.sbt, it turns out to be difficult in practice.

Some submodule tests presume they're running from the root of the submodule directory and can directly access files in src/test/resources.
This is not true when running as a dependent project under a higher root (the current working directory is the top of the project tree).
Additionaly, sbt's treatment of sub-projects is schizophrenic at best: dependencies and plugins from sub-projects have to be propogated up to the top-level project.
Switching a project from a library dependency to a sub-project dependency is not straight-forward.

While we assume this will all eventually get worked out (either via updates to sbt, or a transition to mill or some other build tool), we use a relatively simple Makefile for the moment.

### Publish Local Versions
Use the following recipes to generate compatible versions of the chisel libraries.

- clone this repository
```bash
$ git clone https://github.com/ucb-bar/chisel-release.git
```
- checkout the required version (master, or SNAPSHOT or release tag)
```bash
$ git checkout master
$ git pull
$ git submodule update --init --recursive
```
- clean and publish all cross versions
```bash
$ make +clean +publishLocal
```
In order to understand the semantics of Chisel versions, we need to say something about Chisel development.

## Chisel development
We follow a practice similar to [1].
Due to Chisel's research evolution and resources, we tend to be oriented more toward development than production.
This may change with the increasing adoption of Chisel and the requirement to maintain a stable set of tools that can be used in production environments.
This document describes the current (2019) development environment.

Our `master` branch corresponds to the `develop` branch in [1].
Most developer work is focused here.
Developers create feature or bug fix branches containing changes to the master branch.
Pull requests are generated to merge these branches into master.
Pull requests must be reviewed and pass a suite of integration tests before they may be merged into master.
The goal is to assure that the master branch is always buildable, and moreover, is self-consistent.
Pull requests are labeled indicating among other things, their impact on the existing API, and tagged with `milestones` indicating their intended release version.
Changes that impact the existing API are typically tagged for the next major release.

We use semantic versioning for releases.
A release is defined as a tuple `z.y.x` where `z.y` correspond to the **major** release number, and `x` is the **minor** release number.
Minor releases (increasing `x`) are API-preserving.
They typically consist of bug fixes or experimental features that should not impact existing code.
A new major release indicates some change to the API.
It may impact existing code.

Unlike the practice described in [1], we currently have multiple release branches.
We could use the _single release branch_ model, creating specific release branches as required.
This would simplify the _normal_ release process, at the expense of complicating the process should a requirement arise for an emergency fix to a prior release.

Current practice is to create a new branch `z.y+1.x` from either `z.y.x` or `master` as part of the preparation for a new major release.
**NOTE**: The `x` here is the character **x**.
The `3.1.x` branch will contain all releases from `3.1.0` to `3.1.999999`
Minor releases (bug fixes or experimental features) are created from commits cherry-picked from master into this branch, the internal version bumped, and the branch tagged with the internal version.

## Branches vs. tags
There is the potential for confusion here.
The namespaces should be separate, but git doesn't enforce that.
You can have both a tag named `tag` and a branch named `tag`.
Checking out `tag` produces:
```bash
$ git checkout tag
warning: refname 'tag' is ambiguous.
Switched to branch 'tag'
```
In general, _tags_ are fixed and correspond to a specific commit.
_Branches_ represent a sequence of commits and will evolve over time.
Where there is the possibility of confusion, we prefix a tag corresponding to a release with the character `v`. \
I.e., the _tag_ `v3.1.6` corresponds to the release `3.1.6` and it will tag a commit on the _branch_ `3.1.x`.
The _branch_ `3.1.x` contains the history of commits for the `3.1` series of releases (major version 3.1).
The _tag_ `v3.1.6` represents the state of the `3.1` major version at the time of the 3.1.6 release.

When preparing the next 3.1 minor release (say, `3.1.8`, you would:
- checkout the `3.1.x` branch,
- bump the internal version number in `build.sbt` to `3.1.8`,
- add/cherry-pick your changes,
- commit your changes,
- tag this commit with a `v3.1.8`

## Reproducible builds and versioning
We've opted to make (as far as we can) stable builds reproducible.
This means that for a stable build to use an updated upstream dependency, its version number must change, even if there's no change to its code base.
For example, if we find and fix a bug in FIRRTL, we'll publish a new version.
For non-SNAPSHOT (i.e., _stable_) releases, this involves increasing the minor version number for FIRRTL.
In order to use this new version of FIRRTL in downstream repositories (repositories dependent on FIRRTL), we'll need to bump the FIRRTL version in their `build.sbt`, bump their internal version, and publish the new version.
This change will cascade as downstream repositories bump the required versions of their upstream dependencies and their own internal version to reflect the updated dependencies.

The exception to this are the example repositories (chisel-template and chisel-tutorial) which in principle should never have downstream repositories dependent on them, and which are intended to be built with the latest version of the current major release.

[1] https://nvie.com/posts/a-successful-git-branching-model/