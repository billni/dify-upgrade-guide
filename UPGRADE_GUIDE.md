# Dify 升级指南：从 v1.7.2 到 v1.15.0

> 📅 **文档生成时间**：2026-07-02  
> 🎯 **升级跨度**：1.7.2 → 1.15.0（8个主版本）  
> ⚠️ **重要性**：**强烈推荐**

---

## 📋 目录

1. [升级概述](#升级概述)
2. [核心功能增强](#核心功能增强)
3. [UI/UX 重大改进](#uiux-重大改进)
4. [数据和 RAG 增强](#数据和-rag-增强)
5. [安全性改进](#安全性改进)
6. [部署和运维](#部署和运维)
7. [性能优化](#性能优化)
8. [升级前注意事项](#升级前注意事项)
9. [升级步骤](#升级步骤)
10. [升级检查清单](#升级检查清单)

---

## 升级概述

### 为什么要升级？

从 v1.7.2 升级到 v1.15.0 包含了**大量功能增强、安全优化和性能改进**：

| 指标 | 评分 | 说明 |
|------|------|------|
| **升级必要性** | ⭐⭐⭐⭐⭐ | 包含关键安全修复和功能增强 |
| **功能增益** | ⭐⭐⭐⭐⭐ | 新增协作编辑、HITL、工作流增强等 |
| **安全性提升** | ⭐⭐⭐⭐⭐ | 多个关键漏洞修复和安全加固 |
| **升级复杂度** | ⭐⭐☆☆☆ | 相对简单，主要是数据库迁移 |
| **预期停机时间** | 15-30 分钟 | 取决于数据库大小 |

---

## 核心功能增强

### 🤝 协作功能（v1.14.0）

#### 工作流协作编辑
- **多人实时编辑** - 团队成员可以同时编辑同一个工作流
- **实时图表更新** - 修改立即在所有参与者的屏幕上显示
- **在线状态显示** - 查看谁在线、谁在编辑哪个部分
- **共享可见性** - 更清晰的权限和访问管理

### 🎯 HITL（Human-in-the-Loop）

- Service API 支持
- 支持更丰富的人工输入表单
- 暂停流程等待人工确认

### 🔄 工作流改进

- 支持长时间运行模型（图像/视频生成）
- CoT（Chain of Thought）思考过程可视化
- 改进的知识检索和RAG功能

---

## UI/UX 重大改进

### 📱 设计系统升级

- **Dify UI组件库** - 统一的设计系统
- **Base UI集成** - 现代的基础组件
- **无障碍功能** - 更好的可访问性

### 🎨 新增功能

- "Go to Anything"快速导航增强
- 改进的提示词编辑器
- 更多的对话配置选项

---

## 数据和 RAG 增强

### 📚 知识库改进

- **Hologres 支持** - 向量检索 + 全文搜索
- **Excel图片提取** - 自动提取嵌入的图片
- **更好的文档索引管理**
- **Weaviate兼容性修复**

### 📥 数据下载功能

- 批量ZIP下载所选文档
- 原始文件的签名URL下载

---

## 安全性改进

### 🔐 关键安全修复

| 版本 | 修复内容 |
|------|--------|
| v1.14.1 | 自主机SECRET_KEY强化、路径遍历修复 |
| v1.14.0 | IDOR漏洞修复、变更邮件流程令牌绑定 |
| v1.13.x | SQL注入防护、SMTP头注入防护 |

### 🛡️ 凭证管理

- 插件卸载时清理过期凭证
- 改进的OAuth刷新处理
- 租户级隔离增强

---

## 部署和运维

### ⚙️ 环境变量配置变更

#### 新增环境变量

```bash
ENABLE_COLLABORATION_MODE=true
REDIS_MAX_CONNECTIONS=100
DEVICE_FLOW_APPROVE_RATE_LIMIT_PER_HOUR=10
OPENAPI_API_KEY=your_api_key
CELERY_QUEUES=default,workflow_based_app_execution,dataset_summary
```

#### 移除/弃用的环境变量

| 旧变量 | 新变量 |
|--------|--------|
| PUBSUB_REDIS_URL | EVENT_BUS_REDIS_URL |
| PUBSUB_TYPE | EVENT_BUS_TYPE |
| SSRF_REVERSE_PROXY_PORT | ❌ 已删除 |

---

## 性能优化

### ⚡ 性能提升

| 指标 | 提升 |
|------|------|
| 图形初始化 | ↓ 70% |
| Chatflow启动延迟 | ↓ 81% |
| 工作流终止速度 | 更快 |
| 数据库查询 | ↓ 80% |

### 📊 可观测性

- Langfuse v3+ 支持（TTFT指标）
- Phoenix追踪改进
- LangSmith trace_id对齐
- 设备流程速率限制指标

---

## 升级前注意事项

### ⚠️ 关键准备工作

#### 1️⃣ 数据备份（**必须**）

```bash
# 备份 Docker 卷
docker stop dify-postgres dify-redis
tar -cvzf dify-volumes-$(date +%Y%m%d_%H%M%S).tgz volumes/
docker start dify-postgres dify-redis

# 备份数据库
docker exec dify-postgres pg_dump \
  -U postgres dify_prod \
  > dify-$(date +%Y%m%d_%H%M%S).sql.gz
```

#### 2️⃣ 环境变量检查

```bash
# 检查必需变量
grep -E "DATABASE_URL|REDIS_URL|SECRET_KEY" .env

# 添加新的 Celery 队列配置
echo 'CELERY_QUEUES=default,workflow_based_app_execution,dataset_summary' >> .env
```

#### 3️⃣ 存储空间检查

```bash
df -h  # 确保可用空间 >= 数据库大小 + 100GB
```

---

## 升级步骤

### 方式一：Docker Compose 部署

```bash
#!/bin/bash
set -e

echo "=== Dify 升级：1.7.2 → 1.15.0 ==="

cd /path/to/dify

# 1. 备份
mkdir -p backups
cp docker-compose.yaml backups/docker-compose.yaml.bak
docker compose down
tar -czf backups/volumes-$(date +%s).tgz volumes/

# 2. 获取新版本
git fetch --tags
git checkout 1.15.0

# 3. 更新环境变量
if ! grep -q "CELERY_QUEUES" .env; then
    echo 'CELERY_QUEUES=default,workflow_based_app_execution,dataset_summary' >> .env
fi

# 4. 启动服务
docker compose pull
docker compose up -d

# 5. 等待服务启动
sleep 30

# 6. 运行数据库迁移
docker compose exec api flask db upgrade

# 7. 运行初始化脚本
docker compose exec api flask backfill-plugin-auto-upgrade

# 8. 验证
docker compose ps
curl http://localhost:5001/health

echo "升级完成！"
```

### 方式二：源代码部署

```bash
cd api

# 1. 检查版本
git describe --tags

# 2. 更新依赖
uv sync

# 3. 运行迁移
uv run flask db upgrade

# 4. 重启服务
systemctl restart dify-api
systemctl restart dify-worker
```

---

## 升级检查清单

### ✅ 升级前

- [ ] 完成数据备份
- [ ] 确认PostgreSQL和Redis版本
- [ ] 检查磁盘空间
- [ ] 环境变量备份
- [ ] 通知用户进行维护

### ✅ 升级中

- [ ] 切换到1.15.0代码
- [ ] 更新.env文件
- [ ] 启动新版本容器
- [ ] 运行数据库迁移
- [ ] 检查错误日志

### ✅ 升级后

- [ ] 验证Web界面可访问
- [ ] 验证API服务正常
- [ ] 测试基本功能
- [ ] 检查日志
- [ ] 性能基准测试

---

## 问题诊断

### 常见问题

| 问题 | 解决方案 |
|------|--------|
| 数据库迁移失败 | 检查数据库连接，查看完整错误日志 |
| 服务无法启动 | 检查环境变量配置、日志查看具体错误 |
| 高内存使用 | 调整 Worker 并发配置 |
| 工作流执行慢 | 检查 Celery 队列配置 |

### 快速回滚

```bash
cd /path/to/dify

docker compose down
git checkout 1.7.2
docker compose up -d

# 恢复备份（如果需要）
# tar -xzf backups/volumes-*.tgz
```

---

## 总结建议

| 维度 | 评分 |
|------|------|
| 升级必要性 | ⭐⭐⭐⭐⭐ |
| 功能增益 | ⭐⭐⭐⭐⭐ |
| 安全性提升 | ⭐⭐⭐⭐⭐ |
| 升级复杂度 | ⭐⭐☆☆☆ |
| 风险等级 | ⭐⭐☆☆☆ |

**🎯 强烈推荐升级到 v1.15.0**

**参考资源**
- [Dify 官方文档](https://docs.dify.ai)
- [GitHub 发布页面](https://github.com/langgenius/dify/releases)

---

**文档版本**: 1.0  
**最后更新**: 2026-07-02  
**适用版本**: v1.7.2 → v1.15.0