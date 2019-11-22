#!/bin/sh
script_dir=$(dirname $0)
if [[ $# -gt 0 ]]; then
  version="$1"
else
  version=`$script_dir/getVersion.sh`
fi
shift
echo "-m \"master `git rev-parse --short \`git merge-base origin/master HEAD\``\"" "$version"
