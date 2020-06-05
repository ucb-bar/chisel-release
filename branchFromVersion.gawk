# Print the branch based on the version in a version.yml file.
# Call with something like:
#  gawk -v dir=firrtl -v suffix=-20200603-SNAPSHOT -f branchFromVersion.gawk version.yml
BEGIN {
  dirPat = dir":"
}
$1 ~ dirPat,/version:/ && NF == 2 { if ($1 ~ /version:/) { sub(suffix,".x",$2); print $2}}
