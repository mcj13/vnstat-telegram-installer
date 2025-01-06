# vnstat-telegram-installer

这是一个用于安装 `vnstat_telegram.sh` 脚本的安装程序，该脚本可以定期发送服务器的 CPU、内存、磁盘使用率和流量信息到 Telegram。

## 功能

*   自动安装 `vnstat` 和 `bc` 依赖。
*   自动配置 `crontab`，每天早上 8 点运行脚本。
*   自动创建 `/var/log/vnstat_telegram.log` 日志文件。
*   通过 Telegram Bot 发送服务器信息。
*   交互式安装，引导用户完成配置。

## 如何运行脚本

1.  使用以下命令下载并执行脚本：
    ```bash
    curl -sSL https://raw.githubusercontent.com/<你的用户名>/<你的仓库名>/main/install.sh | bash
    ```
    **注意：** 请将 `<你的用户名>` 和 `<你的仓库名>` 替换为你的实际用户名和仓库名。
2.  脚本将引导你完成安装过程，包括输入 Telegram Bot Token 和 Chat ID。

## 配置

*   **Telegram Bot Token：** 你需要创建一个 Telegram Bot 并获取其 Token。
*   **Telegram Chat ID：** 你需要获取你的 Telegram 聊天 ID，以便机器人可以发送消息给你。

## 日志

脚本的输出将被记录到 `/var/log/vnstat_telegram.log` 文件中。

## 注意事项

*   请确保你的服务器已安装 `curl` 命令。
*   脚本需要 `sudo` 权限才能安装依赖和配置 `crontab`。
*   请定期查看日志文件，以便及时发现问题。
