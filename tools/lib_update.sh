#!/usr/bin/env bash
#
# 项目依赖安装脚本
#
# 该脚本用于自动化安装项目的依赖，包括通过 apt 安装、pip 安装、
# 第三方源码编译安装以及使用 rosdep 管理 ROS 依赖。
#
# 使用说明：
#  - ./tools/lib_update [参数]
#
# 参数：
#  - 无需参数，此脚本将依次执行所有安装步骤。
#
# 注意：
#  - 确保已正确配置 ROS2 环境
#  - 使用国内源更新 rosdep 依赖以加快速度
#
# 作者: Zhao Jun
# 日期: 2024-11-21

# ------------------ 配置 ------------------
set -e  # 遇到错误立即退出
script=$(readlink -f "$0")  # 获取当前脚本的绝对路径
route=$(dirname "$script")  # 获取当前脚本的目录

# 环境变量设置
source /opt/ros/humble/setup.bash  # 设置 ROS Humble 环境变量

# 默认依赖包列表
apt_packages=(   # (包名=版本号)
    "clang-format"
    "python3-pip"
    "libqt5serialport5-dev"
    "ccache"
)

pip_packages=( # (包名==版本号)
    "rosdep==0.23.0"
    "rosdepc"  # 确保使用正确的包名
    "matplotlib"
)

# ------------------ 日志函数 ------------------
log_info() {
    echo "ℹ️  [INFO] $(date +'%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo "✅ [SUCCESS] $(date +'%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo "⚠️  [WARNING] $(date +'%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo "❌ [ERROR] $(date +'%Y-%m-%d %H:%M:%S') - $1"
}

# ------------------ 函数定义 ------------------

# 函数：安装 apt 软件包
install_apt_packages() {
    log_info "开始通过 apt 安装软件包..."

    sudo apt update

    for package in "${apt_packages[@]}"; do
        pkg_name="${package%%=*}"     # 获取包名
        pkg_version="${package##*=}"  # 获取版本号

        # 检查是否指定了版本
        if [[ "$pkg_name" == "$pkg_version" ]]; then
            pkg_version=""  
        fi

        # 检查是否已安装
        if dpkg -l | grep -qw "$pkg_name"; then
            log_info "$pkg_name 已安装，跳过"
        else
            if [[ -n "$pkg_version" ]]; then
                log_info "安装 $pkg_name 版本 $pkg_version"
                sudo apt install -y "$pkg_name=$pkg_version"
            else
                log_info "安装 $pkg_name"
                sudo apt install -y "$pkg_name"
            fi
        fi
    done

    log_success "apt 软件包安装完成"
}

# 函数：安装 pip 软件包
install_pip_packages() {
    log_info "开始通过 pip 安装软件包..."

    for package in "${pip_packages[@]}"; do
        pkg_name="${package%%==*}"     # 获取包名
        pkg_version="${package##*==}"  # 获取版本号

        # 检查是否指定了版本
        if [[ "$pkg_name" == "$pkg_version" ]]; then
            pkg_version=""  # 如果未指定版本，则版本部分为空
        fi

        # 检查是否已安装
        if pip show "$pkg_name" &> /dev/null; then
            log_info "$pkg_name 已安装，跳过"
        else
            if [[ -n "$pkg_version" ]]; then
                log_info "安装 $pkg_name 版本 $pkg_version"
                pip install "$pkg_name==$pkg_version"
            else
                log_info "安装 $pkg_name"
                pip install "$pkg_name"
            fi
        fi
    done

    log_success "pip 软件包安装完成"
}

# 函数：检查并安装 ROS 依赖
install_ros_packages() {
    log_info "开始安装 ROS 依赖..."

    cd "$route/../"

    # 检查 rosdep 是否初始化
    if [ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]; then
        log_info "初始化 rosdep"
        sudo rosdep init
        sudo rosdepc init
    else
        log_info "rosdep 已经初始化，跳过 init"
    fi

    log_info "更新 rosdep"
    rosdepc update --rosdistro humble --include-eol-distros

    log_info "安装依赖包"
    rosdepc install --from-paths src --ignore-src -r -y

    log_success "ROS 依赖安装完成"
}

# 函数：安装从源码编译的第三方软件
install_3dp_packages(){
    log_info "开始从源码安装第三方软件..."

    third_party_dir="$route/../third_party"

    if [ -d "$third_party_dir" ]; then
        cd "$third_party_dir"
        if [ -f "build_and_install.sh" ]; then
            chmod +x build_and_install.sh
            ./build_and_install.sh
            log_success "第三方软件安装完成"
        else
            log_warning "未找到 build_and_install.sh 脚本，跳过第三方软件安装"
        fi
    else
        log_warning "未找到 third_party 目录，跳过第三方软件安装"
    fi
}

# 函数：更新共享库的缓存
update_ldconfig() {
    log_info "更新共享库缓存..."
    sudo ldconfig
    log_success "共享库缓存更新完成"
}

# ------------------ 主流程 ------------------
main() {
    log_info "开始安装依赖..."

    cd "$route/../"

    # 运行时依赖安装
    install_apt_packages
    install_pip_packages
    install_3dp_packages
    install_ros_packages

    # 更新共享库缓存
    update_ldconfig

    log_success "依赖安装完成!"
}

# 执行主流程
main "$@"
