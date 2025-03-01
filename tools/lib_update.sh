

source /opt/ros/humble/setup.bash #设置humble环境变量


main() {
    log_info "开始安装依赖..."

    cd "$route/../"

    sudo apt update

    sudo apt-get install gazebo

    log_success "依赖安装完成!"
}