#!/usr/bin/env bash
# ============================================================
# github-badges.sh
# Run once to earn all earnable GitHub Achievement badges.
# Creates a temp repo, triggers every badge, then deletes it.
#
# Usage:
#   bash github-badges.sh
#   bash github-badges.sh --coauthor "Name <ID+user@users.noreply.github.com>"
#
# Requirements: gh CLI installed and authenticated (gh auth login)
# Get a co-author noreply email: gh api users/USERNAME --jq '"\(.id)+\(.login)@users.noreply.github.com"'
# ============================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

log()    { echo -e "${BLUE}[*]${NC} $*"; }
ok()     { echo -e "${GREEN}[+]${NC} $*"; }
warn()   { echo -e "${YELLOW}[!]${NC} $*"; }
header() { echo -e "\n${BOLD}${CYAN}>>> $*${NC}"; }

COAUTHOR=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --coauthor) COAUTHOR="$2"; shift 2 ;;
    --coauthor=*) COAUTHOR="${1#*=}"; shift ;;
    *) shift ;;
  esac
done

BADGE_REPO=""

# Cleanup on exit (always delete the temp repo)
cleanup() {
  if [[ -n "$BADGE_REPO" ]]; then
    log "Cleaning up temp repo..."
    gh api "repos/$USERNAME/$BADGE_REPO" --method DELETE 2>/dev/null && ok "Temp repo deleted." || true
  fi
}
trap cleanup EXIT

# ============================================================
# PREFLIGHT
# ============================================================
header "Preflight"

if ! command -v gh &>/dev/null; then
  echo -e "${RED}Error:${NC} gh CLI not found. Install from https://cli.github.com"; exit 1
fi
if ! gh auth status &>/dev/null; then
  echo -e "${RED}Error:${NC} Not authenticated. Run: gh auth login"; exit 1
fi

USERNAME=$(gh api user --jq '.login')
ok "Authenticated as: ${BOLD}$USERNAME${NC}"

MERGED_BEFORE=$(gh api graphql -f query="{ user(login: \"$USERNAME\") { pullRequests(states: MERGED) { totalCount } } }" --jq '.data.user.pullRequests.totalCount' 2>/dev/null || echo 0)
log "Merged PRs before: $MERGED_BEFORE"

# ============================================================
# CREATE TEMP REPO
# ============================================================
header "Creating temp repo"

BADGE_REPO="gh-badges-$(date +%s)"
FULL="$USERNAME/$BADGE_REPO"

gh api user/repos \
  --method POST \
  -f name="$BADGE_REPO" \
  -f description="Temp badge repo - deletes itself after running" \
  -F private=false \
  -F has_issues=true \
  --jq '.full_name' | read -r _ || true

log "Created: github.com/$FULL"
sleep 3

# Init README
b64() { printf '%s' "$1" | base64 -w 0; }

gh api "repos/$FULL/contents/README.md" \
  --method PUT \
  -f message="init: initial commit" \
  -f content="$(b64 "# $BADGE_REPO")" >/dev/null

ok "Repo initialized."

# Helper: get default branch SHA
get_sha() {
  local branch
  branch=$(gh api "repos/$FULL" --jq '.default_branch')
  gh api "repos/$FULL/git/refs/heads/$branch" --jq '.object.sha'
}

# Helper: create branch -> push file -> open PR -> merge (no review = YOLO)
merge_pr() {
  local branch="$1" filename="$2" title="$3" commit_msg="${4:-$3}"

  local sha
  sha=$(get_sha)
  local default_branch
  default_branch=$(gh api "repos/$FULL" --jq '.default_branch')

  gh api "repos/$FULL/git/refs" \
    --method POST -f ref="refs/heads/$branch" -f sha="$sha" >/dev/null

  gh api "repos/$FULL/contents/$filename" \
    --method PUT \
    -f message="$commit_msg" \
    -f content="$(b64 "$filename")" \
    -f branch="$branch" >/dev/null

  local pr_num
  pr_num=$(gh api "repos/$FULL/pulls" \
    --method POST \
    -f title="$title" \
    -f head="$branch" \
    -f base="$default_branch" \
    --jq '.number')

  gh api "repos/$FULL/pulls/$pr_num/merge" \
    --method PUT \
    -f merge_method="squash" \
    -f commit_title="$title" >/dev/null

  log "PR #$pr_num merged."
}

# ============================================================
# QUICKDRAW - open + close issue < 5 min
# ============================================================
header "Quickdraw"

ISSUE=$(gh api "repos/$FULL/issues" \
  --method POST \
  -f title="chore: initial setup" \
  -f body="Resolving immediately." \
  --jq '.number')

gh api "repos/$FULL/issues/$ISSUE" \
  --method PATCH -f state=closed >/dev/null

ok "Issue #$ISSUE opened and closed instantly."

# ============================================================
# PULL SHARK + YOLO - 2 merged PRs, no review
# ============================================================
header "Pull Shark + YOLO"

log "Merging PR 1..."
merge_pr "feat/ci" "ci.md" "feat: add CI notes"

log "Merging PR 2..."
merge_pr "feat/docs" "NOTES.md" "docs: add project notes"

ok "2 PRs merged without review."

# ============================================================
# PAIR EXTRAORDINAIRE - co-authored merged PR
# ============================================================
header "Pair Extraordinaire"

if [[ -z "$COAUTHOR" ]]; then
  warn "Skipped - no co-author provided."
  warn "Rerun with: --coauthor \"Name <ID+username@users.noreply.github.com>\""
  warn "Get the value: gh api users/FRIEND_USERNAME --jq '\"\\(.id)+\\(.login)@users.noreply.github.com\"'"
else
  local_sha=$(get_sha)
  default_br=$(gh api "repos/$FULL" --jq '.default_branch')

  gh api "repos/$FULL/git/refs" \
    --method POST \
    -f ref="refs/heads/feat/collab" \
    -f sha="$local_sha" >/dev/null

  gh api "repos/$FULL/contents/COLLAB.md" \
    --method PUT \
    -f "message=feat: collaboration notes

Co-authored-by: $COAUTHOR" \
    -f content="$(b64 'collaboration')" \
    -f branch="feat/collab" >/dev/null

  pr_num=$(gh api "repos/$FULL/pulls" \
    --method POST \
    -f title="feat: collaboration notes" \
    -f head="feat/collab" \
    -f base="$default_br" \
    --jq '.number')

  gh api "repos/$FULL/pulls/$pr_num/merge" \
    --method PUT \
    -f merge_method="squash" \
    -f "commit_title=feat: collaboration notes

Co-authored-by: $COAUTHOR" >/dev/null

  ok "Pair Extraordinaire triggered. Co-author: $COAUTHOR"
fi

# ============================================================
# SUMMARY (cleanup runs automatically via trap)
# ============================================================
header "Summary"

MERGED_AFTER=$(gh api graphql -f query="{ user(login: \"$USERNAME\") { pullRequests(states: MERGED) { totalCount } } }" --jq '.data.user.pullRequests.totalCount' 2>/dev/null || echo "?")

echo ""
echo -e "  ${GREEN}Quickdraw${NC}            triggered"
echo -e "  ${GREEN}Pull Shark${NC}           triggered   ($MERGED_BEFORE -> $MERGED_AFTER merged PRs)"
echo -e "  ${GREEN}YOLO${NC}                 triggered"
if [[ -n "$COAUTHOR" ]]; then
echo -e "  ${GREEN}Pair Extraordinaire${NC}  triggered"
else
echo -e "  ${YELLOW}Pair Extraordinaire${NC}  skipped     (pass --coauthor)"
fi
echo -e "  ${YELLOW}Galaxy Brain${NC}         manual      get 2 Discussion answers accepted"
echo -e "  ${YELLOW}Public Sponsor${NC}       manual      sponsor any dev for min \$1/month"
echo -e "  ${YELLOW}Starstruck${NC}           manual      get 16 stars on a personal repo"
echo ""
echo -e "  Badges appear in ${BOLD}24-48h${NC} at:"
echo -e "  ${CYAN}https://github.com/$USERNAME?tab=achievements${NC}"
echo ""
ok "Done. Temp repo will be deleted now."
