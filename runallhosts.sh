#!/bin/bash

# 假设你的私钥文件是 ~/.ssh/id_rsa，并且已经添加到了目标服务器的authorized_keys中
PRIVATE_KEY_FILE=~/.ssh/id_rsa
REMOTE_PASSWORD='!qaZXsw@tianyi'
USER="root"  # 替换为你的用户名
COMMAND="/root/runntpscript.sh"  # 替换为你要执行的命令

# 检查参数数量
if [ "$#" -lt 1 ]; then
    echo "使用方法：$0 IP1 [IP2 ...]"
    exit 1
fi

# 遍历所有的命令行参数，这些应该是IP地址
for IP in "$@"; do
    echo "虚拟机IP: $IP"
    # 使用SSH登录并执行命令
    # 注意：这里使用了-o StrictHostKeyChecking=no来避免首次连接时的host key确认提示
    # 在生产环境中，你应该考虑其他方法来处理host key的验证
    #ssh -i "$PRIVATE_KEY_FILE" -o StrictHostKeyChecking=no "$USER@$IP" "$COMMAND"
    #sshpass -p "$REMOTE_PASSWORD" ssh "$USER@$IP" "$COMMAND"
    #sshpass -p $REMOTE_PASSWORD ssh "$USER@$IP" "$COMMAND"
    ssh "$USER@$IP" "$COMMAND"
    # 检查SSH命令的退出状态，并据此决定是否继续执行
    if [ $? -ne 0 ]; then
        echo "连接到 $IP 失败或命令执行出错"
    fi
done
