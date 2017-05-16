#!/bin/sh
# Set default suffix
versionSuffix=`date +%Y-%m-%d`
version=""
while [[ $# -gt 1 ]]
do
opt="$1"
case $opt in
  -s|--suffix)
  versionSuffix="$2"
  shift
  ;;
  -v|--version)
  version="$2"
  shift
  ;;
  *)
  print "unknown option: $opt"
  exit 1
  ;;
esac
shift
done
# If we're replacing the entire version string, limit the replacement
#  to the actual version setting.
if [[ $version != "" ]] ; then
  sed -E -i.bak -e "/\bversion := /s/\"([[:digit:]]+\.[[:digit:]]+(-SNAPSHOT){0,1}(_[^\"]+){0,1}\")/\"$version\"/" $@
else
  sed -E -i.bak -e "s/\"([[:digit:]]+\.[[:digit:]]+-SNAPSHOT)(_[^\"]+){0,1}\"/\"\1_$versionSuffix\"/" $@
fi
