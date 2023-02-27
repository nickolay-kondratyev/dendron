#!/bin/bash
# Source me, don't run me.
# > source ./build-script.sh

_dendronVSIXBuild__npm_install_if_not_at_version(){
  local command="${1:?}"
  local wanted_version_start="${2:?}"

  cmd_version=$($command --version)
  echo "$command --version: $cmd_version"
  if echo "$cmd_version" | grep -q "${wanted_version_start:?}"; then
    echo "$command is at version ${wanted_version_start:?}xxx skipping install"
  else
    echo "$command is not at version ${wanted_version_start:?}xxx installing $command"
    cmd.run.announce.OR-interrupt "npm install -g $command"
  fi
}
# https://docs.dendron.so/notes/gI6BwB1PJOfe9nMQQAN7a/
_dendronVSIXBuild__envSetup(){
  # "Node.js >= 14 "We recommend using a version in Active LTS"
  # https://github.com/nodejs/release#release-schedule
  # At the time of writing 18 is the latest LTS
  cmd.run.announce.OR-interrupt "nvm install 18"

  _dendronVSIXBuild__npm_install_if_not_at_version "yarn" "1\.22"
  _dendronVSIXBuild__npm_install_if_not_at_version "lerna" "6\.5"
}

_dendronVSIXBuild__setup_yarn(){
  cmd.run.announce.OR-interrupt "yarn"
  cmd.run.announce.OR-interrupt "yarn setup"
}

_dendronVSIXBuild__MAIN() {
  echo "I should be sourced, like > source ./build-script.sh"

  _dendronVSIXBuild__envSetup

  _dendronVSIXBuild__setup_yarn || return 1

  # Set up environment variables
  export NODE_OPTIONS="--max_old_space_size=4096"
  export PUBLISHING_TARGET="darwin-x64"
  export DENDRON_RELEASE_VERSION="$(cat ./packages/plugin-core/package.json | jq .version -r)-nightly"

  # Build the VSIX
  cmd.run.announce.OR-interrupt "yarn install"
  cmd.run.announce.OR-interrupt "yarn build:patch"
  # yarn install || return 1
  # yarn build:patch:local:ci:nightly "${PUBLISHING_TARGET}" || return 1

  # Check for VSIX
  vsixCount=$(ls ./packages/plugin-core/*.vsix | wc -l | awk '{print $1}')
  if [[ $vsixCount -eq 1 ]]; then
      vsix=$(ls ./packages/plugin-core/*.vsix | tail -1)
      echo "found a single .vsix file named $vsix"
      VSIX_FILE_NAME=$(basename "$vsix")
      VSIX_RELATIVE_PATH="$vsix"
  else
      echo "error: expected 1 .vsix file, found $vsixCount"
      return 1
  fi

  echo "VSIX_FILE_NAME=$VSIX_FILE_NAME"
  echo "VSIX_RELATIVE_PATH=$VSIX_RELATIVE_PATH"
}
export -f _dendronVSIXBuild__MAIN

_dendronVSIXBuild__MAIN || exit 1

