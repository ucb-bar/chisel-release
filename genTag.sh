#!/bin/sh
if [[ $# -gt 0 ]]; then
  version="$1"
else
  version=`../getVersion.sh`
fi
shift
echo "-m \"master `git rev-parse --short \`git merge-base origin/master HEAD\``\"" "$version"
