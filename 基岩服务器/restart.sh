#!/bin/bash
# James Chambers
# Minecraft Bedrock Server restart script

# Check if server is started
if ! screen -list | grep -q "servername"; then
    echo "服务器当前未运行！"
    exit 1
fi

echo "正在重启Minecraft服务器..."

# Start countdown notice on server
screen -Rd servername -X stuff "say §c服务器将在§f60秒§c后重启，请合理安排您的活动...$(printf '\r')"
sleep 30;
screen -Rd servername -X stuff "say §c服务器将在§f30秒§c后重启，请合理安排您的活动...$(printf '\r')"
sleep 10;
screen -Rd servername -X stuff "say §c服务器将在§f20秒§c后重启，请合理安排您的活动...$(printf '\r')"
sleep 10;
screen -Rd servername -X stuff "say §c服务器将在§f10秒§c后重启，请合理安排您的活动...$(printf '\r')"
sleep 5;
screen -Rd servername -X stuff "say §c服务器将在§f5秒§c后重启，请合理安排您的活动...$(printf '\r')"
sleep 1;
screen -Rd servername -X stuff "say §c服务器将在§f4秒§c后重启，请合理安排您的活动...$(printf '\r')"
sleep 1;
screen -Rd servername -X stuff "say §c服务器将在§f3秒§c后重启，请合理安排您的活动...$(printf '\r')"
sleep 1;
screen -Rd servername -X stuff "say §c服务器将在§f2秒§c后重启，请合理安排您的活动...$(printf '\r')"
sleep 1;
screen -Rd servername -X stuff "say §c服务器将在§f1秒§c后重启，请合理安排您的活动...$(printf '\r')"
sleep 1s
screen -Rd servername -X stuff "say 正在关闭服务器...$(printf '\r')"
screen -Rd servername -X stuff "stop$(printf '\r')"

echo "Closing server..."
# Wait up to 30 seconds for server to close
StopChecks=0
while [ $StopChecks -lt 30 ]; do
  if ! screen -list | grep -q "servername"; then
    break
  fi
  sleep 1;
  StopChecks=$((StopChecks+1))
done

if screen -list | grep -q "servername"; then
    # Server still hasn't stopped after 30s, tell Screen to close it
    echo "Minecraft服务器无法在30秒内停止，已执行手动关闭。"
    screen -S servername -X quit
    sleep 10
fi

# Start server
/bin/bash dirname/minecraftbe/servername/start.sh