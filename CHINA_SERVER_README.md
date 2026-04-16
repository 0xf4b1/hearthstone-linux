# 中国服务器特别说明

## 分支信息

当前分支：`china-server-fix`

此分支专门针对中国服务器（国服）的炉石传说登录问题进行了优化。

## 主要修改

### 1. 新增文档
- `中国服务器获取token.md` - 详细的中国服务器登录指南
- `CHINA_SERVER_README.md` - 本文件

### 2. 新增工具
- `create_token_from_url.sh` - 自动化token创建脚本
- `encrypt_token` - 已编译的令牌加密工具
- `encrypt_token.c` - 加密工具源代码
- `encrypt_token.py` - Python版本加密工具

### 3. 代码备份
- `login/loginCn.c` - 中国服务器专用登录工具备份

## 解决的问题

### 主要问题：localhost:0 回调URL
中国服务器登录成功后，回调URL格式为：
```
http://localhost:0/?ST=CN-xxxxx-xxxxxx&accountId=xxxxxx
```
端口为0导致标准登录工具无法正确处理。

### 解决方案
手动提取ST令牌并使用`encrypt_token`工具加密。

## 快速开始

### 方法1：使用自动化脚本
```bash
# 从回调URL创建token
./create_token_from_url.sh "http://localhost:0/?ST=CN-xxxxx-xxxxxx&accountId=xxxxxx"

# 或直接使用ST令牌
./create_token_from_url.sh --token "CN-xxxxx-xxxxxx"
```

### 方法2：手动步骤
```bash
# 1. 提取ST令牌
ST_TOKEN="CN-xxxxx-xxxxxx"

# 2. 进入游戏目录
cd hearthstone

# 3. 加密令牌
../encrypt_token "$ST_TOKEN"

# 4. 启动游戏
./Bin/Hearthstone.x86_64
```

## 文件说明

| 文件 | 用途 | 是否必需 |
|------|------|----------|
| `hearthstone/token` | 加密后的令牌文件 | ✅ 是 |
| `hearthstone/token_raw.txt` | 原始ST令牌（明文） | ❌ 否，仅备份 |
| `encrypt_token` | 令牌加密工具 | ✅ 是 |
| `create_token_from_url.sh` | 自动化脚本 | ❌ 否，但推荐 |

## 切换回国际服

如果要切换回国际服（原始版本）：
```bash
git checkout master
```

## 贡献

如果你有更好的解决方案，欢迎：
1. 提交Pull Request到本分支
2. 在GitHub Issues中反馈问题
3. 改进文档和脚本

## 许可证

与原项目相同，遵循原项目的许可证协议。

## 免责声明

此修改版仅供技术研究使用，请遵守Battle.net用户协议。使用风险自负。