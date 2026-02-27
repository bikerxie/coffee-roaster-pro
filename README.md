# Coffee Roaster Pro - 咖啡烘焙机控制应用

一款专业的咖啡烘焙机控制软件，支持实时温度监控、烘焙曲线记录、AI 预测等功能。

## 🚀 快速开始

### 环境要求
- Flutter SDK 3.0+
- Dart 3.0+
- Android Studio / Xcode
- 一台支持蓝牙/WiFi 的咖啡烘焙机

### 安装依赖

```bash
# 进入项目目录
cd coffee_roaster_app

# 安装依赖
flutter pub get

# 运行应用
flutter run
```

### 构建发布版本

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

---

## 📱 功能特性

### 核心功能
- ✅ **实时温度监控** - 豆温、风温、RoR（升温速率）
- ✅ **烘焙曲线可视化** - 双Y轴图表，支持缩放、平移
- ✅ **事件标记** - 一爆(FC)、二爆(SC)、下豆(Drop)
- ✅ **设备控制** - 火力、滚筒转速、风量调节
- ✅ **历史记录** - 保存、查询、导出烘焙数据

### 高级功能
- 🔄 **多设备连接** - 支持蓝牙 LE、Wi-Fi、USB
- 📊 **AI 智能预测** - 烘焙曲线预测（开发中）
- ☁️ **云端同步** - 多设备数据同步（开发中）
- 👥 **社交分享** - 分享烘焙曲线到社区（开发中）

---

## 📁 项目结构

```
coffee_roaster_app/
├── lib/
│   ├── main.dart                    # 应用入口
│   ├── models/                      # 数据模型
│   │   ├── roast_session.dart       # 烘焙会话
│   │   └── device.dart              # 设备模型
│   ├── screens/                     # 界面
│   │   ├── roast_screen.dart        # 主烘焙界面
│   │   ├── history_screen.dart      # 历史记录
│   │   └── device_connection_screen.dart  # 设备连接（开发中）
│   ├── widgets/                     # 自定义组件
│   │   ├── roast_chart.dart         # 烘焙曲线图表
│   │   ├── control_panel.dart       # 控制面板
│   │   └── event_buttons.dart       # 事件按钮
│   ├── services/                    # 服务层
│   │   ├── bluetooth_service.dart   # 蓝牙服务（开发中）
│   │   └── database_service.dart    # 数据库服务（开发中）
│   └── providers/                   # 状态管理
│       └── roast_provider.dart      # 烘焙状态（开发中）
├── assets/                          # 资源文件
│   ├── images/
│   └── fonts/
├── pubspec.yaml                     # 项目配置
└── README.md                        # 本文件
```

---

## 🔌 支持的设备

### 已测试设备
- Smola R300
- Aillio Bullet R1
- Gene Café CBR-101

### 连接方式
- **蓝牙 LE** - 推荐用于移动设备
- **Wi-Fi TCP/UDP** - 推荐用于固定场所
- **USB Serial** - Android OTG 支持

---

## 🎨 设计规范

### 颜色主题
- 背景色：`#1A1A1A` (深色)
- 卡片色：`#2D2D2D`
- 主色调：`#FF9800` (橙色)
- 强调色：`#4CAF50` (绿色)

### 界面原则
- 深色主题 - 减少烘焙时的视觉疲劳
- 大按钮 - 方便戴手套操作
- 实时数据突出显示
- 离线优先设计

---

## 🗓️ 开发路线图

### Phase 1: MVP (已完成 ✅)
- [x] 基础 UI 界面
- [x] 实时温度显示
- [x] 烘焙曲线图表
- [x] 事件标记

### Phase 2: 核心功能 (进行中 🟡)
- [ ] 设备连接（蓝牙/WiFi）
- [ ] 数据存储（SQLite）
- [ ] 历史记录管理

### Phase 3: 智能化 (计划中 📋)
- [ ] AI 曲线预测
- [ ] 烘焙建议
- [ ] 语音标记

### Phase 4: 社交功能 (计划中 📋)
- [ ] 云端同步
- [ ] 社区分享
- [ ] 曲线导出视频

---

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

### 开发流程
1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

---

## 📄 开源协议

MIT License - 详见 [LICENSE](LICENSE) 文件

---

## 🙏 致谢

- [Flutter](https://flutter.dev/) - 跨平台 UI 框架
- [fl_chart](https://github.com/imaNNeoFighT/fl_chart) - 图表库
- [flutter_blue_plus](https://github.com/boskokg/flutter_blue_plus) - 蓝牙插件

---

## 📞 联系我们

如有问题或建议，欢迎联系：
- Email: your-email@example.com
- GitHub Issues: [提交 Issue](https://github.com/yourusername/coffee_roaster/issues)

---

**Happy Roasting! ☕️**
