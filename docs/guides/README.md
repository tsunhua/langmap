# 实施指南

本目录包含 LangMap 项目开发和部署的操作指南。

## 文档列表

- [corpus-acquisition.md](./corpus-acquisition.md) - 语料获取指南
- [email-verification.md](./email-verification.md) - 邮箱验证实施指南

## 文档说明

### corpus-acquisition.md
为 LangMap 获取高质量开源语料的指南，包括：
- 主要获取渠道与优先级说明
  - Tatoeba（句子库）
  - OPUS（并行语料集合）
  - Mozilla Common Voice（音频 + 文本）
  - Wikipedia Dumps（单语语料）
  - Universal Dependencies（结构化语料）
  - OpenSLR / MLS / LibriVox（语音语料）
  - 其他开源数据集
- 地域标注的现实限制与解决方案
- 实操优先级（入门语料清单）
- 下载与使用示例命令
- 预处理要点（质量保证的关键）
- 地域标注与映射策略
- 治理、许可与伦理流程
- 自动化与管道建议
- 低资源/方言策略

### email-verification.md
邮箱验证功能的实施指南，包括：
- 整体架构说明
- Cloudflare DNS 配置（为 Resend 添加记录）
- Resend 配置（API Key 创建、发信地址规划）
- 数据库设计（users 表扩展、email_verification_tokens 表）
- 后端实现
  - 用户注册 API
  - 邮箱验证 API
  - 重发验证邮件（可选）
- 前端实现（注册后提示、验证成功页面、登录提示）
- 安全考虑（必做与推荐增强）
- 环境变量配置
- 错误处理（异常情况列表）
- 后续扩展功能

## 开发环境设置

### 前置要求

- Node.js 18+
- Python 3.12+
- Cloudflare 账号（用于部署）
- Resend 账号（用于邮件服务）

### 常用命令

```bash
# 前端开发
cd web
npm install
npm run dev

# 后端开发
cd backend
npm install
npm run dev

# 部署到 Cloudflare Workers
npm run deploy

# 数据库迁移
cd backend
python scripts/migrate.py
```

## 实施状态

- [x] corpus-acquisition.md - 指南文档完成
- [ ] email-verification.md - 待实施

## 相关文档

- [系统设计](../design/)
- [API 文档](../api/)
