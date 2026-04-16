# 中国服务器炉石传说 Token 获取指南

## 问题背景

在中国服务器登录炉石传说时，登录工具 (`login`) 可能会遇到 `localhost:0` 回调 URL 的问题，导致无法自动提取和加密 token。

## 解决方案

### 方法一：手动提取并加密 Token（推荐）

#### 步骤 1：获取回调 URL
1. 运行登录工具：
   ```bash
   cd hearthstone
   ../login/login
   ```
2. 在打开的窗口中完成 Battle.net 登录
3. 登录成功后，你会看到一个类似这样的回调 URL：
   ```
   http://localhost:0/?ST=CN-5bb2de31fba875c01427f99d696fe47f-206371446&accountId=206371446&flowTrackingId=&flow_type=hard_account_login
   ```

#### 步骤 2：提取 ST 令牌
从 URL 中提取 `ST=` 参数后面的值：
```bash
ST_TOKEN="CN-5bb2de31fba875c01427f99d696fe47f-206371446"
```

#### 步骤 3：加密 Token
```bash
# 进入项目根目录
cd /home/tyrion/project/hearthstone-linux

# 编译加密工具（如果尚未编译）
g++ -o encrypt_token encrypt_token.c -lcryptopp

# 进入游戏目录并加密 token
cd hearthstone
../encrypt_token "$ST_TOKEN"
```

#### 步骤 4：启动游戏
```bash
./Bin/Hearthstone.x86_64
```

### 方法二：使用快捷方式

#### 创建快捷方式
已创建两个桌面快捷方式：
1. **Hearthstone Login** - 登录工具
2. **Hearthstone** - 游戏启动器

位置：`~/.local/share/applications/`

#### 一键命令
```bash
# 完整流程（从获取 URL 到启动游戏）
cd /home/tyrion/project/hearthstone-linux/hearthstone && \
ST_TOKEN="你的ST令牌" && \
../encrypt_token "$ST_TOKEN" && \
./Bin/Hearthstone.x86_64
```

## 故障排除

### 1. 编译 encrypt_token 失败
```bash
# 确保已安装 cryptopp 库
sudo pacman -S crypto++

# 使用 g++ 而不是 gcc 编译
g++ -o encrypt_token encrypt_token.c -lcryptopp
```

### 2. 登录工具无法处理 localhost:0
这是已知问题，登录工具可能无法正确处理端口为 0 的回调 URL。手动提取 ST 令牌是当前的最佳解决方案。

### 3. Token 过期
当 token 过期时：
```bash
# 1. 删除旧 token
rm hearthstone/token

# 2. 重新登录获取新 ST 令牌
# 3. 使用 encrypt_token 加密新令牌
# 4. 启动游戏
```

## 文件说明

- `login/login` - 登录工具（国际服）
- `login/loginCn.c` - 中国服务器登录工具（如果需要修改）
- `encrypt_token` - 令牌加密工具
- `hearthstone/token` - 加密后的令牌文件（48字节）
- `hearthstone/token_raw.txt` - 原始 ST 令牌（明文）

## 注意事项

1. **安全警告**：不要分享你的 ST 令牌，它等同于你的账号密码
2. **备份**：建议备份 `hearthstone/token` 文件
3. **多账号**：如果需要切换账号，删除 `token` 文件并重新登录
4. **国际服 vs 中国服**：中国服务器使用 `account.battlenet.com.cn`，国际服使用 `account.battle.net`

## 自动化脚本

项目根目录包含以下辅助脚本：
- `create_token_from_url.sh` - 从回调 URL 创建 token
- `中国服务器获取token.md` - 本文档

## 相关链接

- 项目 GitHub: https://github.com/0xf4b1/hearthstone-linux
- Battle.net 中国: https://account.battlenet.com.cn
- 问题反馈: 项目 GitHub Issues