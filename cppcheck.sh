#!/bin/bash
set -e

# GITHUB_TOKEN is a GitHub private access token configured for repo:status scope
# DROPBOX_TOKEN is an access token for the Dropbox API

BRANCH=${BRANCH:=develop}
CPPCHECK_ARGS=${CPPCHECK_ARGS:="--enable=warning --suppressions-list=cppcheck.txt --template='[{file}:{line}]:({severity}),{id},{message}' --force -q -j `nproc`"}

status () {
  if [ "$SHIPPABLE" = "true" ]; then
    if [ "$IS_PULL_REQUEST" = "true" ]; then
      # Limit the description to 100 characters even though GitHub supports up to 140 characters
      DESCRIPTION=`echo $2 | cut -b -100`
      DATA="{ \"state\": \"$1\", \"target_url\": \"$BUILD_URL\", \"description\": \"$DESCRIPTION\", \"context\": \"cppcheck\"}"
      GITHUB_API="https://api.github.com/repos/$REPO_FULL_NAME/statuses/$COMMIT"
      curl -H "Content-Type: application/json" -H "Authorization: token $GITHUB_TOKEN" -H "User-Agent: bangolufsen/cppcheck" -X POST -d "$DATA" $GITHUB_API 1>/dev/null 2>&1
    fi

    # Only update coverage badge if we are analyzing all files
    if [ "$FILES" = "." ] && [ "$1" != "pending" ]; then
      BADGE_COLOR=red
      if [ $ERRORS -eq 0 ]; then
        BADGE_COLOR=yellow
        if [ $WARNINGS -eq 0 ]; then
          BADGE_COLOR=brightgreen
        fi
      fi

      BADGE_TEXT=$BUGS"_bug"`test $BUGS -eq 1 || echo s`
      wget -O /tmp/cppcheck_${REPO_NAME}_${BRANCH}.svg https://img.shields.io/badge/cppcheck-$BADGE_TEXT-$BADGE_COLOR.svg 1>/dev/null 2>&1
      curl -X POST "https://api-content.dropbox.com/2/files/upload" \
        -H "Authorization: Bearer $DROPBOX_TOKEN" \
        -H "Content-Type: application/octet-stream" \
        -H "Dropbox-API-Arg: {\"path\": \"/cppcheck_${REPO_NAME}_${BRANCH}.svg\", \"mode\": \"overwrite\"}" \
        --data-binary @/tmp/cppcheck_${REPO_NAME}_${BRANCH}.svg 1>/dev/null 2>&1
    fi
  fi

  echo $2
}


ARGS=("$@")
FILES=${ARGS[${#ARGS[@]}-1]}
unset "ARGS[${#ARGS[@]}-1]"

if [ "$FILES" = "diff" ]; then
  FILES=`git diff --name-only --diff-filter ACMRTUXB origin/$BRANCH | grep -e '\.h$' -e '\hpp$' -e '\.c$' -e '\.cc$' -e '\cpp$' -e '\.cxx$' | xargs`
fi

status "pending" "Running cppcheck with args $CPPCHECK_ARGS ${ARGS[*]} $FILES"

LOG=/tmp/cppcheck.log
cppcheck $CPPCHECK_ARGS ${ARGS[*]} $FILES 2>&1 | tee $LOG

BUGS=`cat $LOG | wc -l`
ERRORS=`cat $LOG | grep "(error)" | wc -l`
WARNINGS=`cat $LOG | grep "(warning)" | wc -l`
DESCRIPTION="Found $ERRORS error`test $ERRORS -eq 1 || echo s` and $WARNINGS warning`test $WARNINGS -eq 1 || echo s`"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
  status "success" "$DESCRIPTION"
else
  status "failure" "$DESCRIPTION"
fi
