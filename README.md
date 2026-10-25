# 瓜菜宝 · 卖菜记账 App

一个专为老人设计的卖菜记账应用，界面简洁，操作方便。

## 功能特点

- 📅 自动记录日期与星期
- 🥬 菜品不再固定：内置豆角、菜心、白菜、瓜软、白瓜，还能随时**添加自定义菜品**（选个表情做图标）
- ✏️ **长按菜品卡片**可改名、删除（历史记录保留），删掉的内置菜品可一键恢复
- 🔢 自定义大号数字键盘，全程无需系统键盘
- 📊 实时显示今日合计和各菜品金额
- 📈 菜品详情页：查看本月、近一周、上月或自定义时间段的销售总额
- 📜 历史记录：按天查看各菜品明细与累计总收入
- 📤 分享 / 导入 JSON 数据，换机不丢账

## 界面说明

### 主界面
- 顶部显示当前日期和今日合计，右上角工具栏：分享 / 导入 / 总收入
- 菜品区显示全部菜品卡片：点击选中，点「详情」看明细，**长按管理（改名 / 删除）**
- 点「＋ 添加」新增自定义菜品：输入名称 + 选表情图标
- 底部大号数字键盘输入金额，点「确认」保存

### 菜品详情页
- 点菜品卡片上的「详情」进入
- 支持本月 / 近一周 / 上月 / 自定义日期范围
- 显示每笔记录（含时间），可单笔删除

### 历史记录页
- 按日期倒序显示每天的菜品明细和小计
- 顶部显示累计总收入与各菜品总收入
- 可分享文字统计摘要

## 环境要求

- Flutter SDK 3.0 或更高版本
- Android Studio 或 VS Code
- Android 模拟器或真机

## 安装步骤

```bash
flutter pub get   # 安装依赖
flutter run       # 运行应用
```

## 打包 APK

```bash
flutter build apk --release
```

打包后的 APK 位于：`build/app/outputs/flutter-apk/app-release.apk`

推送到 main 分支也会由 GitHub Actions 自动构建 APK（Artifacts 里下载）。

## 数据存储

- 交易记录与自定义菜品均保存在本机（SharedPreferences），卸载应用会清除数据
- 「分享」导出的 JSON 可在新设备「导入」中粘贴恢复

## 项目结构

```
lib/
├── main.dart                       # 应用入口
├── models/
│   ├── record.dart                 # 交易记录 + 每日汇总
│   └── dish.dart                   # 菜品定义（内置/自定义）
├── screens/
│   ├── home_screen.dart            # 主界面（记账 + 菜品管理）
│   ├── vegetable_detail.dart       # 菜品详情页
│   ├── history_screen.dart         # 历史记录页
│   └── import_screen.dart          # 数据导入页
├── services/
│   ├── storage_service.dart        # 交易记录存储
│   ├── dish_service.dart           # 菜品管理（增删改名）
│   ├── export_service.dart         # 分享/导出
│   └── sound_service.dart          # 按键音与震动反馈
├── utils/
│   └── format.dart                 # 金额格式化
└── widgets/
    └── numpad.dart                 # 自定义数字键盘
```
