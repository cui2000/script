#!/bin/sh
# 用于部署bash-tutorial

tutorialDir=/home/soft/tutorial
bashTutorialDir=$tutorialDir/bash-tutorial
if [ -d "$bashTutorialDir" ]; then
  cd $bashTutorialDir
  # 更新
  git pull
  npm run build-and-commit
else
  yum install -y git npm
  mkdir -p $tutorialDir
  cd $tutorialDir
  git clone https://github.com/wangdoc/bash-tutorial.git
  cd $bashTutorialDir
  # 更新
  npm update
  # 安装
  npm install
  # 编译
  npm run build-and-commit
fi

echo "网页已生成，路径：$bashTutorialDir/dist"
