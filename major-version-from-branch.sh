#!/bin/sh
# Extract the branch name for a submodule based on its name
# Get the last component of the current directory (the submodule name)
name=${1:-$(basename $(pwd))}
# Typically, the top level is one directory up.
toplevel=${2:-".."}
# Extract the branch name from .gitmodules
branch=$(git config -f $toplevel/.gitmodules submodule.$name.branch)
# Keep the leading (major) component of the branch.
[[ "$branch" =~ ([[:digit:]]+\.[[:digit:]]+)[-.] ]] && echo "${BASH_REMATCH[1]}"
