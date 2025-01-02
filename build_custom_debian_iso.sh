#!/bin/bash

# 设定镜像名称、版本、架构等变量
ISO_NAME="custom_debian_iso"
DEBIAN_VERSION="bookworm"      # 你可以根据需要修改 Debian 版本
ARCHITECTURE="amd64"           # 镜像架构（例如：amd64, arm64）
ISO_OUTPUT_DIR="~/iso_output"  # 输出目录
OFFLINE_DEB_DIR="./offline_debs"  # 离线 .deb 包存放目录

# 设置 Live 镜像的额外软件包
PACKAGE_LIST="my_custom_list.list"

# 设置配置文件目录
CONFIG_DIR="./custom_live_config"

# 用户配置
USER_NAME="bye22"         # 设置要创建的用户名
USER_PASSWORD="q"       # 设置用户密码
USER_FULL_NAME="bye22"   # 用户的全名

# 检查依赖项
echo "检查是否已安装必要的工具..."
for pkg in live-build debootstrap; do
  dpkg -l | grep -qw $pkg || {
    echo "$pkg 未安装，正在安装..."
    sudo apt-get install -y $pkg
  }
done

# 创建工作目录
echo "创建工作目录..."
mkdir -p $CONFIG_DIR
cd $CONFIG_DIR

# 配置镜像构建环境
echo "初始化 live-build 配置..."
lb config \ 
	--debian-installer cdrom \ 
	--bootappend-live 'boot=live'  \ 
	--iso-application debian \ 
	--iso-volume debian-12-bookworm-live-install \ 
	--architecture $ARCHITECTURE \
	--distribution $DEBIAN_VERSION \
	--binary-images iso-hybrid

# 配置自定义软件包列表
echo "配置软件包列表..."
mkdir -p config/package-lists
cat <<EOF > config/package-lists/$PACKAGE_LIST
vim
htop
curl
git
timeshift
wget
openssh-server
build-essential
libx11-dev
libxft-dev
libxinerama-dev
libxcb1-dev
EOF

# 配置其他定制选项（例如源列表、网络配置等）
echo "配置源列表..."
mkdir -p config/includes.chroot/etc
cat <<EOF > config/includes.chroot/etc/apt/sources.list
# 中科大镜像站
deb https://mirrors.ustc.edu.cn/debian/ $DEBIAN_VERSION main contrib non-free non-free-firmware
deb-src https://mirrors.ustc.edu.cn/debian/ $DEBIAN_VERSION main contrib non-free non-free-firmware
deb https://mirrors.ustc.edu.cn/debian/ $DEBIAN_VERSION-updates main contrib non-free non-free-firmware
deb-src https://mirrors.ustc.edu.cn/debian/ $DEBIAN_VERSION-updates main contrib non-free non-free-firmware
deb https://mirrors.ustc.edu.cn/debian/ $DEBIAN_VERSION-backports main contrib non-free non-free-firmware
deb-src https://mirrors.ustc.edu.cn/debian/ $DEBIAN_VERSION-backports main contrib non-free non-free-firmware
deb https://mirrors.ustc.edu.cn/debian-security/ $DEBIAN_VERSION-security main contrib non-free non-free-firmware
deb-src https://mirrors.ustc.edu.cn/debian-security/ $DEBIAN_VERSION-security main contrib non-free non-free-firmware
EOF

# 配置安装时的脚本（例如自动配置时区、网络等）
echo "配置自定义脚本..."
mkdir -p config/includes.chroot/etc/skel
echo "export LANG=en_US.UTF-8" > config/includes.chroot/etc/skel/.bashrc
echo "LANG=en_US.UTF-8" > config/includes.chroot/etc/default/locale
echo "Asia/Shanghai" > config/includes.chroot/etc/timezone
echo "export DEBIAN_FRONTEND=noninteractive" > config/includes.chroot/etc/apt/apt.conf.d/70debconf

# 配置主机名和默认用户
echo "配置主机名和用户..."
mkdir -p config/includes.chroot/etc
echo "custom-debian" > config/includes.chroot/etc/hostname

# 创建用户并设置密码
cat <<EOF > config/includes.chroot/usr/local/bin/create_user.sh
#!/bin/bash

# 创建用户
useradd -m -s /bin/bash -c "$USER_FULL_NAME" $USER_NAME

# 设置用户密码
echo "$USER_NAME:$USER_PASSWORD" | chpasswd

# 创建用户目录
mkdir -p /home/$USER_NAME/.ssh
chown $USER_NAME:$USER_NAME /home/$USER_NAME/.ssh

# 为用户设置默认配置文件
echo "export PS1='[\u@\h \W]\$ '" > /home/$USER_NAME/.bashrc
echo "alias ll='ls -l'" >> /home/$USER_NAME/.bashrc
chown $USER_NAME:$USER_NAME /home/$USER_NAME/.bashrc

# 切换到用户目录，安装 chadwm
su - $USER_NAME -c "
# 更新系统并安装构建工具
sudo apt update && sudo apt install -y build-essential libx11-dev libxft-dev libxinerama-dev libxcb1-dev

# 克隆 chadwm 源码仓库
git clone https://github.com/chadwickjones/chadwm.git ~/chadwm

# 进入源码目录并编译安装
cd ~/chadwm
make
sudo make install

# 配置 chadwm 作为用户的默认窗口管理器
echo 'exec chadwm' > ~/.xinitrc
"

EOF
chmod +x config/includes.chroot/usr/local/bin/create_user.sh

# 配置 SSH 服务（如果需要）
echo "配置 SSH 服务..."
mkdir -p config/includes.chroot/etc/ssh
echo "PermitRootLogin yes" > config/includes.chroot/etc/ssh/sshd_config
echo "PasswordAuthentication yes" >> config/includes.chroot/etc/ssh/sshd_config

# 配置离线 deb 包
echo "配置离线 .deb 包..."
mkdir -p config/packages.offline

# 检查离线包目录是否存在
if [ -d "$OFFLINE_DEB_DIR" ]; then
  echo "将离线 .deb 包复制到镜像中..."
  cp $OFFLINE_DEB_DIR/*.deb config/packages.offline/
else
  echo "离线 .deb 包目录 $OFFLINE_DEB_DIR 不存在，跳过此步骤"
fi

# 配置安装离线包的脚本
echo "配置安装离线 .deb 包的脚本..."
mkdir -p config/includes.chroot/etc/apt
cat <<EOF > config/includes.chroot/usr/local/bin/install_offline_debs.sh
#!/bin/bash
dpkg -i /cdrom/packages.offline/*.deb
apt-get install -f
EOF
chmod +x config/includes.chroot/usr/local/bin/install_offline_debs.sh

# 开始构建镜像前执行系统更新
echo "执行系统更新..."
mkdir -p config/includes.chroot/etc/apt/apt.conf.d
echo "Acquire::http::No-Cache true;" > config/includes.chroot/etc/apt/apt.conf.d/99no-cache
echo "Acquire::http::ForceIPv4 true;" >> config/includes.chroot/etc/apt/apt.conf.d/99no-cache

# 配置自定义启动脚本（例如启动后运行更新和清理）
echo "配置启动时自动更新和清理..."
mkdir -p config/includes.chroot/etc/rc.local
cat <<EOF > config/includes.chroot/etc/rc.local
#!/bin/bash
apt-get update && apt-get upgrade -y
apt-get autoremove -y
apt-get clean
exit 0
EOF
chmod +x config/includes.chroot/etc/rc.local

# 配置自定义壁纸或其他文件（可选）
# echo "添加自定义文件..."
# cp /path/to/custom/file config/includes.chroot/etc/

# 配置启动器（例如 GRUB 配置，默认会使用 GRUB）
# 你可以根据需要定制 GRUB 配置

# 开始构建镜像
echo "开始构建自定义 ISO 镜像..."
sudo lb build

# 移动生成的 ISO 到指定目录
echo "移动 ISO 文件到输出目录..."
mkdir -p $ISO_OUTPUT_DIR
mv *.iso $ISO_OUTPUT_DIR/

echo "构建完成！ISO 文件位于 $ISO_OUTPUT_DIR"
