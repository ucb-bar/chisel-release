#!/bin/sh
function usage ()
{
  echo usage:
  cat <<EOF
$0: [-s suffix | -v version] files...

Search files... for SNAPSHOT version strings, replacing whatever follows the
SNAPSHOT with the supplied suffix, separated from SNAPSHOT with an '_'.
If suffix is the empty string (-s ""), any existing suffix is removed.
NOTE: These replacements will happen whereever a *SNAPSHOT* version is found.
If a specific version is specified with -v, it will replace the *SNAPSHOT*
version in its entirety, but this replacement is limited to explicit
version settings ("version := ...").
EOF
}

# Set default suffix
versionSuffix=_`date +%Y-%m-%d`
version=""
if [[ $# == 0 ]]; then
usage
exit 1
fi
while [[ $# -gt 1 || $1 =~ -.* ]]
do
opt="$1"
case $opt in
  -s|--suffix)
  if [[ $2 == "" ]]; then
    versionSuffix=""
  else
    versionSuffix=_"$2"
  fi
  shift
  ;;
  -v|--version)
  version="$2"
  shift
  ;;
  -h|--help)
  usage
  exit 1
  ;;
  *)
  echo "$0: unknown option: $opt"
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
  sed -E -i.bak -e "s/\"([[:digit:]]+\.[[:digit:]]+-SNAPSHOT)(_[^\"]+){0,1}\"/\"\1$versionSuffix\"/" $@
fi
