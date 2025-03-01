#!/bin/bash

# 日志函数
log_info() {
    echo "[INFO] $1"
}

log_error() {
    echo "[ERROR] $1"
}

# 函数：获取包路径
get_package_path() {
    local package_name=$1
    log_info "正在查找 $package_name 包的路径..."
    if PACKAGE_PREFIX=$(ros2 pkg prefix "$package_name" 2>/dev/null); then
        log_info "找到 $package_name 包的路径：$PACKAGE_PREFIX"
    else
        log_error "无法找到 $package_name 包。请确保包已正确安装并设置了 ROS2 环境。"
        exit 1
    fi
}

# 函数：验证 meshes 文件夹是否存在
verify_meshes_folder() {
    local package_name=$1
    local package_share_dir="${PACKAGE_PREFIX}/share/${package_name}"

    log_info "正在检查 ${package_name} 包的 meshes 文件夹..."

    # 使用 find 命令递归查找 meshes 文件夹
    SOURCE_MESHES=$(find "$package_share_dir" -type d -name "meshes" -print -quit)

    if [ -n "$SOURCE_MESHES" ]; then
        log_info "找到 ${package_name} 包的 meshes 文件夹：$SOURCE_MESHES"
    else
        log_error "未找到 ${package_name} 包的 meshes 文件夹。请检查路径是否正确。"
        exit 1
    fi
}

# 函数：复制 meshes 文件夹
copy_meshes() {
    local package_name=$1
    local source_meshes=$2

    # 提取 robots/g1_description 部分
    local relative_path=$(echo "$source_meshes" | sed -n "s|.*/${package_name}/\(.*\)/meshes|\1|p")
    if [ -z "$relative_path" ]; then
        log_error "无法从源路径中提取 robots/g1_description 部分。"
        exit 1
    fi

    # 构建目标路径
    TARGET_MESHES_DIR="${TARGET_MODEL_DIR}/${package_name}/${relative_path}/meshes"
    
    log_info "开始复制 $package_name 的 meshes 文件夹到目标目录..."
    log_info "源路径：$source_meshes"
    log_info "目标目录：$TARGET_MESHES_DIR"

    # 创建目标目录（如果不存在）
    mkdir -p "$TARGET_MESHES_DIR"
    if [ $? -ne 0 ]; then
        log_error "无法创建目标目录：$TARGET_MESHES_DIR。请检查路径和权限。"
        exit 1
    fi

    # 复制 meshes 文件夹内容
    cp -r "$source_meshes/"* "$TARGET_MESHES_DIR/"
    if [ $? -ne 0 ]; then
        log_error "复制 meshes 文件夹失败。请检查源路径和目标路径。"
        exit 1
    fi

    # 创建空的 model.config 文件
    touch "${TARGET_MODEL_DIR}/${package_name}/model.config"
    if [ $? -ne 0 ]; then
        log_error "创建 model.config 文件失败。请检查目标路径权限。"
        exit 1
    fi

    log_info "$package_name 的 meshes 文件夹已成功复制到 $TARGET_MESHES_DIR"
}

# 主函数
main() {
    local package_name="simulation"  # 替换为你的包名
    TARGET_MODEL_DIR="${HOME}/.gazebo/models"  # 目标目录

    # 检查目标路径是否存在，如果不存在则创建
    mkdir -p "$TARGET_MODEL_DIR"
    if [ $? -ne 0 ]; then
        log_error "无法创建目标目录：$TARGET_MODEL_DIR。请检查路径和权限。"
        exit 1
    fi

    # 获取包路径
    get_package_path "$package_name"

    # 验证 meshes 文件夹
    verify_meshes_folder "$package_name"

    # 复制 meshes 文件夹
    copy_meshes "$package_name" "$SOURCE_MESHES"

    log_info "🎉 示例的 g1 的 meshes 文件夹已成功安装"
}

# 执行主函数
main