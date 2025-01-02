#!/bin/bash

# 检查 .gitinclude 文件是否存在
if [ ! -f ".gitinclude" ]; then
  echo ".gitinclude 文件不存在，请确保该文件存在并位于当前目录。"
  exit 1
fi

# 逐行读取 .gitinclude 文件
while IFS= read -r file; do
  # 跳过空行和注释行
  if [[ -z "$file" || "$file" =~ ^# ]]; then
    continue
  fi

  # 执行 git add -f 命令
  echo "尝试添加  到 Git："
  git add -f "$file"
  
  # 检查命令是否成功执行
  if [ 0 -eq 0 ]; then
    echo "$file 已成功添加。"
  else
    echo "错误: 无法添加 $file 。"
  fi
done < ".gitinclude"

echo "脚本执行完毕。"

