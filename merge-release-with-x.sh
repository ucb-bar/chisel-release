
git submodule foreach \
    'if [ "$name" != "rocket-chip" ] && git diff --quiet --cached ; then \
         rbranch=$(git config -f $toplevel/.gitmodules submodule.$name.branch); \
         xbranch=$(echo $rbranch | sed -e 's/-release/.x/'); \
         git merge --no-ff --no-commit $xbranch; \
    fi'\
