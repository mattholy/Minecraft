#!/bin/bash

# Check if server is already started
if screen -list | grep -q "servername"; then
    echo "服务器已经在运行中了！ 输入 screen -r servername 来打开它。"
    exit 1
fi

# Check if network interfaces are up
NetworkChecks=0
DefaultRoute=$(route -n | awk '$4 == "UG" {print $2}')
while [ -z "$DefaultRoute" ]; do
    echo "当前网络未链接，将在1秒后重试。";
    sleep 1;
    DefaultRoute=$(route -n | awk '$4 == "UG" {print $2}')
    NetworkChecks=$((NetworkChecks+1))
    if [ $NetworkChecks -gt 20 ]; then
        echo "等待网络超时 - 服务器将在无网络情况下启动..."
        break
    fi
done

# Change directory to server directory
cd dirname/minecraftbe/servername

# Create backup
if [ -d "worlds" ]; then
    echo "正在备份服务器至 minecraftbe/servername/backups"
    tar -pzvcf backups/$(date +%Y.%m.%d.%H.%M.%S).tar.gz worlds
fi

# Retrieve latest version of Minecraft Bedrock dedicated server
echo "正在检查Minecraft基岩服务器的最新版本..."

# Test internet connectivity first
wget --spider --quiet https://minecraft.net/en-us/download/server/bedrock/
if [ "$?" != 0 ]; then
    echo "未能连接至更新服务器（可能因为无网络连接）,跳过更新步骤..."
else
    # Download server index.html to check latest version
    wget -O downloads/version.html https://minecraft.net/en-us/download/server/bedrock/
    DownloadURL=$(grep -o 'https://minecraft.azureedge.net/bin-linux/[^"]*' downloads/version.html)
    DownloadFile=$(echo "$DownloadURL" | sed 's#.*/##')

    # Download latest version of Minecraft Bedrock dedicated server if a new one is available
    if [ -f "downloads/$DownloadFile" ]
    then
        echo "Minecraft基岩服务器已经是最新版..."
    else
        echo "检测到新版本 $DownloadFile ， 正在更新..."
        wget -O "downloads/$DownloadFile" "$DownloadURL"
        unzip -o "downloads/$DownloadFile" -x "*server.properties*" "*permissions.json*" "*whitelist.json*"
    fi
fi

echo "正在启动Minecraft基岩版服务器，要查看状态请输入 screen -r servername"
echo "要让服务器在后台运行，请按 Ctrl+A 然后 Ctrl+D"
screen -dmS servername /bin/bash -c "LD_LIBRARY_PATH=dirname/minecraftbe/servername dirname/minecraftbe/servername/bedrock_server"
