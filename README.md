# vnstat-telegram-installer

这是一个用于安装和配置 `vnstat-telegram` 脚本的安装程序。该脚本可以定期通过 Telegram 机器人发送服务器的状态信息（如 CPU 使用率、内存使用率、磁盘使用率和网络流量）。

## 功能
- 自动安装依赖项（`vnstat`, `bc`, `curl`）
- 验证 Telegram Bot Token 和 Chat ID
- 部署并配置脚本
- 配置 crontab 以每天定时运行脚本
- 创建日志文件

## 安装步骤

1. **下载脚本**
   
   `curl -sSL https://raw.githubusercontent.com/mcj13/vnstat-telegram-installer/main/install.sh -o install.sh`
   

2. **执行脚本**
   
   \`bash install.sh\`
   

3. **按照提示操作**
   - 输入 Telegram Bot Token 和 Chat ID
   - 选择安装路径（默认为 `/usr/local/bin/`）
   - 脚本会自动安装依赖项、验证凭证、部署脚本并配置 crontab

## 使用方法

1. **确保以 root 用户或使用 `sudo` 执行脚本**
   
   \`sudo bash install.sh\`
   

2. **输入 Telegram Bot Token 和 Chat ID**
   - 你可以从 [BotFather](https://t.me/botfather) 获取 Bot Token。
   - 你可以从 [userinfobot](https://t.me/userinfobot) 获取 Chat ID。

3. **选择安装路径**
   - 默认安装路径为 `/usr/local/bin/`，如果需要自定义路径，请在提示时输入。

4. **查看日志文件**
   - 日志文件位于 `/var/log/vnstat_telegram.log`。

5. **修改 crontab**
   - 如果需要手动修改 crontab，可以使用以下命令：
     
     \`crontab -e\`
     
   - 在打开的编辑器中添加或修改以下行：
     
     \`0 8 * * * /usr/local/bin/vnstat_telegram.sh >> /var/log/vnstat_telegram.log 2&gt;&1\`
     

## 常见问题解答

### 1. 如何获取 Telegram Bot Token？
- 你可以从 [BotFather](https://t.me/botfather) 获取 Bot Token。详细步骤如下：
  1. 打开 Telegram 并搜索 `@BotFather`。
  2. 发送 `/newbot` 命令创建一个新的 bot。
  3. 按照指示设置 bot 的名称和用户名。
  4. 完成后，BotFather 会返回一个 API Token。

### 2. 如何获取 Telegram Chat ID？
- 你可以从 [userinfobot](https://t.me/userinfobot) 获取 Chat ID。详细步骤如下：
  1. 打开 Telegram 并搜索 `@userinfobot`。
  2. 发送 `/start` 命令。
  3. 发送一条消息，userinfobot 会回复你的 Chat ID。

### 3. 脚本部署失败怎么办？
- 确保你有 root 权限。
- 确保网络连接正常。
- 检查安装路径是否有写入权限。
- 查看日志文件 `/var/log/vnstat_telegram.log` 以获取更多错误信息。

## 贡献
欢迎贡献代码或提出建议！请通过 GitHub Issues 或 Pull Requests 参与项目。

## 许可
本项目采用 MIT 许可协议。详见 [LICENSE](LICENSE) 文件。
