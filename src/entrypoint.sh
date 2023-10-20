#! /usr/bin/env bash
set -e
set -x

# shellcheck source=src/sync_common.sh
source sync_common.sh

if [[ -z "${GITHUB_TOKEN_LOCAL}" ]]; then
    err "Missing input 'github_token_local: \${{ secrets.GITHUB_TOKEN_LOCAL }}'.";
    exit 1;
fi
if [[ -z "${GITHUB_TOKEN_REMOTE}" ]]; then
    err "Missing input 'github_token_remote: \${{ secrets.GITHUB_TOKEN_REMOTE }}'.";
    exit 1;
fi

if [[ -z "${SOURCE_REPO_PATH}" ]]; then
  err "Missing input 'source_repo_path: \${{ input.source_repo_path }}'.";
  exit 1
fi

DEFAULT_REPO_HOSTNAME="github.com"
SOURCE_REPO_HOSTNAME="${HOSTNAME:-${DEFAULT_REPO_HOSTNAME}}"
GIT_USER_NAME="${GIT_USER_NAME:-${GITHUB_ACTOR}}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-github-action@actions-template-sync.noreply.${SOURCE_REPO_HOSTNAME}}"

# In case of ssh template repository this will be overwritten
SOURCE_REPO_PREFIX="https://${SOURCE_REPO_HOSTNAME}/"

# Forward to /dev/null to swallow the output of the private key
gh auth login --git-protocol "https" --hostname "${SOURCE_REPO_HOSTNAME}" --with-token <<< "${GITHUB_TOKEN_REMOTE}"

export SOURCE_REPO="${SOURCE_REPO_PREFIX}${SOURCE_REPO_PATH}"

function git_init() {
  info "set git global configuration"

  git config --global user.email "${GIT_USER_EMAIL}"
  git config --global user.name "${GIT_USER_NAME}"
  git config --global pull.rebase false
  git config --global --add safe.directory /github/workspace
  git lfs install

  info "the source repository is located within GitHub."
  gh auth setup-git --hostname "${SOURCE_REPO_HOSTNAME}"
  gh auth status --hostname "${SOURCE_REPO_HOSTNAME}"
}

git_init

# shellcheck source=src/sync_template.sh
source sync_template.sh
