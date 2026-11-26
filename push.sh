#!/bin/sh
# 리얼통번역 3D 학원 → GitHub Pages 배포 스크립트
# 사용법:  sh deploy/ghpages/push.sh [repo] ["commit message"]
#   · 원격 이력 위에 얹어 fast-forward 로 올린다 (강제 push·거절 문제 해결)
set -e
cd "$(dirname "$0")"
REPO="${1:-realchinese-academy}"
OWNER="realmeee3-cell"
MSG="${2:-v13.1: 클럽·지하상가·판다·거래소·비즈니스100·버스·지하철}"
URL="https://github.com/$OWNER/$REPO.git"
GIT="git -c user.name=$OWNER -c user.email=$OWNER@users.noreply.github.com"

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  rm -rf .git 2>/dev/null || true
  git init -q
  git remote add origin "$URL"
fi
git remote set-url origin "$URL" 2>/dev/null || git remote add origin "$URL" 2>/dev/null || true

# 교재 PDF는 서버에 올리지 않는다 (다운로드 방지) — 추적 중이면 삭제로 반영
git rm -r --cached pdfs >/dev/null 2>&1 || true
rm -rf pdfs 2>/dev/null || true
git add index.html news.json reels.json 2>/dev/null || git add index.html
$GIT commit -q -m "$MSG" 2>/dev/null || true

# 원격 이력이 있으면 그 위로 rebase 해서 fast-forward 로 올린다
git fetch -q origin main 2>/dev/null || true
if git rev-parse --verify -q origin/main >/dev/null; then
  if ! git merge-base --is-ancestor origin/main HEAD 2>/dev/null; then
    git reset --soft origin/main
    git rm -r --cached pdfs >/dev/null 2>&1 || true
    git add index.html news.json reels.json 2>/dev/null || git add index.html
    $GIT commit -q -m "$MSG" 2>/dev/null || true
  fi
fi
git branch -M main 2>/dev/null || true
# 자격증명은 실행 환경이 주입하는 GitHub 연결을 그대로 쓴다.
# (GH_TOKEN·gh auth token 을 credential.helper 로 덮어쓰면 403 이 나는 경우가 있었다)
if [ -n "$GH_TOKEN" ] && [ -z "$SKIP_GH_TOKEN" ]; then
  echo "note: GH_TOKEN 이 설정되어 있으면 403 이 날 수 있어요 — 'env -u GH_TOKEN' 로 실행하세요" >&2
fi
git push -u origin main

gh api -X POST "repos/$OWNER/$REPO/pages" -f 'source[branch]=main' -f 'source[path]=/' 2>/dev/null || \
  gh api -X PUT "repos/$OWNER/$REPO/pages" -f 'source[branch]=main' -f 'source[path]=/' 2>/dev/null || true
echo "https://$OWNER.github.io/$REPO/"
