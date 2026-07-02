# Dify 升级指南：v1.7.2 → v1.15.0

🚀 **完整的 Dify 本地部署升级指南**

## 📚 文档内容

本仓库包含从 Dify v1.7.2 升级到 v1.15.0 的完整指南，包括：

- ✅ **升级概述** - 为什么要升级及其必要性评估
- ✅ **核心功能增强** - 新增协作编辑、HITL、工作流改进
- ✅ **安全性改进** - 关键漏洞修复清单
- ✅ **性能优化** - 性能对比数据和改进说明
- ✅ **完整升级步骤** - Docker Compose 和源代码部署方式
- ✅ **检查清单** - 升级前、中、后的详细验证步骤
- ✅ **问题诊断** - 常见问题和快速回滚方案

## 🎯 快速开始

### 1. 查看完整升级指南

```bash
cat UPGRADE_GUIDE.md
```

### 2. Docker Compose 升级（推荐）

```bash
bash scripts/upgrade-docker-compose.sh
```

### 3. 源代码升级

```bash
bash scripts/upgrade-source-code.sh
```

## 📊 升级评分

| 指标 | 评分 | 说明 |
|------|------|------|
| **升级必要性** | ⭐⭐⭐⭐⭐ | 包含关键安全修复 |
| **功能增益** | ⭐⭐⭐⭐⭐ | 新增重要功能 |
| **安全性提升** | ⭐⭐⭐⭐⭐ | 多个漏洞修复 |
| **升级复杂度** | ⭐⭐☆☆☆ | 相对简单 |
| **停机时间** | 15-30 分钟 | 取决于数据库大小 |

## 🔑 关键改进

### 🤝 协作功能
- 多人实时编辑工作流
- 在线状态显示
- 共享可见性

### 🎯 HITL（Human-in-the-Loop）
- Service API 支持
- 丰富的人工输入表单
- 流程暂停功能

### 🔐 安全加固
- IDOR 漏洞修复
- SQL 注入防护
- SMTP 头注入防护
- 凭证隔离增强

### ⚡ 性能提升
- 图形初始化 ↓ 70%
- Chatflow 启动延迟 ↓ 81%
- 数据库查询 ↓ 80%

## 📁 目录结构

```
.
├── UPGRADE_GUIDE.md          # 完整升级指南
├── README.md                 # 本文件
├── CHANGELOG.md              # 变更日志
├── scripts/
│   ├── upgrade-docker-compose.sh  # Docker Compose 升级脚本
│   ├── upgrade-source-code.sh     # 源代码升级脚本
│   └── backup.sh                  # 备份脚本
├── examples/
│   ├── .env.example          # 环境变量示例
│   └── docker-compose-1.15.0.yaml
└── LICENSE                   # MIT License
```

## ⚠️ 升级前检查清单

### 必须完成
- [ ] 备份数据库和 Docker 卷
- [ ] 确认 PostgreSQL >= 12
- [ ] 确认 Redis >= 6.0
- [ ] 检查磁盘可用空间
- [ ] 通知用户进行维护

### 建议完成
- [ ] 导出当前配置
- [ ] 测试备份恢复流程
- [ ] 准备回滚计划
- [ ] 安排技术人员在场

## 🚀 升级步骤（快速版）

```bash
# 1. 进入 Dify 目录
cd /path/to/dify

# 2. 备份
mkdir -p backups
cp docker-compose.yaml backups/docker-compose.yaml.bak
docker compose down
tar -czf backups/volumes-$(date +%s).tgz volumes/

# 3. 更新代码
git fetch --tags
git checkout 1.15.0

# 4. 启动新版本
docker compose pull
docker compose up -d

# 5. 运行迁移
docker compose exec api flask db upgrade

# 6. 验证
curl http://localhost:5001/health
```

## 🔍 版本对比

| 功能 | v1.7.2 | v1.15.0 |
|------|--------|----------|
| 基础工作流 | ✅ | ✅ |
| 协作编辑 | ❌ | ✅ **新增** |
| HITL | ❌ | ✅ **新增** |
| 混合搜索 | ❌ | ✅ **新增** |
| Excel 图片提取 | ❌ | ✅ **新增** |
| 安全修复 | 基础 | ✅ **增强** |
| 性能 | 基准 | ⚡ **↑ 81%** |
| 可观测性 | 基础 | ✅ **增强** |

## ❓ 常见问题

### Q: 升级需要多久？
A: 通常 15-30 分钟，取决于数据库大小

### Q: 升级期间会有服务中断吗？
A: 是的，升级期间服务会短时间不可用

### Q: 可以回滚吗？
A: 是的，有完整的备份和回滚方案

### Q: 需要修改应用代码吗？
A: 不需要，升级是透明的

## 🔧 诊断命令

```bash
# 查看 API 日志
docker compose logs -f api

# 检查数据库连接
docker exec dify-postgres psql -U postgres -c "SELECT version();"

# 检查 Redis 连接
docker exec dify-redis redis-cli ping

# 检查磁盘空间
df -h
```

## 📞 获取帮助

- 📖 [Dify 官方文档](https://docs.dify.ai)
- 🐙 [GitHub 仓库](https://github.com/langgenius/dify)
- 💬 [社区讨论](https://github.com/langgenius/dify/discussions)
- 📋 [发布日志](https://github.com/langgenius/dify/releases)

## 📝 文件说明

| 文件 | 说明 |
|------|------|
| UPGRADE_GUIDE.md | 详细的升级指南，包含所有细节 |
| README.md | 快速开始和概览 |
| CHANGELOG.md | 版本变更日志 |
| scripts/ | 自动化升级脚本 |
| examples/ | 配置示例文件 |

## 💡 升级建议

1. **阅读完整指南** - 在升级前阅读 UPGRADE_GUIDE.md
2. **制定计划** - 选择合适的升级窗口
3. **备份数据** - 完成数据备份和配置备份
4. **测试环境** - 如果可能，在测试环境先升级
5. **监控升级** - 升级过程中监控日志
6. **验证功能** - 升级后验证所有关键功能

## 📄 许可证

MIT License - 详见 [LICENSE](./LICENSE) 文件

---

**最后更新**: 2026-07-02  
**文档版本**: 1.0  
**适用版本**: v1.7.2 → v1.15.0