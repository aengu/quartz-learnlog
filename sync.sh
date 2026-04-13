#!/bin/bash
# 사용법: ~/Desktop/혀란/quartz-learnlog/sync.sh
cp -r ~/Desktop/opsidian/hr.shin/LearnLog/* ~/Desktop/혀란/quartz-learnlog/content/
cd ~/Desktop/혀란/quartz-learnlog
git add -A && git commit -m "sync from obsidian" && git push
echo "✓ 배포 완료! 1-2분 후 반영됨: https://aengu.github.io/quartz-learnlog/"
