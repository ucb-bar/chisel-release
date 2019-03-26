#!/bin/sh
# As of 5/3/2017, we include the date in the sbt version so there's no need to add it here.
# This is very brittle, depending, as it does, on sbt's formatting.
# We assume that in the case of multiple subprojects, the version is determined
#  by the root project, whose version is given by the line following:
#  [info] version
sbt version | gawk -e 'BEGIN{m=1}' -e '/^\[info\] version$/{m=1}' -e 'm==1 && $1 ~ /^\[info\]/ && $2 ~ /[[:digit:]]+\.[[:digit:]]/ { print "v" $2; m=0 }' -e '/ \/ version$/{m=0}'
