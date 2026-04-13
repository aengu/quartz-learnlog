# Quartz로 Obsidian 볼트 웹 배포하기

| 항목 | 내용 |
| --- | --- |
| 목적 | Obsidian 마크다운 문서를 외부에서 URL로 볼 수 있게 정적 사이트로 배포 |
| 도구 | Quartz v4 + GitHub Pages |
| 배포 URL | https://aengu.github.io/quartz-learnlog/ |
| 저장소 | https://github.com/aengu/quartz-learnlog |

---

## Quartz란?

Obsidian 마크다운을 정적 웹사이트로 변환해주는 오픈소스 도구. `[[위키링크]]`, 태그, 그래프 뷰 등 Obsidian 문법을 그대로 지원함.

```
Obsidian 볼트 → Quartz 빌드 → GitHub Pages 배포 → URL로 접근
```

---

## 세팅 과정

### 1. Quartz 클론 + 설치

```bash
cd ~/Desktop/혀란
git clone https://github.com/jackyzha0/quartz.git quartz-learnlog
cd quartz-learnlog
npm i
```

**Node 22 이상 필요.** 20 버전이면 `EBADENGINE` 에러 남.

```bash
# nvm으로 22 설치
nvm install 22
nvm use 22
```

### 2. Obsidian 파일 복사

```bash
cp -r ~/Desktop/opsidian/hr.shin/LearnLog/* ~/Desktop/혀란/quartz-learnlog/content/
```

메인페이지를 `index.md`로 복사해야 Quartz 홈페이지로 인식함:

```bash
cp "content/📚 LearnLog - 개발자를 위한 AI 검색 아카이브 시스템.md" content/index.md
```

### 3. 로컬 확인

```bash
npx quartz build --serve
# http://localhost:8080 에서 확인
```

### 4. GitHub 저장소 생성 + push

```bash
# 원래 Quartz origin을 내 repo로 변경
gh repo create quartz-learnlog --public
git remote set-url origin https://github.com/aengu/quartz-learnlog.git
git add -A
git commit -m "initial quartz setup with LearnLog content"
git push -u origin v4
```

### 5. GitHub Actions 배포 워크플로우 추가

`.github/workflows/deploy.yml` 생성:

```yaml
name: Deploy Quartz to GitHub Pages

on:
  push:
    branches: [v4]

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
      - run: npm ci
      - run: npx quartz build
      - uses: actions/upload-pages-artifact@v3
        with:
          path: public

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - id: deployment
        uses: actions/deploy-pages@v4
```

### 6. GitHub Pages 활성화

GitHub repo Settings → Pages → Source를 **GitHub Actions**로 설정. 또는 API로:

```bash
gh api repos/aengu/quartz-learnlog/pages -X POST --input - <<'EOF'
{
  "build_type": "workflow",
  "source": { "branch": "v4", "path": "/" }
}
EOF
```

push하면 자동으로 빌드 → 배포됨.

---

## Obsidian 변경사항 반영하기

Obsidian에서 문서 수정 후 수동으로 동기화해야 함:

```bash
cp -r ~/Desktop/opsidian/hr.shin/LearnLog/* ~/Desktop/혀란/quartz-learnlog/content/
cd ~/Desktop/혀란/quartz-learnlog
git add -A && git commit -m "sync from obsidian" && git push
```

push하면 GitHub Actions가 자동으로 빌드 + 배포.

---

## 주의사항

- **Quartz 기본 브랜치는 `v4`** — `main`이 아님
- Node 22 이상 필요 (nvm use 22)
- `content/index.md`가 홈페이지 — 메인 문서 바꾸면 여기도 갱신해야 함
- attachments 폴더 (이미지)도 같이 복사해야 이미지가 보임
