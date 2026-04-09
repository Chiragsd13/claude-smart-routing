#!/usr/bin/env bash
# ============================================================
# github-badges.sh
# Automates earning every earnable GitHub Achievement badge.
# Usage: bash github-badges.sh [--coauthor "Name <email>"]
# Requirements: gh CLI authenticated (gh auth login)
# ============================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

log()    { echo -e "${BLUE}[*]${NC} $*"; }
ok()     { echo -e "${GREEN}[+]${NC} $*"; }
warn()   { echo -e "${YELLOW}[!]${NC} $*"; }
fail()   { echo -e "${RED}[-]${NC} $*"; }
header() { echo -e "\n${BOLD}${CYAN}==> $*${NC}"; }

# ---- Parse args ----
COAUTHOR=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --coauthor) COAUTHOR="$2"; shift 2 ;;
    --coauthor=*) COAUTHOR="${1#*=}"; shift ;;
    *) shift ;;
  esac
done

# ---- Preflight ----
header "Preflight"

if ! command -v gh &>/dev/null; then
  fail "gh CLI not found. Install from https://cli.github.com"; exit 1
fi

if ! gh auth status &>/dev/null; then
  fail "Not authenticated. Run: gh auth login"; exit 1
fi

USERNAME=$(gh api user --jq '.login')
ok "Authenticated as: ${BOLD}$USERNAME${NC}"

# ---- Status check ----
header "Current Badge Status"

MERGED_PRS=$(gh api graphql -f query="{ user(login: \"$USERNAME\") { pullRequests(states: MERGED) { totalCount } } }" --jq '.data.user.pullRequests.totalCount' 2>/dev/null || echo 0)

echo -e "  Merged PRs : ${BOLD}$MERGED_PRS${NC}"
echo ""
echo "  Will automate:"
echo "    Quickdraw           open + close issue in <5 min"
echo "    Pull Shark          2 PRs merged"
echo "    YOLO                merge without review"
if [[ -n "$COAUTHOR" ]]; then
echo "    Pair Extraordinaire co-authored PR -> $COAUTHOR"
else
echo "    Pair Extraordinaire skipped (pass --coauthor to enable)"
fi
echo ""
echo "  Manual only:"
echo "    Galaxy Brain        answer 2 Discussions and get them accepted"
echo "    Public Sponsor      sponsor any user for min \$1/month"
echo "    Starstruck          get 16 stars on a personal repo"
echo ""

read -rp "$(echo -e "${YELLOW}Proceed?${NC} [y/N] ")" confirm
[[ "${confirm,,}" == "y" ]] || { warn "Aborted."; exit 0; }

# ============================================================
# HELPER: create branch, push file, open PR, merge (no review)
# ============================================================
merge_pr() {
  local branch="$1" filename="$2" commit_msg="$3" pr_title="$4"

  local default_branch
  default_branch=$(gh api "repos/$BADGE_FULL" --jq '.default_branch')

  local head_sha
  head_sha=$(gh api "repos/$BADGE_FULL/git/refs/heads/$default_branch" --jq '.object.sha')

  # Create branch
  gh api "repos/$BADGE_FULL/git/refs" \
    --method POST \
    -f ref="refs/heads/$branch" \
    -f sha="$head_sha" >/dev/null

  # Push file
  local content
  content=$(printf '%s' "$filename content" | base64 -w 0)
  gh api "repos/$BADGE_FULL/contents/$filename" \
    --method PUT \
    -f message="$commit_msg" \
    -f content="$content" \
    -f branch="$branch" >/dev/null

  # Open PR
  local pr_num
  pr_num=$(gh api "repos/$BADGE_FULL/pulls" \
    --method POST \
    -f title="$pr_title" \
    -f head="$branch" \
    -f base="$default_branch" \
    --jq '.number')

  # Merge without review
  gh api "repos/$BADGE_FULL/pulls/$pr_num/merge" \
    --method PUT \
    -f merge_method="squash" \
    -f commit_title="$pr_title" >/dev/null

  log "PR #$pr_num merged ($branch)"
}

# ============================================================
# 1. CREATE WORKING REPO
# ============================================================
header "Creating working repo"

BADGE_REPO="badge-run-$(date +%s)"
BADGE_FULL="$USERNAME/$BADGE_REPO"

REPO_URL=$(gh api user/repos \
  --method POST \
  -f name="$BADGE_REPO" \
  -f description="GitHub badge automation working repo - safe to delete after badges appear" \
  -F private=false \
  -F has_issues=true \
  --jq '.html_url')

log "Created: $REPO_URL"

# Wait for GitHub to provision the repo
sleep 3

# Init with README
README_B64=$(printf '# %s\n\nBadge automation working repo. Safe to delete after badges are awarded (24-48h).\n' "$BADGE_REPO" | base64 -w 0)
gh api "repos/$BADGE_FULL/contents/README.md" \
  --method PUT \
  -f message="init: initial commit" \
  -f content="$README_B64" >/dev/null

ok "Repo ready."

# ============================================================
# 2. QUICKDRAW
# ============================================================
header "Quickdraw"

ISSUE_NUM=$(gh api "repos/$BADGE_FULL/issues" \
  --method POST \
  -f title="chore: initial setup tracking" \
  -f body="Tracking setup. Closing as resolved." \
  --jq '.number')

gh api "repos/$BADGE_FULL/issues/$ISSUE_NUM" \
  --method PATCH -f state=closed >/dev/null

ok "Quickdraw triggered. Issue #$ISSUE_NUM opened and closed."

# ============================================================
# 3. PULL SHARK + YOLO
# ============================================================
header "Pull Shark + YOLO"

log "Merging PR 1 of 2..."
merge_pr "feat/setup-ci"   "ci.md"    "feat: add CI notes"    "feat: add CI configuration notes"

log "Merging PR 2 of 2..."
merge_pr "feat/add-docs"   "NOTES.md" "docs: add project notes" "docs: add project notes"

ok "Pull Shark + YOLO triggered. 2 PRs merged without review."

# ============================================================
# 4. PAIR EXTRAORDINAIRE
# ============================================================
header "Pair Extraordinaire"

if [[ -z "$COAUTHOR" ]]; then
  warn "Skipped. To enable, rerun with:"
  warn "  --coauthor \"Name <ID+username@users.noreply.github.com>\""
  warn "  Get the ID from: gh api users/USERNAME --jq '.id'"
else
  pair_default_branch=$(gh api "repos/$BADGE_FULL" --jq '.default_branch')
  pair_head_sha=$(gh api "repos/$BADGE_FULL/git/refs/heads/$pair_default_branch" --jq '.object.sha')

  gh api "repos/$BADGE_FULL/git/refs" \
    --method POST \
    -f ref="refs/heads/feat/pair-work" \
    -f sha="$pair_head_sha" >/dev/null

  pair_content=$(printf 'Collaboration notes.' | base64 -w 0)
  gh api "repos/$BADGE_FULL/contents/COLLAB.md" \
    --method PUT \
    -f "message=feat: add collaboration notes

Co-authored-by: $COAUTHOR" \
    -f content="$pair_content" \
    -f branch="feat/pair-work" >/dev/null

  pair_pr_num=$(gh api "repos/$BADGE_FULL/pulls" \
    --method POST \
    -f title="feat: add collaboration notes" \
    -f head="feat/pair-work" \
    -f base="$pair_default_branch" \
    --jq '.number')

  gh api "repos/$BADGE_FULL/pulls/$pair_pr_num/merge" \
    --method PUT \
    -f merge_method="squash" \
    -f "commit_title=feat: add collaboration notes

Co-authored-by: $COAUTHOR" >/dev/null

  ok "Pair Extraordinaire triggered. Co-author: $COAUTHOR"
fi

# ============================================================
# 5. SUMMARY
# ============================================================
header "Done"

NEW_MERGED=$(gh api graphql -f query="{ user(login: \"$USERNAME\") { pullRequests(states: MERGED) { totalCount } } }" --jq '.data.user.pullRequests.totalCount' 2>/dev/null || echo "?")

echo ""
echo -e "  ${GREEN}Quickdraw${NC}            triggered"
echo -e "  ${GREEN}Pull Shark${NC}           triggered  ($NEW_MERGED total merged PRs on account)"
echo -e "  ${GREEN}YOLO${NC}                 triggered"
if [[ -n "$COAUTHOR" ]]; then
echo -e "  ${GREEN}Pair Extraordinaire${NC}  triggered"
else
echo -e "  ${YELLOW}Pair Extraordinaire${NC}  skipped    (rerun with --coauthor)"
fi
echo -e "  ${YELLOW}Galaxy Brain${NC}         manual     answer 2 Discussions, get them accepted"
echo -e "  ${YELLOW}Public Sponsor${NC}       manual     sponsor any user for min \$1/month"
echo -e "  ${YELLOW}Starstruck${NC}           manual     get 16 stars on a personal repo"
echo ""
echo -e "  Badges appear within ${BOLD}24-48h${NC} at:"
echo -e "  ${CYAN}https://github.com/$USERNAME?tab=achievements${NC}"
echo ""
echo -e "  Working repo (delete after badges appear):"
echo -e "  ${CYAN}$REPO_URL${NC}"
echo ""
ok "All done."
