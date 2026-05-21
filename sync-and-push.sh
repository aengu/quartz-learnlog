#!/bin/bash
# Obsidian → Quartz 전체 sync + 빌드 + push

OBSIDIAN="/Users/shinhaeran/Desktop/opsidian/hr.shin"
QUARTZ="/Users/shinhaeran/Desktop/혀란/quartz-learnlog"
CONTENT="$QUARTZ/content"

echo "=== Syncing content ==="

# LearnLog 개발일지 (index.md, attachments 보존)
rsync -av --delete \
  --exclude='index.md' \
  --exclude='attachments/' \
  "$OBSIDIAN/LearnLog/" "$CONTENT/LearnLog/"

# LearnLog attachments
rsync -av "$OBSIDIAN/LearnLog/attachments/" "$CONTENT/LearnLog/attachments/"

# LearnLog index (포트폴리오)
cp "$OBSIDIAN/LearnLog/📚 LearnLog - 개발자를 위한 AI 검색 아카이브 시스템.md" "$CONTENT/LearnLog/index.md"

# 이력서 (What I Learned, index.md 제외 - 별도 관리, 대용량 영상 제외)
rsync -av --delete \
  --exclude='신혜란/What I Learned/' \
  --exclude='*.mov' \
  --exclude='*.mp4' \
  "$OBSIDIAN/이력서/" "$CONTENT/이력서/"

# 이력서 폴더 index (explorer 클릭 시 콘텐츠 표시용)
cp "$OBSIDIAN/이력서/신혜란.md" "$CONTENT/이력서/index.md"

# What I Learned: sync 후 frontmatter 자동 추가
WIL="$CONTENT/이력서/신혜란/What I Learned"
rsync -av --delete \
  --exclude='attachments/' \
  "$OBSIDIAN/이력서/신혜란/What I Learned/" "$WIL/" \
  --include='*.md' --exclude='*/'

for f in "$WIL"/*.md; do
  if ! head -1 "$f" | grep -q '^---'; then
    title=$(head -1 "$f" | sed 's/^# //')
    tmpfile=$(mktemp)
    printf '%s\n' "---" "title: \"$title\"" "---" "" > "$tmpfile"
    cat "$f" >> "$tmpfile"
    mv "$tmpfile" "$f"
  fi
done

# 루트 index (이력서)
cp "$OBSIDIAN/이력서/신혜란.md" "$CONTENT/index.md"

# 자기소개서
cp "$OBSIDIAN/자소서/자기소개서.md" "$CONTENT/자기소개서.md"

echo ""
echo "=== Building ==="
source ~/.nvm/nvm.sh && nvm use 22
cd "$QUARTZ"
npx quartz build

if [ $? -ne 0 ]; then
  echo "❌ Build failed!"
  exit 1
fi

echo ""
echo "=== Exporting PDFs ==="
PDF_DIR="/Users/shinhaeran/Desktop/혀란/력서/$(date '+%m%d')"
mkdir -p "$PDF_DIR"

npx serve "$QUARTZ/public" -l 8080 --no-clipboard > /dev/null 2>&1 &
SERVE_PID=$!
sleep 3

CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
"$CHROME" --headless --disable-gpu --no-pdf-header-footer --virtual-time-budget=10000 \
  --print-to-pdf="$PDF_DIR/이력서.pdf" "http://localhost:8080/이력서/신혜란/" 2>/dev/null
"$CHROME" --headless --disable-gpu --no-pdf-header-footer --virtual-time-budget=10000 \
  --print-to-pdf="$PDF_DIR/자기소개서.pdf" "http://localhost:8080/자기소개서" 2>/dev/null
"$CHROME" --headless --disable-gpu --no-pdf-header-footer --virtual-time-budget=10000 \
  --print-to-pdf="$PDF_DIR/포트폴리오.pdf" "http://localhost:8080/LearnLog/" 2>/dev/null

kill $SERVE_PID 2>/dev/null
echo "✅ PDFs saved to: $PDF_DIR"

echo ""
echo "=== Pushing ==="
git add -A
git commit -m "content sync $(date '+%Y-%m-%d %H:%M')"
git push origin v4

echo "✅ Done!"
