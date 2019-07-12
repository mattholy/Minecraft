#!/bin/bash

# Check if server is running
if ! screen -list | grep -q "servername"; then
  echo "服务器当前未运行！"
  exit 1
fi

# Stop the server
echo "正在停止Minecraft服务器..."
screen -Rd servername -X stuff "say §c服务器将在§f60秒§c后关闭，请合理安排您的活动...$(printf '\r')"
sleep 30;
screen -Rd servername -X stuff "say §c服务器将在§f30秒§c后关闭，请合理安排您的活动...$(printf '\r')"
sleep 10;
screen -Rd servername -X stuff "say §c服务器将在§f20秒§c后关闭，请合理安排您的活动...$(printf '\r')"
sleep 10;
screen -Rd servername -X stuff "say §c服务器将在§f10秒§c后关闭，请合理安排您的活动...$(printf '\r')"
sleep 5;
screen -Rd servername -X stuff "say §c服务器将在§f5秒§c后关闭，请合理安排您的活动...$(printf '\r')"
sleep 1;
screen -Rd servername -X stuff "say §c服务器将在§f4秒§c后关闭，请合理安排您的活动...$(printf '\r')"
sleep 1;
screen -Rd servername -X stuff "say §c服务器将在§f3秒§c后关闭，请合理安排您的活动...$(printf '\r')"
sleep 1;
screen -Rd servername -X stuff "say §c服务器将在§f2秒§c后关闭，请合理安排您的活动...$(printf '\r')"
sleep 1;
screen -Rd servername -X stuff "say §c服务器将在§f1秒§c后关闭，请合理安排您的活动...$(printf '\r')"
sleep 1s
screen -Rd servername -X stuff "stop$(printf '\r')"

# Wait up to 20 seconds for server to close
StopChecks=0
while [ $StopChecks -lt 20 ]; do
  if ! screen -list | grep -q "servername"; then
    break
  fi
  sleep 1;
  StopChecks=$((StopChecks+1))
done

# Force quit if server is still open
if screen -list | grep -q "servername"; then
  echo "Minecraft服务器无法在20秒内停止，已执行手动关闭。"
  screen -S servername -X quit
fi

echo "Minecraft服务器 servername 已经停止了。"