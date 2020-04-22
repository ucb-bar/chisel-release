#!/bin/sh
script_dir=$(dirname $0)
xbranch="master"
if [[ $# -gt 0 ]]; then
  xbranch="$1"
fi
shift
if [[ $# -gt 0 ]]; then
  version="$1"
else
  version=`$script_dir/getVersion.sh`
fi
shift
echo "-m \"$xbranch `git rev-parse --short \`git merge-base origin/$xbranch HEAD\``\"" "$version"
