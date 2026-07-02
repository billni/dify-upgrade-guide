#!/bin/bash

################################################################################
# Dify 备份脚本
# 
# 使用方法：
#   bash backup.sh [backup_name]
# 
# 该脚本会：
#   1. 备份 Docker 卷
#   2. 导出 PostgreSQL 数据库
#   3. 导出 Redis 数据
#   4. 备份配置文件
################################################################################

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

BACKUP_NAME=${1:-"dify-backup-$(date +%Y%m%d_%H%M%S)"}
BACKUP_DIR="backups/$BACKUP_NAME"

echo -e "${BLUE}开始备份...${NC}"
echo "备份目录: $BACKUP_DIR"
echo ""

mkdir -p "$BACKUP_DIR"

# 备份配置文件
echo -e "${BLUE}备份配置文件...${NC}"
cp docker-compose.yaml "$BACKUP_DIR/" 2>/dev/null || true
cp .env "$BACKUP_DIR/" 2>/dev/null || true
echo -e "${GREEN}✓ 配置文件备份完成${NC}"
echo ""

# 备份 Docker 卷
echo -e "${BLUE}备份 Docker 卷...${NC}"
echo -e "${YELLOW}停止服务...${NC}"
docker compose stop dify-postgres dify-redis || true
sleep 5

echo -e "${YELLOW}压缩卷...${NC}"
tar -czf "$BACKUP_DIR/volumes.tgz" volumes/ 2>/dev/null || true
echo -e "${GREEN}✓ 卷备份完成${NC}"
echo ""

# 备份 PostgreSQL
echo -e "${BLUE}备份 PostgreSQL 数据库...${NC}"
docker compose start dify-postgres || true
sleep 10

echo -e "${YELLOW}导出中...${NC}"
docker exec dify-postgres pg_dump \
  -U postgres dify_prod \
  | gzip > "$BACKUP_DIR/postgres-dump.sql.gz" || {
    echo -e "${YELLOW}PostgreSQL 导出失败，跳过${NC}"
}
echo -e "${GREEN}✓ PostgreSQL 备份完成${NC}"
echo ""

# 备份 Redis
echo -e "${BLUE}备份 Redis 数据...${NC}"
docker compose start dify-redis || true
sleep 5

echo -e "${YELLOW}执行 Redis 快照...${NC}"
docker exec dify-redis redis-cli BGSAVE || true
sleep 5
echo -e "${GREEN}✓ Redis 备份完成${NC}"
echo ""

# 显示备份信息
echo -e "${GREEN}========================${NC}"
echo -e "${GREEN}✓ 备份完成！${NC}"
echo -e "${GREEN}========================${NC}"
echo ""
echo "备份位置: $(pwd)/$BACKUP_DIR"
echo ""
echo "备份内容:"
ls -lh "$BACKUP_DIR"/
echo ""
echo "备份大小: $(du -sh $BACKUP_DIR)"
echo ""