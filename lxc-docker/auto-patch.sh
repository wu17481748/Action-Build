#!/bin/bash
# auto-patch.sh - 自动应用文件夹中的所有补丁
# 用法: ./auto-patch.sh <补丁文件夹> [内核源码目录]

#set -e  # 发生错误立即退出

PATCH_DIR="$1"
KERNEL_DIR="${2:-.}"  # 默认当前目录为内核源码目录

# 参数检查
if [ -z "$PATCH_DIR" ]; then
    echo "用法: $0 <补丁文件夹> [内核源码目录]"
    exit 1
fi

if [ ! -d "$PATCH_DIR" ]; then
    echo "错误: 补丁文件夹 '$PATCH_DIR' 不存在"
    exit 1
fi

if [ ! -d "$KERNEL_DIR" ]; then
    echo "错误: 内核源码目录 '$KERNEL_DIR' 不存在"
    exit 1
fi

# 切换到内核源码目录
cd "$KERNEL_DIR"

# 检查 patch 命令是否可用
if ! command -v patch &> /dev/null; then
    echo "错误: 未找到 patch 命令，请安装 patch 工具"
    exit 1
fi

# 查找所有 .patch 文件并按名称排序
patches=$(find "$PATCH_DIR" -maxdepth 1 -name "*.patch" | sort)

if [ -z "$patches" ]; then
    echo "在 $PATCH_DIR 中没有找到 .patch 文件"
    exit 0
fi

# 依次应用每个补丁
for patch_file in $patches; do
    echo "正在应用 $patch_file ..."
    patch -p1 < "$patch_file"
    echo "成功应用 $patch_file"
done

echo "所有补丁应用完成！"
