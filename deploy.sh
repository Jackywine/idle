#!/usr/bin/env bash
# 空转 · IDLE —— GitHub Pages 一键部署
# 用法：./deploy.sh <github用户名> [仓库名，默认 idle]

set -euo pipefail

USER_NAME="${1:-}"
REPO_NAME="${2:-idle}"

if [ -z "$USER_NAME" ]; then
  echo "用法: ./deploy.sh <github用户名> [仓库名，默认 idle]"
  echo "例如: ./deploy.sh jackywine"
  exit 1
fi

echo "→ 目标: https://${USER_NAME}.github.io/${REPO_NAME}/"
echo ""

# ---------- 依赖检查 ----------
command -v git >/dev/null 2>&1 || { echo "✗ 没找到 git"; exit 1; }
command -v gh  >/dev/null 2>&1 || { echo "✗ 没找到 gh，先跑: brew install gh"; exit 1; }

if ! gh auth status >/dev/null 2>&1; then
  echo "✗ gh 还没登录。先跑："
  echo "   gh auth login"
  exit 1
fi

# ---------- 替换占位符 ----------
if grep -q "YOURNAME" index.html; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/YOURNAME/${USER_NAME}/g" index.html
  else
    sed -i "s/YOURNAME/${USER_NAME}/g" index.html
  fi
  echo "✓ 占位符已替换为 ${USER_NAME}"
else
  echo "· 占位符已替换过，跳过"
fi

# ---------- 本地提交 ----------
if [ ! -d .git ]; then
  git init -q
  git add -A
  git commit -q -m "空转 · IDLE"
  git branch -M main
  echo "✓ 已初始化本地仓库"
else
  git add -A
  if ! git diff --cached --quiet 2>/dev/null; then
    git commit -q -m "update"
    echo "✓ 已提交改动"
  else
    echo "· 没有新改动"
  fi
  git branch -M main 2>/dev/null || true
fi

# ---------- 建仓 / 推送 ----------
if gh repo view "${USER_NAME}/${REPO_NAME}" >/dev/null 2>&1; then
  echo "· 远程仓库已存在，直接推送"
  git remote remove origin 2>/dev/null || true
  git remote add origin "https://github.com/${USER_NAME}/${REPO_NAME}.git"
  git push -u origin main
else
  gh repo create "${REPO_NAME}" --public --source=. --push
  echo "✓ 已创建仓库并推送"
fi

# ---------- 开启 Pages ----------
if gh api "repos/${USER_NAME}/${REPO_NAME}/pages" >/dev/null 2>&1; then
  echo "· Pages 已开启"
else
  if gh api -X POST "repos/${USER_NAME}/${REPO_NAME}/pages" \
      -H "Accept: application/vnd.github+json" \
      -f "source[branch]=main" -f "source[path]=/" >/dev/null 2>&1; then
    echo "✓ Pages 已自动开启"
  else
    echo "· 自动开启 Pages 失败，请手动：仓库 → Settings → Pages → main / root"
  fi
fi

echo ""
echo "──────────────────────────────────────────"
echo "完成。首次构建需要 1～2 分钟，然后访问："
echo ""
echo "   https://${USER_NAME}.github.io/${REPO_NAME}/"
echo ""
echo "建议再检查一下分享卡片："
echo "   https://www.opengraph.xyz/url/https%3A%2F%2F${USER_NAME}.github.io%2F${REPO_NAME}%2F"
echo "──────────────────────────────────────────"
