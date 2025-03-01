#!/usr/bin/env bash
#
# 进程终止与端口释放脚本
#
# 该脚本用于终止所有与 Gazebo、MoveIt2 和 RViz2 相关的进程，并释放相关端口。
# 支持处理多个同名进程实例，并提供详细的日志输出以便调试。
#
# 使用说明：
#  - ./scripts/simulation_reset.sh
#
# 注意：
#  - 确保以具有足够权限的用户运行脚本（无需使用 sudo，除非终止的进程属于其他用户）
#  - 脚本会尝试优雅地终止进程，必要时强制终止

# 设置脚本配置：启用错误中止，未定义变量时退出，管道中任意命令失败时退出
set -euo pipefail

# 定义颜色变量用于日志输出
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
NC="\033[0m" # 无颜色

# 默认镜像配置
PROCESSES=("gzserver" "gzclient" "gazebo" "move_group" "rviz2")
PORTS=(11345 11311) # Gazebo 和 MoveIt2/RViz2 可能占用的端口

# 函数：打印信息
log_info() {
    echo -e "${GREEN}ℹ️  INFO:${NC} $1"
}

# 函数：打印警告
log_warn() {
    echo -e "${YELLOW}⚠️  WARNING:${NC} $1"
}

# 函数：打印错误
log_error() {
    echo -e "${RED}❌ ERROR:${NC} $1"
}

# 函数：终止指定进程
terminate_processes() {
    log_info "开始终止所有与 Gazebo、MoveIt2 和 RViz2 相关的进程..."

    for PROCESS in "${PROCESSES[@]}"; do
        # 获取所有匹配的 PID
        PIDS=$(pgrep -x "$PROCESS" || true)
        if [ -n "$PIDS" ]; then
            log_info "终止进程 $PROCESS (PIDs: $PIDS)..."
            kill $PIDS
            sleep 1
        else
            log_info "进程 $PROCESS 未运行。"
        fi
    done
}

# 函数：强制终止残留进程
force_terminate_processes() {
    log_warn "某些进程仍在运行，正在强制终止..."

    for PROCESS in "${PROCESSES[@]}"; do
        # 获取所有匹配的 PID
        PIDS=$(pgrep -x "$PROCESS" || true)
        if [ -n "$PIDS" ]; then
            log_warn "强制终止进程 $PROCESS (PIDs: $PIDS)..."
            kill -9 $PIDS || log_error "无法强制终止进程 $PROCESS (PID: $PIDS)"
        fi
    done
}

# 函数：等待进程终止
wait_for_termination() {
    local attempts=5
    for ((i=1; i<=attempts; i++)); do
        REMAINING_PIDS=$(pgrep -x "$(IFS=\|; echo "${PROCESSES[*]}")" || true)
        if [ -z "$REMAINING_PIDS" ]; then
            log_info "所有指定的进程已成功终止。"
            return
        fi
        log_warn "等待进程终止... (尝试 $i/$attempts)"
        sleep 1
    done

    # 如果仍有进程，进行强制终止
    REMAINING_PIDS=$(pgrep -x "$(IFS=\|; echo "${PROCESSES[*]}")" || true)
    if [ -n "$REMAINING_PIDS" ]; then
        force_terminate_processes
    else
        log_info "所有指定的进程已成功终止。"
    fi
}

# 函数：检查并释放端口
release_ports() {
    log_info "检查并释放默认端口占用..."

    for PORT in "${PORTS[@]}"; do
        PID=$(lsof -t -i:$PORT || true)
        if [ -n "$PID" ]; then
            log_warn "端口 $PORT 仍被 PID $PID 占用，正在终止..."
            kill $PID || log_error "无法终止占用端口 $PORT 的进程 (PID: $PID)"
            sleep 1
            # 再次检查端口是否已释放
            if lsof -i:$PORT > /dev/null; then
                log_warn "端口 $PORT 仍被占用，强制终止..."
                kill -9 $PID || log_error "无法强制终止进程 (PID: $PID) 占用端口 $PORT"
            else
                log_info "端口 $PORT 已释放。"
            fi
        else
            log_info "端口 $PORT 已空闲。"
        fi
    done
}

# 函数：主流程
main() {
    terminate_processes          # 终止进程
    wait_for_termination         # 等待进程终止
    release_ports                # 检查并释放端口
    log_info "清理完成。"
}

# 执行主流程
main "$@"
