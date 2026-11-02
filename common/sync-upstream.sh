#!/usr/bin/env bash
set -euo pipefail

UPSTREAM_REPO="${UPSTREAM_REPO:-datout/Openwrt-Auto}"
UPSTREAM_BRANCH="${UPSTREAM_BRANCH:-main}"
UPSTREAM_URL="${UPSTREAM_URL:-https://github.com/${UPSTREAM_REPO}.git}"
DEFAULT_BRANCH="${DEFAULT_BRANCH:-${GITHUB_REF_NAME:-$(git branch --show-current)}}"
if [[ -z "${DEFAULT_BRANCH}" ]]; then
  echo "::error::无法确定 Fork 默认分支。" >&2
  exit 1
fi
RUN_ROOT="${RUNNER_TEMP:-${TMPDIR:-/tmp}}/openwrt-auto-sync"
BACKUP_DIR="${RUN_ROOT}/custom"
BACKUP_TAR="${RUN_ROOT}/custom-backup.tar.gz"
DELETIONS_FILE="${RUN_ROOT}/custom-deletions.txt"

mkdir -p "${RUN_ROOT}"
rm -rf "${BACKUP_DIR}"
mkdir -p "${BACKUP_DIR}"
: > "${DELETIONS_FILE}"

git checkout "${DEFAULT_BRANCH}"
if git remote get-url upstream >/dev/null 2>&1; then
  git remote set-url upstream "${UPSTREAM_URL}"
else
  git remote add upstream "${UPSTREAM_URL}"
fi
git fetch upstream "${UPSTREAM_BRANCH}" --prune

# GitHub Actions runners do not provide a Git identity by default.
# Configure a local bot identity before any merge/commit operation.
git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"

LOCAL_COMMIT="$(git rev-parse HEAD)"
UPSTREAM_COMMIT="$(git rev-parse "upstream/${UPSTREAM_BRANCH}")"
AHEAD="$(git rev-list --count "${UPSTREAM_COMMIT}..${LOCAL_COMMIT}")"
BEHIND="$(git rev-list --count "${LOCAL_COMMIT}..${UPSTREAM_COMMIT}")"

if git merge-base --is-ancestor "${LOCAL_COMMIT}" "${UPSTREAM_COMMIT}"; then
  echo "Sync required: behind=${BEHIND}, ahead=${AHEAD}."
elif git merge-base --is-ancestor "${UPSTREAM_COMMIT}" "${LOCAL_COMMIT}"; then
  echo "Framework refresh required: behind=0, ahead=${AHEAD}."
else
  COMMON_BASE="$(git merge-base "${LOCAL_COMMIT}" "${UPSTREAM_COMMIT}" 2>/dev/null || true)"
  if [[ -z "${COMMON_BASE}" ]]; then
    echo "::error::Local and upstream histories have no common ancestor; resolve the Git history before syncing."
    exit 1
  fi
  echo "Syncing diverged history: behind=${BEHIND}, ahead=${AHEAD}, common=${COMMON_BASE}."
fi

# Preserve only the documented user customization layer. The archive is kept in
# RUNNER_TEMP so it never becomes part of the repository history.
mapfile -t custom_paths < <(
  find build -mindepth 2 -maxdepth 2 \
    \( -type f \( -name 'settings.ini' -o -name 'diy-part.sh' \) \) -print
  find build -mindepth 2 -maxdepth 2 -type d \
    \( -name seed -o -name diy -o -name files -o -name patches \) -print
)

if ((${#custom_paths[@]})); then
  printf '%s\0' "${custom_paths[@]}" | tar -czf "${BACKUP_TAR}" --null -T -
else
  tar -czf "${BACKUP_TAR}" --files-from /dev/null
fi

# Preserve explicit deletions inside the customization layer. This prevents a
# file intentionally removed by the user from reappearing from upstream.
mapfile -t tracked_custom < <(
  git ls-tree -r --name-only "upstream/${UPSTREAM_BRANCH}" -- build | awk '
    $0 ~ /^build\/[^\/]+\/(settings\.ini|diy-part\.sh)$/ ||
    $0 ~ /^build\/[^\/]+\/(seed|diy|files|patches)\// {print}
  '
)
for path in "${tracked_custom[@]}"; do
  if git cat-file -e "${LOCAL_COMMIT}:${path}" 2>/dev/null && [[ ! -e "${path}" && ! -L "${path}" ]]; then
    printf '%s\n' "${path}" >> "${DELETIONS_FILE}"
  fi
done

# Replace the framework tree with the exact upstream tree while keeping the
# current branch history intact. Ahead-only forks can add a normal sync commit
# because upstream is already an ancestor. Behind/diverged forks first create a
# conflict-free merge parent with -s ours, then reset the tree to upstream. This
# keeps upstream/main in Git ancestry without ever rewriting the remote branch.
if git merge-base --is-ancestor "${UPSTREAM_COMMIT}" "${LOCAL_COMMIT}"; then
  git read-tree -u --reset "upstream/${UPSTREAM_BRANCH}"
else
  git merge --no-commit --no-ff -s ours "upstream/${UPSTREAM_BRANCH}"
  git read-tree -u --reset "upstream/${UPSTREAM_BRANCH}"
fi

# Remove untracked files left by old fork framework commits. Documented user
# customization has already been archived above, so it is safe to enforce the
# upstream tree for everything outside that customization layer.
git clean -fd

tar -xzf "${BACKUP_TAR}" -C .

while IFS= read -r path; do
  [[ -n "${path}" ]] || continue
  rm -rf -- "${path}"
done < "${DELETIONS_FILE}"

# Remove retired version metadata if an old fork carried it outside the upstream tree.
rm -f UPSTREAM_VERSION
find build -type f -path '*/relevance/actions_version' -delete

git add -A
MERGE_IN_PROGRESS=false
if git rev-parse -q --verify MERGE_HEAD >/dev/null 2>&1; then
  MERGE_IN_PROGRESS=true
fi

if [[ "${MERGE_IN_PROGRESS}" != "true" ]] && git diff --cached --quiet; then
  echo "Upstream framework and user customization are already synchronized."
  exit 0
fi

git diff --cached --stat || true
git commit -m "sync: align framework with upstream main"
git push origin "HEAD:${DEFAULT_BRANCH}"

echo "Sync complete: framework=${UPSTREAM_COMMIT}, custom layer preserved."
