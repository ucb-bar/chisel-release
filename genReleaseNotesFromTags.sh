#!/bin/sh
# Generate all commits between the last two tags.
git submodule foreach 'read -a tags <<< $(git tag --sort=-creatordate -l); git log --oneline ${tags[1]}..${tags[0]}'