#!/bin/sh
function usage ()
{
  echo usage:
  cat <<EOF
$0: [-p prefix | -v version] files...

Search files... for SNAPSHOT version strings, replacing whatever comes before the
SNAPSHOT with the supplied prefix, separated from SNAPSHOT with an '-'.
If prefix is the empty string (-p ""), any existing prefix is removed.
NOTE: These replacements will happen whereever a *SNAPSHOT* version is found.
If a specific version is specified with -v, it will replace the *SNAPSHOT*
version in its entirety, but this replacement is limited to explicit
version settings ("version := ...").
EOF
}

# Set default prefix
versionPrefix=`date +%m%d%y`
version=""
if [[ $# == 0 ]]; then
usage
exit 1
fi
# While we have switches (a word with a leading "-") ...
while [[ $# -gt 1 && ${1#-} != ${1} ]]
do
opt="$1"
case $opt in
  -p|--prefix)
  if [[ $2 != "" ]]; then
    versionPrefix="$2"
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
  sed -E -i -e "/\bversion := /s/\"([[:digit:]]+\.[[:digit:]]+(-[^\"]+){0,1}\")(-SNAPSHOT){0,1}/\"$version\"/" $@
else
  sed -E -i -e "/-SNAPSHOT/s/\"([[:digit:]]+\.[[:digit:]]+)(-SNAPSHOT){0,1}\"/\"\1-$versionPrefix\2\"/" $@
fi
