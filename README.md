# 卖菜记账 App

一个专为老人设计的卖菜记账应用，界面简洁，操作方便。

## 功能特点

- 📅 自动记录日期
- 🥬 三种菜品分类：豆角、菜心、白菜
- 🔢 自定义大号数字键盘，全程无需系统键盘
- 📊 实时显示今日合计和各菜品金额
- 📈 菜品详情页：查看本月或自定义时间段的销售总额
- 📜 历史记录：查看所有历史记录和累计总收入

## 界面说明

### 主界面
- 顶部显示当前日期和今日合计
- 中间显示三个菜品卡片，点击选择要输入金额的菜品
- 底部是大号数字键盘，点击数字输入金额，点击"确认"保存
- 点击"查看历史记录"进入历史页面

### 菜品详情页
- 长按主界面的菜品卡片进入详情页
- 默认显示本月该菜品的销售总额
- 可以切换到"自定义"选择日期范围查看
- 显示每日明细记录

### 历史记录页
- 显示所有历史记录，按日期倒序排列
- 每天显示三个菜品的金额和小计
- 顶部显示累计总收入

## 环境要求

- Flutter SDK 3.0 或更高版本
- Android Studio 或 VS Code
- Android 模拟器或真机

## 安装步骤

1. 安装 Flutter SDK
   ```bash
   # 下载 Flutter SDK
   git clone https://github.com/flutter/flutter.git -b stable
   
   # 添加到 PATH
   export PATH="$PATH:`pwd`/flutter/bin"
   
   # 验证安装
   flutter doctor
   ```

2. 克隆或下载本项目
   ```bash
   cd li_cal
   ```

3. 安装依赖
   ```bash
   flutter pub get
   ```

4. 运行应用
   ```bash
   flutter run
   ```

## 打包 APK

```bash
flutter build apk --release
```

打包后的 APK 位于：`build/app/outputs/flutter-apk/app-release.apk`

## 数据存储

应用使用 SharedPreferences 本地存储数据，数据保存在设备上，卸载应用会清除数据。

## 项目结构

```
li_cal/
├── lib/
│   ├── main.dart                    # 应用入口
│   ├── models/
│   │   └── record.dart              # 数据模型
│   ├── screens/
│   │   ├── home_screen.dart         # 主界面
│   │   ├── vegetable_detail.dart    # 菜品详情页
│   │   └── history_screen.dart      # 历史记录页
│   ├── services/
│   │   └── storage_service.dart     # 本地存储服务
│   └── widgets/
│       ├── numpad.dart              # 自定义数字键盘
│       └── vegetable_card.dart      # 菜品卡片组件
└── android/                         # Android 配置文件
```

## 使用说明

1. 打开应用，看到今天的日期
2. 点击要记录的菜品（如"豆角"）
3. 在数字键盘上输入金额（如卖了120元就输入120）
4. 点击"确认"保存
5. 继续记录其他菜品
6. 长按菜品卡片可以查看该菜品的历史明细
7. 点击"查看历史记录"查看所有记录
