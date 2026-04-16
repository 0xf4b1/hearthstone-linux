#!/bin/bash
# 从回调URL创建炉石传说token文件
# 适用于中国服务器localhost:0回调问题

set -e

echo "=== 炉石传说中国服务器 Token 创建工具 ==="
echo ""

# 检查参数
if [ $# -eq 0 ]; then
    echo "用法: $0 <回调URL>"
    echo ""
    echo "示例:"
    echo "  $0 \"http://localhost:0/?ST=CN-5bb2de31fba875c01427f99d696fe47f-206371446&accountId=206371446\""
    echo ""
    echo "或者直接提供ST令牌:"
    echo "  $0 --token \"CN-5bb2de31fba875c01427f99d696fe47f-206371446\""
    exit 1
fi

# 解析参数
if [ "$1" = "--token" ]; then
    ST_TOKEN="$2"
    echo "🔧 使用提供的ST令牌: $ST_TOKEN"
else
    CALLBACK_URL="$1"
    echo "🔍 从URL提取ST令牌..."
    
    # 提取ST令牌
    ST_TOKEN=$(echo "$CALLBACK_URL" | grep -o 'ST=[^&]*' | cut -d= -f2)
    
    if [ -z "$ST_TOKEN" ]; then
        echo "❌ 无法从URL中提取ST令牌"
        echo "请检查URL格式，确保包含ST=参数"
        exit 1
    fi
    
    echo "✅ 提取到ST令牌: $ST_TOKEN"
fi

echo ""

# 验证令牌格式
if [[ ! "$ST_TOKEN" =~ ^CN-.*-[0-9]+$ ]]; then
    echo "⚠️  警告：令牌格式可能不正确"
    echo "期望格式: CN-xxxxx-xxxxxx"
    echo "实际格式: $ST_TOKEN"
    read -p "是否继续？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 进入游戏目录
GAME_DIR="hearthstone"
if [ ! -d "$GAME_DIR" ]; then
    echo "❌ 错误：找不到 $GAME_DIR 目录"
    echo "请确保在项目根目录运行此脚本"
    exit 1
fi

cd "$GAME_DIR"

# 保存原始令牌
echo "💾 保存原始令牌..."
echo "$ST_TOKEN" > token_raw.txt
echo "已保存到: $(pwd)/token_raw.txt"
echo ""

# 编译加密工具（如果需要）
if [ ! -f "../encrypt_token" ]; then
    echo "🔨 编译加密工具..."
    cd ..
    if [ ! -f "encrypt_token.c" ]; then
        echo "❌ 错误：找不到 encrypt_token.c"
        exit 1
    fi
    
    echo "编译命令: g++ -o encrypt_token encrypt_token.c -lcryptopp"
    g++ -o encrypt_token encrypt_token.c -lcryptopp
    
    if [ $? -ne 0 ]; then
        echo "❌ 编译失败"
        echo "请确保已安装 cryptopp 库:"
        echo "  Debian/Ubuntu: sudo apt install libcrypto++-dev"
        echo "  Arch/Manjaro: sudo pacman -S crypto++"
        exit 1
    fi
    
    echo "✅ 加密工具编译成功"
    cd "$GAME_DIR"
fi

# 加密令牌
echo "🔐 加密令牌..."
../encrypt_token "$ST_TOKEN"

if [ $? -ne 0 ]; then
    echo "❌ 加密失败"
    exit 1
fi

echo "✅ Token加密成功！"
echo ""

# 显示结果
echo "📊 结果摘要："
echo "----------------------------------------"
echo "原始令牌: $ST_TOKEN"
echo "加密文件: $(pwd)/token"
echo "文件大小: $(stat -c%s token) 字节"
echo "Hex输出:"
hexdump -C token | head -5
echo "----------------------------------------"
echo ""

# 检查游戏文件
if [ -f "Bin/Hearthstone.x86_64" ]; then
    echo "🎮 游戏可执行文件存在"
    echo ""
    echo "启动游戏命令:"
    echo "  ./Bin/Hearthstone.x86_64"
    echo ""
    echo "或使用快捷方式："
    echo "  1. 在应用程序菜单中搜索 'Hearthstone'"
    echo "  2. 点击 'Hearthstone' 图标启动游戏"
else
    echo "⚠️  警告：找不到游戏可执行文件"
    echo "请确保已运行 ./craft.sh 完成游戏安装"
fi

echo ""
echo "✅ 完成！"