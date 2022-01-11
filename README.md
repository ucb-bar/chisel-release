# The chisel-release Repository

## Overview
Chisel release is a template for core chisel repos.
This repository is used in conjunction with [chisel-repo-tools](https://github.com/ucb-bar/chisel-repo-tools.git).
This repo contains the submodules and a couple of files that describe the current branches.
`chisel-repo-tools` contains the shell, python, and mills scripts used in publishing releases as well as building and
testing them.
In general release processes will be run by chisel-repo-tools.
Most of the documentation on how to do that is in 
[chisel-repo-tools/docs/index.md](https://github.com/ucb-bar/chisel-repo-tools/blob/dev/docs/index.md)

## Use
This repository contains the main Chisel repositories as git submodules
This is the data, if you will, for chisel-repo-tools programs/scripts.
Typically one will checkout this repo for a specific release operation,
e.g. updating snapshot published releases, creating new major an minor releases, etc.

We try to guarantee that all submodule versions (SNAPSHOT and release) are in sync.
While in principle, this could be accomplished with the "correct" top-level build.sbt, it turns out to be difficult in practice.

Some submodule tests presume they're running from the root of the submodule directory and can directly access files in src/test/resources.
This is not true when running as a dependent project under a higher root (the current working directory is the top of the project tree).
Additionaly, sbt's treatment of sub-projects is schizophrenic at best: at the time of writing (sbt 1.3.10), dependencies and plugins from sub-projects have to be propogated up to the top-level project.
Switching a project from a library dependency to a sub-project dependency is not straight-forward.

While we assume this will all eventually get worked out (either via updates to sbt, or a transition to mill or some other build tool), we use a relatively simple Makefile for the moment.

## Branches
There are always several active branches in this repo that are updated by chisel-repo-tools.
The branch names and what they point to is: 
>Z.Y below refers to a specific major release number 

| branch(es) | use | published as |
| --- | --- | --- |
| master | latest development branches | next release (bleeding edge) snapshot |
| Z.Y.x | latest code for release Z.Y | current release snapshots |
| Z.Y-release | the released version | Z.Y.x |

## Currently the repositories referenced here are.
### Chisel libraries
- chisel3
- chiseltest
- chiseltest
- diagrammer
- dsptools
- firrtl
- firrtl-interpreter
- treadle

### Teaching and
- chisel-bootcamp
- chisel-template
- chisel-tutorial

## Chisel development
We follow a practice similar to [1].
Due to Chisel's research evolution and resources, we tend to be oriented more toward development than production.
This may change with the increasing adoption of Chisel and the requirement to maintain a stable set of tools that can be used in production environments.
This document describes the current (2020) development environment.

Our `master` branch corresponds to the `develop` branch in [1].
Most developer work is focused here.
Developers create feature or bug fix branches containing changes to the master branch.
Pull requests are generated to merge these branches into master.
Pull requests must be reviewed and pass a suite of integration tests before they may be merged into master.
The goal is to assure that the master branch is always buildable, and moreover, is self-consistent.
Pull requests are labeled indicating among other things, their impact on the existing API, and tagged with `milestones` indicating their intended release version.
Changes that impact the existing API are typically tagged for the next major release.

We use modified semantic versioning for releases.
A release is defined as a tuple `z.y.x` where `z.y` correspond to the **major** release number, and `x` is the **minor** release number.
Minor releases (increasing `x`) are API-preserving.
They typically consist of bug fixes or experimental features that should not negatively impact existing code.
A new major release indicates some change to the API.
It may impact existing code.

Unlike the practice described in [1], we currently have multiple release branches.
We could use the _single release branch_ model, creating specific release branches as required.
This would simplify the _normal_ release process, at the expense of complicating the process should a requirement arise for an emergency fix to a prior release.

Current practice is to create new branches `z.y+1.x` from either `z.y.x` or `master`, and branch `z.y-release` from `z.y+1.x` as part of the preparation for a new major release.
**NOTE**: The `x` here is the character **x**.
The `3.1.x` and `3.1-release` branches will contain commits for all releases from `3.1.0` to `3.1.999999`.
Minor releases (bug fixes or experimental features) are created from commits cherry-picked (or backported using the mergify bot) from master into the `z.y.x` branch, and from there to the `z.y-release` branch as part of the release process.
To faciltate testing, the internal version of the `z.y.x` branch will always be `z.y-SNAPSHOT`.

To successfully publish releases of related repositories, it is crucial that the collection of repositories can be treated as a single repository.
We don't want someone to commit a change to one of the repositories during the testing of the ensemble.
To this end, we use the branches parallel to `z.y.x`, namely `z.y-release`, and releases are cut from these `z.y-release` branches.
By convention, only the release process itself makes commits to the `z.y-release` branches.
The internal version of `z.y-release` branch is bumped with each release, from pre-release time-stamped SNAPSHOTS (`3.3-20200227-SNAPSHOT`), to release candidates (`3.3.0-RC1`), to major (`3.3.0`) and minor (`3.3.1`) releases, and branch tags created that correspond to these internal versions.

## Branches vs. tags
There is the potential for confusion here.
The namespaces (_branch_ and _tag_) are separate.
You can have both a _tag_ named `tag` and a _branch_ named `tag` referring to different commits.
Checking out `tag` produces:
```bash
$ git checkout tag
warning: refname 'tag' is ambiguous.
Switched to branch 'tag'
```
You can force `sbt` to interpret the name as a _tag_ instead of a _branch_ with:
```bash
$ git checkout tags/tag
```
but I think it's better to avoid the confusion altogether by ensuring that _tag_ and _branch_ names are distinct.

In general, _tags_ are fixed and correspond to a specific commit.
_Branches_ represent a sequence of commits and will evolve over time.
Where there is the possibility of confusion, we prefix a tag corresponding to a release with the character `v`. \
I.e., the _tag_ `v3.1.6` corresponds to the release `3.1.6` and it will tag a commit on the _branch_ `3.1-release`.
The _branch_ `3.1-release` contains the history of commits for the `3.1` series of releases (major version 3.1).
The _tag_ `v3.1.6` represents the state of the `3.1` major version at the time of the 3.1.6 release.
In principle, the `z.y-release` branch corresponds identically to the `z.y.x` branch, with the exception of the internal version - increasing with each release in the former; locked to `z.y-SNAPSHOT` in the latter.
In practice, there may be minor changes to the meta-data associated with the `z.y-release` branch in order to satisfy external publishing constraints, but over time, these changes should be incorporated in the `z.y.x` and `master` branches.

When preparing the next 3.1 minor release (say, `3.1.8`), you would:
- checkout the `3.1.x` branch and `git pull` to enure it's up to date,
- checkout the `3.1-release` branch  and `git pull` to enure it's up to date,
- bump the internal version numbers in the submodule `build.sbt`s on the branches corresponding to the `3.1-release`,
- commit your changes,
- merge the `3.1.x` branch into the `3.1-release` branch and the submodule `z.y.x` branches into the `z.y-release` branches,
- commit your changes,
- clean, build, and test the submodules,
- publish the submodules on Sonatype/Nexus,
- tag each submodule's branch appropriately,
- tag the chisel-release repository,
- push each submodule branch and tag upstream,
- push your updated `3.1-release` branch and the `v3.1.8` tag upstream

There are `make` targets and some `bash` shell stanzas to help with this process.

## Reproducible builds and versioning
We've opted to make stable builds reproducible (as far as we can).
This means that for a stable build to use an updated upstream dependency, its version number must change, even if there's no change to its code base.
For example, if we find and fix a bug in FIRRTL, we'll publish a new version.
For non-SNAPSHOT (i.e., _stable_) releases, this involves increasing the minor version number for FIRRTL.
In order to use this new version of FIRRTL in downstream repositories (repositories dependent on FIRRTL), we'll need to bump the FIRRTL version in their `build.sbt`, bump their internal version, and publish the new version.
This change will cascade as downstream repositories bump the required versions of their upstream dependencies and their own internal version to reflect the updated dependencies.

The exception to this are the example repositories (chisel-template and chisel-tutorial) which in principle should never have downstream repositories dependent on them, and which are intended to be built with the latest version of the current major release.

[1] https://nvie.com/posts/a-successful-git-branching-model/

[2] https://github.com/ucb-bar/chisel-release/blob/master/doc/publish-release.md
