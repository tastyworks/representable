#!/bin/bash
###
# Runs preflight checks before taging code, creating a gem package, and releasing a new gem version to package_cloud
#
# Usage:
#   ./release.sh # Defaults to patch
#   ./release.sh patch # increments patch
#   ./release.sh minor # increments minor
#   ./release.sh major # increments major
#   ./release.sh 1.2.3 # explicit version
###

echo_info() {
  echo "--> $1"
}

echo_error() {
  echo >&2 "⛔️ ⛔️  $1 ⛔️ ⛔️ "
}


error_exit() {
  message=${1:-Exit}
  echo_error "$message"
  exit 1
}

# Acceptable version types: major, minor, patch, or explicit version, aka 1.2.3
# Defaults to 'patch'
VERSION_TYPE=${1:-patch}

# Target gem repos
PACKAGE_CLOUD_REPOS=tastyworks/gems

# Exit script if any command fails
set -e

# Confirm if current branch isn't master
CURRENT_GIT_BRANCH=`git rev-parse --abbrev-ref HEAD`
if [ $CURRENT_GIT_BRANCH != "master" ]; then
  echo "⚠️  You are about to release on the $CURRENT_GIT_BRANCH branch, not master."
  read -p "Hit 'y' to confirm: " -n 1 -r
  if [[ $REPLY != "y" ]]
  then
    error_exit "Aborting release"
  fi
  echo
fi

echo_info "📤  Push any local commits"
git push
echo

echo_info "🗃  Make sure code repo is clean"
require_clean_work_tree_git () {
    git rev-parse --verify HEAD >/dev/null || exit 1
    git update-index -q --ignore-submodules --refresh
    err=0

    if ! git diff-files --quiet --ignore-submodules
    then
        echo_error "Cannot $1: You have unstaged changes."
        err=1
    fi

    if ! git diff-index --cached --quiet --ignore-submodules HEAD --
    then
        if [ $err = 0 ]
        then
            echo_error "Cannot $1: Your index contains uncommitted changes."
        else
            echo_error "Additionally, your index contains uncommitted changes."
        fi
        err=1
    fi

    if [ $err = 1 ]
    then
        test -n "$2" && echo_error "$2"
        exit 1
    fi
}
require_clean_work_tree_git
echo

echo_info "📥  Ensure local code is up to date"
git pull
echo

echo_info "👁  Ensure code is correct"
bundle exec rake
echo

echo_info "👷  Building gem package"
bundle exec rake build
LATEST_GEM=`ls -tr pkg/ | tail -1`
echo

# Parse output for location of package
[[ $LATEST_GEM =~ ^([[:alnum:]_-]+)-([^[:space:]]+)\.gem$ ]]
if [ -z "${BASH_REMATCH[1]}" ]; then
  error_exit "Failed to detect gem name from latest gem: $LATEST_GEM"
fi

GEM_NAME=${BASH_REMATCH[1]}
GEM_VERSION=${BASH_REMATCH[2]}
PACKAGE_PATH="pkg/$LATEST_GEM"
echo_info "🌩  Pushing gem package to package cloud"
bundle exec package_cloud push $PACKAGE_CLOUD_REPOS $PACKAGE_PATH
echo
echo_info "👍  $GEM_NAME $GEM_VERSION released"
