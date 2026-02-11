# 计划与路线图

本目录包含 LangMap 项目的开发计划和设计文档。

## 文档列表

- [2026-01-27-ios-app-design.md](./2026-01-27-ios-app-design.md) - iOS 应用设计文档

## 文档说明

### 2026-01-27-ios-app-design.md
LangMap iOS 应用的设计文档，包括：
- **概述**：连接现有 Cloudflare Workers 后端的 SwiftUI iOS 应用
- **架构**：Model-View-ViewModel (MVVM) 架构
  - Model Layer：数据模型
  - ViewModel Layer：使用 ObservableObject 和 @StateObject 的状态管理
  - View Layer：SwiftUI 视图（遵循 Apple HIG）
  - Service Layer：使用 URLSession 的 API 客户端
- **核心屏幕**：
  1. Splash/Login Screen
  2. Home Screen
  3. Search Screen
  4. Detail Screen
  5. Collections Screen
  6. Profile Screen
  7. Tab Bar Navigation
- **数据流与 API 集成**：使用 URLSession 的通信模式
- **国际化和本地化**：镜像 web app 的 i18n 结构
- **错误处理和离线支持**：AlertManager + Core Data 缓存
- **技术栈和依赖**：
  - SwiftUI (iOS 15+)
  - Core Data
  - URLSession
  - Keychain Services
  - User Defaults
  - CryptoKit
- **项目结构**
- **测试策略**：单元测试、集成测试、快照测试
- **部署要求**：iOS 15.0+、App Store Connect、代码签名

## 开发路线图

### 已完成 ✅
- 系统基础架构
- 用户认证系统
- 表达式管理
- 集合功能
- UI 翻译基础功能
- API 接口（统计、热力图）
- 前端基础页面

### 进行中 🚧
- UI 翻译系统完善
- 邮箱验证功能
- 权限系统完善

### 计划中 📋
- iOS 应用开发
- 导出系统（异步）
- 高级搜索功能
- 热力图优化
- 版本历史回滚
- 内容审核增强

### 未来考虑 🔮
- 移动端 API 优化
- 实时协作功能
- 翻译质量评分
- 社区功能增强
- 高级数据分析

## 版本历史

- **v0.1.0** (2024 Q4)
  - MVP 版本
  - 基础 CRUD 功能
  - 用户认证
  - 简单搜索

- **v0.2.0** (2025 Q1)
  - 集合功能
  - UI 翻译界面
  - 版本历史

- **v0.3.0** (2025 Q2) - 计划
  - 邮箱验证
  - 导出功能
  - iOS 应用

- **v1.0.0** (2025 Q4) - 计划
  - 完整功能集
  - 多平台支持
  - 高级功能

## 相关文档

- [系统设计](../design/)
- [功能模块设计](../design/features/)
- [API 文档](../api/)
- [需求规范](../specs/)
