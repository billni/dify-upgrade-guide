#!/bin/bash

################################################################################
# Dify Docker Compose 升级脚本：v1.7.2 → v1.15.0
# 
# 使用方法：
#   bash upgrade-docker-compose.sh
# 
# 该脚本会自动：
#   1. 备份当前配置和数据
#   2. 获取新版本代码
#   3. 更新环境变量
#   4. 启动新版本服务
#   5. 运行数据库迁移
#   6. 验证升级成功
################################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠️ ]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# 检查先决条件
check_prerequisites() {
    log_info "检查先决条件..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装"
        exit 1
    fi
    log_success "Docker 已安装"
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose 未安装"
        exit 1
    fi
    log_success "Docker Compose 已安装"
    
    if ! command -v git &> /dev/null; then
        log_error "Git 未安装"
        exit 1
    fi
    log_success "Git 已安装"
}

# 验证 Dify 目录
verify_dify_directory() {
    if [ ! -f "docker-compose.yaml" ]; then
        log_error "当前目录不是 Dify 项目目录（未找到 docker-compose.yaml）"
        exit 1
    fi
    log_success "Dify 项目目录验证通过"
}

# 创建备份
create_backup() {
    log_info "创建备份..."
    
    BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    log_info "备份配置文件..."
    cp docker-compose.yaml "$BACKUP_DIR/docker-compose.yaml.bak"
    cp .env "$BACKUP_DIR/.env.bak" 2>/dev/null || log_warning ".env 文件不存在"
    
    log_success "配置备份完成: $BACKUP_DIR"
}

# 备份数据卷
backup_volumes() {
    log_info "备份 Docker 卷..."
    
    VOLUMES_BACKUP="$BACKUP_DIR/volumes-$(date +%s).tgz"
    
    log_info "停止 PostgreSQL 和 Redis..."
    docker compose stop dify-postgres dify-redis || true
    sleep 5
    
    log_info "压缩数据卷..."
    tar -czf "$VOLUMES_BACKUP" volumes/ 2>/dev/null || {
        log_warning "可能不存在 volumes 目录"
    }
    
    log_info "重启服务..."
    docker compose start dify-postgres dify-redis || true
    
    log_success "数据卷备份完成: $VOLUMES_BACKUP"
}

# 停止服务
stop_services() {
    log_info "停止服务..."
    docker compose down --remove-orphans
    sleep 5
    log_success "服务已停止"
}

# 获取新版本
fetch_new_version() {
    log_info "获取新版本代码..."
    
    git fetch --all --tags
    git checkout 1.15.0
    
    log_success "已切换到版本 1.15.0"
}

# 更新环境变量
update_env_variables() {
    log_info "检查和更新环境变量..."
    
    if [ ! -f .env ]; then
        log_warning ".env 文件不存在，跳过更新"
        return
    fi
    
    # 检查并添加新的 Celery 队列配置
    if ! grep -q "CELERY_QUEUES" .env; then
        log_info "添加 CELERY_QUEUES 配置..."
        echo 'CELERY_QUEUES=default,workflow_based_app_execution,dataset_summary' >> .env
    fi
    
    # 检查并添加 Redis 连接限制
    if ! grep -q "REDIS_MAX_CONNECTIONS" .env; then
        log_info "添加 REDIS_MAX_CONNECTIONS 配置..."
        echo "REDIS_MAX_CONNECTIONS=100" >> .env
    fi
    
    # 检查协作模式配置
    if ! grep -q "ENABLE_COLLABORATION_MODE" .env; then
        log_info "添加 ENABLE_COLLABORATION_MODE 配置..."
        echo "ENABLE_COLLABORATION_MODE=true" >> .env
    fi
    
    log_success "环境变量已更新"
}

# 启动服务
start_services() {
    log_info "拉取新镜像..."
    docker compose pull
    
    log_info "启动服务..."
    docker compose up -d
    
    log_success "服务已启动"
}

# 等待服务就绪
wait_for_services() {
    log_info "等待服务就绪..."
    
    max_attempts=60
    attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if docker exec dify-api curl -f http://localhost:5001/health > /dev/null 2>&1; then
            log_success "API 服务已就绪"
            return 0
        fi
        
        attempt=$((attempt + 1))
        if [ $((attempt % 10)) -eq 0 ]; then
            log_info "等待中... ($attempt/$max_attempts)"
        fi
        sleep 1
    done
    
    log_error "服务启动超时"
    return 1
}

# 运行数据库迁移
run_migrations() {
    log_info "运行数据库迁移..."
    
    docker compose exec -T api flask db upgrade
    
    log_success "数据库迁移完成"
}

# 运行初始化脚本
run_initialization() {
    log_info "运行初始化脚本..."
    
    docker compose exec -T api flask backfill-plugin-auto-upgrade || {
        log_warning "插件初始化脚本可能已完成或不需要"
    }
    
    log_success "初始化脚本完成"
}

# 验证升级
verify_upgrade() {
    log_info "验证升级..."
    
    log_info "检查服务状态..."
    docker compose ps
    
    log_info "检查 API 健康状态..."
    if curl -f http://localhost:5001/health > /dev/null 2>&1; then
        log_success "API 健康状态检查通过"
    else
        log_error "API 健康状态检查失败"
        return 1
    fi
    
    log_info "检查日志中的错误..."
    if docker compose logs --tail=100 api 2>&1 | grep -i "error\|exception" | head -5; then
        log_warning "日志中发现潜在错误，请检查"
    else
        log_success "日志中没有发现严重错误"
    fi
}

# 主函数
main() {
    echo -e "${BLUE}"
    echo "========================================"
    echo "   Dify Docker Compose 升级脚本"
    echo "   从 v1.7.2 升级到 v1.15.0"
    echo "========================================"
    echo -e "${NC}"
    echo ""
    
    # 执行升级步骤
    check_prerequisites
    echo ""
    
    verify_dify_directory
    echo ""
    
    create_backup
    backup_volumes
    echo ""
    
    stop_services
    echo ""
    
    fetch_new_version
    echo ""
    
    update_env_variables
    echo ""
    
    start_services
    echo ""
    
    wait_for_services || exit 1
    echo ""
    
    run_migrations
    echo ""
    
    run_initialization
    echo ""
    
    verify_upgrade
    echo ""
    
    # 显示完成信息
    echo -e "${GREEN}"
    echo "========================================"
    echo "   ✓ 升级完成！"
    echo "========================================"
    echo -e "${NC}"
    echo ""
    echo "建议的后续步骤："
    echo "  1. 访问 http://localhost:3000 验证应用"
    echo "  2. 检查日志：docker compose logs -f api"
    echo "  3. 验证功能正常"
    echo "  4. 如遇问题，使用备份文件进行回滚"
    echo ""
    echo "备份位置：$BACKUP_DIR"
    echo "遇到问题时可以使用备份进行回滚"
    echo ""
}

# 错误处理
trap 'log_error "升级脚本被中断"; exit 1' INT TERM

# 运行主函数
main "$@"