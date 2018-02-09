#!/bin/sh
shift
echo "-m \"master `git rev-parse --short \`git merge-base master HEAD\``\"" `../getVersion.sh`
