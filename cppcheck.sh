#!/bin/bash
set -e

# CPPCHECK_TOKEN is a GitHub private access token configured for repo:status scope
# DROPBOX_TOKEN is an access token for the Dropbox API

CPPCHECK_FILES=$*
CPPCHECK_ARGS=${CPPCHECK_ARGS:="--enable=warning --suppressions-list=cppcheck.txt --template='[{file}:{line}]:({severity}),{id},{message}' --force -q -j `nproc`"}
CPPCHECK_TMP=${CPPCHECK_TMP:=/tmp}

status () {
  if [ "$SHIPPABLE" = true ]; then
    # Limit the description to 100 characters even though GitHub supports up to 140 characters
    DESCRIPTION=`echo $2 | cut -b -100`
    DATA="{ \"state\": \"$1\", \"target_url\": \"$BUILD_URL\", \"description\": \"$DESCRIPTION\", \"context\": \"cppcheck\"}"
    GITHUB_API="https://api.github.com/repos/$REPO_FULL_NAME/statuses/$COMMIT"
    
    curl -H "Content-Type: application/json" -H "Authorization: token $CPPCHECK_TOKEN" -H "User-Agent: bangolufsen/cppcheck" -X POST -d "$DATA" $GITHUB_API 1>/dev/null 2>&1
    
    # Only update coverage badge if we are analyzing all files
    if [ "$CPPCHECK_FILES" = "." ] && [ "$1" != "pending" ]; then
      COLOR=red
      if [ $ERRORS -eq 0 ]; then
        COLOR=yellow
        if [ $WARNINGS -eq 0 ]; then
          COLOR=brightgreen
        fi
      fi
      
      BUGS=`expr $ERRORS + $WARNINGS`
      TEXT=$BUGS"_bug"`test $BUGS -eq 1 || echo s`
      wget -O $CPPCHECK_TMP/cppcheck_${REPO_NAME}_${BRANCH}.svg https://img.shields.io/badge/cppcheck-$TEXT-$COLOR.svg 1>/dev/null 2>&1
      curl -H "Authorization: Bearer $DROPBOX_TOKEN" https://api-content.dropbox.com/1/files_put/auto/ -T $CPPCHECK_TMP/cppcheck_${REPO_NAME}_${BRANCH}.svg 1>/dev/null 2>&1
    fi
  fi
  
  echo $2
}

if [ "$1" = "diff" ]; then
  CPPCHECK_FILES=`git diff --name-only origin/develop | grep -e '\.h$' -e '\hpp$' -e '\.c$' -e '\.cc$' -e '\cpp$' -e '\.cxx$' | xargs`
fi

CPPCHECK_ARGS="$CPPCHECK_ARGS $CPPCHECK_FILES"
CPPCHECK_LOG=$CPPCHECK_TMP/cppcheck.log

status "pending" "Running cppcheck with args $CPPCHECK_ARGS"
cppcheck $CPPCHECK_ARGS 2>&1 | tee $CPPCHECK_LOG

ERRORS=`cat $CPPCHECK_LOG | grep "(error)" | wc -l`
WARNINGS=`cat $CPPCHECK_LOG | grep "(warning)" | wc -l`
DESCRIPTION="Found $ERRORS error`test $ERRORS -eq 1 || echo s` and $WARNINGS warning`test $WARNINGS -eq 1 || echo s`"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
  status "success" "$DESCRIPTION"
else
  status "failure" "$DESCRIPTION"
fi
