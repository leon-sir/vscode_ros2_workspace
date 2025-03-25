#!/usr/bin/env bash
#
# 项目构建脚本
#
# 该脚本用于构建 ROS2 项目，支持增量构建和清理构建目录。它会自动检测是否安装了 colcon 并根据不同的构建类型（Debug 或 Release）设置编译参数。
#
# 使用说明：
#  - ./tools/build.sh [参数]
#
# 参数：
#  - --clean     清理构建目录（build, install, log）
#  - --release   设置为 Release 构建类型（默认是 Debug 模式）
#  - --cmake-arg "ARG"  传递额外的 CMake 参数
#
# 注意：
#  - 确保已正确安装 ROS2 环境和 colcon 构建工具
#  - 默认使用所有可用 CPU 核心数减 2 个进行并行构建
#
# 作者: Zhao Jun
# 日期: 2024-11-21

# ------------------ 配置 ------------------
set -e  # 遇到错误立即退出
script=$(readlink -f "$0")  # 获取当前脚本的绝对路径
route=$(dirname "$script")  # 获取当前脚本的目录

# 环境变量设置
source /opt/ros/humble/setup.bash  # 设置 ROS Humble 环境变量

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

# 函数：检查 colcon 是否安装
check_colcon() {
    log_info "检查 colcon 是否安装..."
    if ! command -v colcon &> /dev/null; then
        log_error "未找到 colcon，请安装 colcon 后重试。"
        exit 1
    else
        log_success "colcon 已安装。"
    fi
}

# 函数：清理构建目录 (build, install, log)
clean_build_dirs() {
    log_info "开始清理构建目录..."
    for dir in build install log; do
        if [ -d "$dir" ]; then
            sudo rm -rf "$dir"
            log_success "$dir 目录已清理。"
        else
            log_warning "$dir 目录不存在，跳过。"
        fi
    done
    log_success "构建目录清理完成。"
}

# 函数：使用 colcon 构建项目，并生成编译命令文件以帮助 VSCode 索引依赖项
colcon_build() {
    log_info "开始使用 colcon 构建项目..."

    # 获取可用的并行工作线程数，确保至少为 1
    local parallel_workers=$(( $(nproc) - 2 ))
    if [ "$parallel_workers" -lt 1 ]; then
        parallel_workers=1
    fi

    log_info "并行工作线程数: $parallel_workers"

    log_info "CMake 构建参数: ${cmake_args[*]} ${extra_cmake_args[*]}"
    log_info "开始编译..."
    # 执行 colcon 构建
    export MAKEFLAGS=-j$parallel_workers
    export CC="ccache gcc"
    export CXX="ccache g++"
    if ! colcon build --symlink-install \
                    --parallel-workers "$parallel_workers" \
                    --cmake-args "${cmake_args[@]}" "${extra_cmake_args[@]}"; then
        log_error "项目构建失败。"
        exit 1
    fi

    log_success "项目构建成功！"
}

# ------------------ 主流程 ------------------
main() {
    log_info "开始构建 ROS2 项目..."

    # 默认参数
    local clean_build_flag=false
    cmake_args=(
        "-DCMAKE_BUILD_TYPE=RelWithDebInfo"           # 编译类型为 Debug
        "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON" # 为 VSCode 生成编译命令文件
        # "-DENABLE_TESTS=ON"                 # 启用测试选项（根据需要取消注释）
    )
    extra_cmake_args=()

    # 解析命令行参数
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --clean)
                clean_build_flag=true
                shift
                ;;
            --Debug)
                cmake_args[0]="-DCMAKE_BUILD_TYPE=Debug"
                shift
                ;;
            --cmake-arg)
                if [ -n "$2" ]; then
                    extra_cmake_args+=("$2")
                    shift 2
                else
                    log_error "--cmake-arg 需要一个参数。"
                    exit 1
                fi
                ;;
            *)
                log_error "未知参数: $1"
                exit 1
                ;;
        esac
    done

    cd "$route/../"  # 切换到项目根目录

    check_colcon

    if [ "$clean_build_flag" = true ]; then
        clean_build_dirs
    else
        log_info "跳过清理构建目录，启用增量构建。"
    fi

    colcon_build
}

# 执行主流程
main "$@"
