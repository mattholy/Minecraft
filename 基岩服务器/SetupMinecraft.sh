#!/bin/bash

echo "Minecraft基岩服务器一键开服工具 由Mattholy汉化并修改。"
echo "最新的基岩版本服务端可以在以下地址找到：https://github.com/TheRemote/MinecraftBedrockServer"

# Function to read input from user with a prompt
function read_with_prompt {
  variable_name="$1"
  prompt="$2"
  default="${3-}"
  unset $variable_name
  while [[ ! -n ${!variable_name} ]]; do
    read -p "$prompt: " $variable_name < /dev/tty
    if [ ! -n "`which xargs`" ]; then
      declare -g $variable_name=$(echo "${!variable_name}" | xargs)
    fi
    declare -g $variable_name=$(echo "${!variable_name}" | head -n1 | awk '{print $1;}')
    if [[ -z ${!variable_name} ]] && [[ -n "$default" ]] ; then
      declare -g $variable_name=$default
    fi
    echo -n "$prompt : ${!variable_name} -- 同意吗？ (y/n)?"
    read answer < /dev/tty
    if [ "$answer" == "${answer#[Yy]}" ]; then
      unset $variable_name
    else
      echo "$prompt: ${!variable_name}"
    fi
  done
}

# Install dependencies required to run Minecraft server in the background
echo "正在安装：screen, unzip, sudo, net-tools, wget..."
if [ ! -n "`which sudo`" ]; then
  apt-get update && apt-get install sudo -y
fi
sudo apt-get update
sudo apt-get install screen unzip wget -y
sudo apt-get install net-tools -y
sudo apt-get install libcurl4 -y
sudo apt-get install openssl -y

# Check to see if Minecraft server main directory already exists
cd ~
if [ ! -d "minecraftbe" ]; then
  mkdir minecraftbe
  cd minecraftbe
else
  cd minecraftbe
  if [ -f "bedrock_server" ]; then
    echo "迁移旧的基岩服务器至 minecraftbe/old"
    cd ~
    mv minecraftbe old
    mkdir minecraftbe
    mv old minecraftbe/old
    cd minecraftbe
    echo "迁移完成，旧的服务器位置为 minecraftbe/old"
  fi
fi

# Server name configuration
echo "请输入一个词作为基岩服务器在系统中注册服务所用的名字..."
echo "仅可使用大小写字母和数字..."

read_with_prompt ServerName "服务器名字"

echo "请输入要用于IPv4开服的端口 (默认为19132): "
read_with_prompt PortIPV4 "IPv4端口" 19132

echo "请输入要用于IPv6开服的端口 (默认为19133): "
read_with_prompt PortIPV6 "IPv6端口" 19133

if [ -d "$ServerName" ]; then
  echo "目录 minecraftbe/$ServerName 已经存在！正在更新脚本并应用设置..."

  # Get Home directory path and username
  DirName=$(readlink -e ~)
  UserName=$(whoami)
  cd ~
  cd minecraftbe
  cd $ServerName
  echo "\033[1;32m服务器目录是: $DirName/minecraftbe/$ServerName\033[0m"

  # Remove existing scripts
  rm start.sh stop.sh restart.sh

  # Download start.sh from repository
  echo "正在从远程代码仓库下载启动脚本 start.sh ..."
  wget -O start.sh https://raw.githubusercontent.com/mattholy/Minecraft/master/%E5%9F%BA%E5%B2%A9%E6%9C%8D%E5%8A%A1%E5%99%A8/start.sh
  chmod +x start.sh
  sed -i "s:dirname:$DirName:g" start.sh
  sed -i "s:servername:$ServerName:g" start.sh

  # Download stop.sh from repository
  echo "正在从远程代码仓库下载停止脚本 stop.sh ..."
  wget -O stop.sh https://raw.githubusercontent.com/mattholy/Minecraft/master/%E5%9F%BA%E5%B2%A9%E6%9C%8D%E5%8A%A1%E5%99%A8/stop.sh
  chmod +x stop.sh
  sed -i "s:dirname:$DirName:g" stop.sh
  sed -i "s:servername:$ServerName:g" stop.sh

  # Download restart.sh from repository
  echo "正在从远程代码仓库下载重启脚本 restart.sh ..."
  wget -O restart.sh https://raw.githubusercontent.com/mattholy/Minecraft/master/%E5%9F%BA%E5%B2%A9%E6%9C%8D%E5%8A%A1%E5%99%A8/restart.sh
  chmod +x restart.sh
  sed -i "s:dirname:$DirName:g" restart.sh
  sed -i "s:servername:$ServerName:g" restart.sh

  # Update minecraft server service
  echo "正在设置 $ServerName 的启动服务..."
  sudo wget -O /etc/systemd/system/$ServerName.service https://raw.githubusercontent.com/mattholy/Minecraft/master/%E5%9F%BA%E5%B2%A9%E6%9C%8D%E5%8A%A1%E5%99%A8/minecraftbe.service
  sudo chmod +x /etc/systemd/system/$ServerName.service
  sudo sed -i "s/replace/$UserName/g" /etc/systemd/system/$ServerName.service
  sudo sed -i "s:dirname:$DirName:g" /etc/systemd/system/$ServerName.service
  sudo sed -i "s:servername:$ServerName:g" /etc/systemd/system/$ServerName.service
  sed -i "/server-port=/c\server-port=$PortIPV4" server.properties
  sed -i "/server-portv6=/c\server-portv6=$PortIPV6" server.properties
  sudo systemctl daemon-reload
  echo -n "是否在系统启动时自动启动Minecraft服务器 (y/n)?"
  read answer < /dev/tty
  if [ "$answer" != "${answer#[Yy]}" ]; then
    sudo systemctl enable $ServerName.service

    # Automatic reboot at 4am configuration
    echo -n "是否在每日 4:00 p.m. 自动备份并重启服务器 (y/n)?"
    read answer < /dev/tty
    if [ "$answer" != "${answer#[Yy]}" ]; then
      croncmd="$DirName/minecraftbe/$ServerName/restart.sh"
      cronjob="0 4 * * * $croncmd"
      ( crontab -l | grep -v -F "$croncmd" ; echo "$cronjob" ) | crontab -
      echo "每日重启安排上了。要想更改时间或取消自动重启，请输入 crontab -e"
    fi
  fi

  # Setup completed
  echo "\033[1;32m服务器建立完成，正在启动Minecraft $ServerName 服务器...\033[0m"
  sudo systemctl start $ServerName.service

  # Sleep for 4 seconds to give the server time to start
  sleep 4s

  screen -r $ServerName

  exit 0
fi

# Create server directory
echo "正在建立Minecraft服务器工作目录 (~/minecraftbe/$ServerName)..."
cd ~
cd minecraftbe
mkdir $ServerName
cd $ServerName
mkdir downloads
mkdir backups

# Check CPU archtecture to see if we need to do anything special for the platform the server is running on
echo "正在检查系统信息(CPU,GPU,RAM etc.)..."
CPUArch=$(uname -m)
echo "系统架构: $CPUArch"
if [[ "$CPUArch" == *"aarch"* || "$CPUArch" == *"arm"* ]]; then
  # ARM architecture detected -- download QEMU and dependency libraries
  echo "检测到系统为ARM平台 -- 正在安装依赖..."
  # Check if latest available QEMU version is at least 3.0 or higher
  QEMUVer=$(apt-cache show qemu-user-static | grep Version | awk 'NR==1{ print $2 }' | cut -c3-3)
  if [[ "$QEMUVer" -lt "3" ]]; then
    echo "\033[1;33m可用的QEMU版本不足以模拟x86_64，正下载替代版本...\033[0m"
    if [[ "$CPUArch" == *"armv7"* || "$CPUArch" == *"armhf"* ]]; then
      wget http://ftp.us.debian.org/debian/pool/main/q/qemu/qemu-user-static_3.1+dfsg-7_armhf.deb
      wget http://ftp.us.debian.org/debian/pool/main/b/binfmt-support/binfmt-support_2.2.0-2_armhf.deb
      sudo dpkg --install binfmt*.deb
      sudo dpkg --install qemu-user*.deb
    elif [[ "$CPUArch" == *"aarch64"* || "$CPUArch" == *"arm64"* ]]; then
      wget http://ftp.us.debian.org/debian/pool/main/q/qemu/qemu-user-static_3.1+dfsg-7_arm64.deb
      wget http://ftp.us.debian.org/debian/pool/main/b/binfmt-support/binfmt-support_2.2.0-2_arm64.deb
      sudo dpkg --install binfmt*.deb
      sudo dpkg --install qemu-user*.deb
    fi
  else
    sudo apt-get install qemu-user-static binfmt-support -y
  fi

  if [ -n "`which qemu-x86_64-static`" ]; then
    echo "成功安装了QEMU-x86_64-static"
  else
    echo "\033[1;31mQEMU-x86_64-static未能成功安装 -- 请参见上述错误信息。\033[0m"
    exit 1
  fi
  
  # Retrieve depends.zip from GitHub repository
  wget -O depends.zip https://raw.githubusercontent.com/mattholy/Minecraft/master/%E5%9F%BA%E5%B2%A9%E6%9C%8D%E5%8A%A1%E5%99%A8/depends.zip
  unzip depends.zip
  sudo mkdir /lib64
  # Create soft link ld-linux-x86-64.so.2 mapped to ld-2.28.so
  sudo ln -s ~/minecraftbe/$ServerName/ld-2.28.so /lib64/ld-linux-x86-64.so.2
fi

# Retrieve latest version of Minecraft Bedrock dedicated server
echo "正在检查Minecraft基岩服务器的最新版本..."
wget -O downloads/version.html https://minecraft.net/en-us/download/server/bedrock/
DownloadURL=$(grep -o 'https://minecraft.azureedge.net/bin-linux/[^"]*' downloads/version.html)
DownloadFile=$(echo "$DownloadURL" | sed 's#.*/##')
echo "$DownloadURL"
echo "$DownloadFile"

# Download latest version of Minecraft Bedrock dedicated server
echo "正在下载最新版本的Minecraft基岩版服务端..."
UserName=$(whoami)
DirName=$(readlink -e ~)
wget -O "downloads/$DownloadFile" "$DownloadURL"
unzip -o "downloads/$DownloadFile"

# Download start.sh from repository
echo "正在从远程代码仓库下载启动脚本 start.sh ..."
wget -O start.sh https://raw.githubusercontent.com/mattholy/Minecraft/master/%E5%9F%BA%E5%B2%A9%E6%9C%8D%E5%8A%A1%E5%99%A8/start.sh
chmod +x start.sh
sed -i "s:dirname:$DirName:g" start.sh
sed -i "s:servername:$ServerName:g" start.sh

# Download stop.sh from repository
echo "正在从远程代码仓库下载停止脚本 stop.sh ..."
wget -O stop.sh https://raw.githubusercontent.com/mattholy/Minecraft/master/%E5%9F%BA%E5%B2%A9%E6%9C%8D%E5%8A%A1%E5%99%A8/stop.sh
chmod +x stop.sh
sed -i "s:dirname:$DirName:g" stop.sh
sed -i "s:servername:$ServerName:g" stop.sh

# Download restart.sh from repository
echo "正在从远程代码仓库下载重启脚本 restart.sh ..."
wget -O restart.sh https://raw.githubusercontent.com/mattholy/Minecraft/master/%E5%9F%BA%E5%B2%A9%E6%9C%8D%E5%8A%A1%E5%99%A8/restart.sh
chmod +x restart.sh
sed -i "s:dirname:$DirName:g" restart.sh
sed -i "s:servername:$ServerName:g" restart.sh

# Service configuration
echo "开始设置Minecraft $ServerName 服务器..."
sudo wget -O /etc/systemd/system/$ServerName.service https://raw.githubusercontent.com/mattholy/Minecraft/master/%E5%9F%BA%E5%B2%A9%E6%9C%8D%E5%8A%A1%E5%99%A8/minecraftbe.service
sudo chmod +x /etc/systemd/system/$ServerName.service
sudo sed -i "s/replace/$UserName/g" /etc/systemd/system/$ServerName.service
sudo sed -i "s:dirname:$DirName:g" /etc/systemd/system/$ServerName.service
sudo sed -i "s:servername:$ServerName:g" /etc/systemd/system/$ServerName.service
sed -i "/server-port=/c\server-port=$PortIPV4" server.properties
sed -i "/server-portv6=/c\server-portv6=$PortIPV6" server.properties
sudo systemctl daemon-reload

echo -n "是否在系统启动时自动启动Minecraft服务器 (y/n)?"
read answer < /dev/tty
if [ "$answer" != "${answer#[Yy]}" ]; then
  sudo systemctl enable $ServerName.service

  # Automatic reboot at 4am configuration
  TimeZone=$(cat /etc/timezone)
  CurrentTime=$(date)
  echo "你的当前时区为 $TimeZone，当前时间为 $CurrentTime"
  echo "要想更改自动重启时间或取消自动重启，请输入 crontab -e"
  echo -n "是否在每日 4:00 p.m. 自动备份并重启服务器 (y/n)?"
  read answer < /dev/tty
  if [ "$answer" != "${answer#[Yy]}" ]; then
    croncmd="$DirName/minecraftbe/$ServerName/restart.sh"
    cronjob="0 4 * * * $croncmd"
    ( crontab -l | grep -v -F "$croncmd" ; echo "$cronjob" ) | crontab -
    echo "每日重启安排上了。要想更改时间或取消自动重启，请输入 crontab -e"
  fi
fi

# Finished!
echo "\033[1;32m服务器建立完成，正在启动Minecraft $ServerName 服务器...\033[0m"
sudo systemctl start $ServerName.service

# Wait up to 20 seconds for server to start
StartChecks=0
while [ $StartChecks -lt 20 ]; do
  if screen -list | grep -q "$ServerName"; then
    break
  fi
  sleep 1;
  StartChecks=$((StartChecks+1))
done

# Force quit if server is still open
if ! screen -list | grep -q "$ServerName"; then
  echo "服务器未能在20秒内启动成功"
else
  echo "\033[1;32m服务器建立完成，正在启动Minecraft $ServerName 服务器...\033[0m"
fi

# Attach to screen
screen -r $ServerName
