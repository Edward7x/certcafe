# CertCafe 🏷️ - Your SSL Certificate Café

![CertCafe Logo](https://img.shields.io/badge/CertCafe-v1.0-brown?style=for-the-badge&logo=coffeescript&logoColor=white)

> ☕ 一杯香浓的SSL证书解决方案 | Your daily brew of SSL certificates

## 目录

- [简介](#简介)
- [功能特色](#功能特色)
- [快速开始](#快速开始)
- [使用指南](#使用指南)
- [DNS提供商配置指南](#dns提供商配置指南)
- [证书文件结构](#证书文件结构)
- [常见问题解答](#常见问题解答)
- [高级用法](#高级用法)
- [证书管理](#证书管理)
- [故障排除](#故障排除)
- [自动续期](#自动续期)
- [安全建议](#安全建议)
- [许可证](#许可证)
- [贡献](#贡献)
- [致谢](#致谢)

## 简介

CertCafe 是一个优雅而强大的SSL证书管理工具，基于 acme.sh 构建，提供简单直观的菜单驱动界面，让SSL证书的申请、安装和续期变得像喝咖啡一样轻松惬意。

### 设计理念

- **简单易用**: 无需记忆复杂命令，菜单驱动操作
- **多平台支持**: 支持主流云服务商的DNS API
- **自动化**: 一键安装、自动续期、状态监控
- **可视化**: 清晰的彩色终端输出和状态报告

## 功能特色

### 招牌特饮 (核心功能)
- ✅ **一键安装部署** - 自动安装 acme.sh 并配置证书
- ✅ **多DNS提供商支持** - 支持国内外主流云服务商
- ✅ **证书类型选择** - 支持 RSA 和 ECC 证书
- ✅ **证书自动更新** - 支持单个或批量更新
- ✅ **证书信息查看** - 查看证书详情和列表
- ✅ **智能续期管理**

### 国际风味 (支持的DNS提供商)
- ☁️ Cloudflare
- 📡 DNSPod
- 🐜 阿里云 (Alibaba Cloud)
- 🐧 腾讯云 (Tencent Cloud)
- 🛡 华为云 (Huawei Cloud)
- 🐶 京东云 (JD Cloud)
- 🔧 其他自定义DNS提供商

### 证书特性
- 🔐 RSA & ECC 证书支持
- 🌐 Let's Encrypt、ZeroSSL、Buypass 多CA选择
- ⏰ 自动续期监控
- 📈 证书状态报告

## 快速开始

### 系统要求
- Linux / Unix 系统
- Bash shell
- curl 工具
- 有效的域名和DNS控制权限

### 安装使用

1. **下载脚本**
```bash
# 下载脚本
curl -O https://gitee.com/edward7x/certcafe/raw/master/certcafe.sh

# 赋予执行权限
chmod +x certcafe.sh
```

2. **运行CertCafe**
```bash
./certcafe.sh
```

3. **按照菜单指引操作**

```
======================================
        🏷️ CertCafe 主菜单
======================================
1) 一键安装部署
2) 手动更新证书
3) 查看已安装证书列表
4) 查看指定证书信息
5) 显示DNS配置帮助
6) 卸载/停止证书
7) 证书状态报告
0) 退出
```

## 使用指南

### 1. 一键安装部署

这是最常用的功能，完成以下步骤：

#### 步骤1: DNS提供商选择

支持以下DNS提供商：

| 选项 | 提供商        | 所需凭据                         |
| ---- | ------------- | -------------------------------- |
| 1    | Cloudflare    | API Key + Email                  |
| 2    | 阿里云        | AccessKey ID + Secret            |
| 3    | 腾讯云/DNSPod | ID + Key                         |
| 4    | 华为云        | AccessKey ID + Secret Access Key |
| 5    | 京东云        | AccessKey ID + Secret Access Key |
| 6    | 其他          | 手动配置                         |

#### 步骤2: 域名配置

- **主域名**: 如 `example.com`
- **附加域名**: 多个域名用空格分隔（支持通配符域名）
- 示例: `example.com *.example.com www.example.com`

#### 步骤3: 证书类型选择

- **RSA证书**: 兼容性好，推荐用于传统系统
- **ECC证书**: 更安全、体积小，推荐用于现代浏览器

#### 步骤4: 证书颁发机构

- **Let's Encrypt** (默认): 免费，90天有效期
- **ZeroSSL**: 免费，90天有效期
- **Buypass**: 免费，180天有效期

#### 步骤5: 自动安装

脚本会自动签发证书，并可选择安装到指定目录。

### 2. 手动更新证书

当需要手动更新证书时：

1. 选择主菜单选项 `2`
2. 选择更新方式，支持三种更新方式：
   - **更新所有证书**: 更新所有已安装的证书
   - **更新指定域名**: 只更新特定域名的证书
   - **强制更新**: 忽略有效期，强制重新签发

### 3. 查看证书列表

查看所有已安装的证书：

1. 选择主菜单选项 `3`
2. 查看证书列表和基本信息（域名、证书路径、过期时间、证书数量统计）

### 4. 查看证书信息

查看特定域名的详细证书信息：

1. 选择主菜单选项 `4`
2. 输入要查看的域名
3. 查看证书文件位置、有效期、颁发机构、主题备用名称(SAN)

### 5. DNS配置帮助

获取各DNS服务商的API配置指南：

1. 选择主菜单选项 `5`
2. 查看详细的API配置说明

### 6. 证书卸载管理

管理证书的卸载和停止：

1. 选择主菜单选项 `6`
2. 选择卸载选项：
   - 删除单个证书
   - 删除所有证书
   - 仅禁用自动续期

### 7. 证书状态报告

查看证书健康状态：

1. 选择主菜单选项 `7`
2. 查看所有证书的：
   - 过期时间
   - 剩余天数
   - 续期状态
   - 统计信息

## DNS提供商配置指南

### Cloudflare

1. 登录 Cloudflare 控制台
2. 进入 "My Profile" → "API Tokens"
3. 创建具有 Zone:DNS:Edit 权限的令牌
4. 或者使用 Global API Key

### 阿里云

1. 登录阿里云控制台
2. 进入「访问控制 RAM」
3. 创建子账号并授予 `AliyunDNSFullAccess` 权限
4. 创建 AccessKey

### 腾讯云/DNSPod

1. 登录 DNSPod 控制台
2. 进入「用户中心」→「API密钥」
3. 创建 API 令牌
4. 获取 ID 和 Token

### 华为云

1. 登录华为云控制台
2. 进入「统一身份认证服务 IAM」
3. 创建用户并授予 `DNS FullAccess` 权限
4. 创建访问密钥

### 京东云

1. 登录京东云控制台
2. 进入「访问控制」→「用户管理」
3. 创建子用户或使用现有用户
4. 为用户添加 `JDCloudDNSFullAccess` 权限
5. 在「AccessKey管理」中创建AccessKey
6. 将AccessKey ID和Secret Key输入到脚本中

### 通用配置要求

所有DNS提供商都需要相应的API权限：
- **域名解析管理权限**
- **DNS记录修改权限**
- **API访问权限**

## 证书文件结构

成功安装后，证书文件通常位于：

```
/etc/ssl/your-domain.com/
├── cert.pem          # 证书文件
├── key.pem           # 私钥文件
└── fullchain.pem     # 完整证书链
```

acme.sh 工作目录：
```
~/.acme.sh/
├── your-domain.com/  # 域名证书目录
├── account.conf      # 账户配置
└── acme.sh          # 主程序
```

## 常见问题解答

### Q: 脚本执行权限问题

**A:** 确保脚本有执行权限：

```bash
chmod +x certcafe.sh
```

### Q: DNS验证失败

**A:** 检查：

- ✅ DNS API凭据是否正确
- ✅ 域名解析是否生效
- ✅ 网络连接是否正常
- ✅ 云服务商权限配置

### Q: 证书安装失败

**A:** 检查：

- ✅ 目标目录是否有写入权限
- ✅ 磁盘空间是否充足
- ✅ SELinux/AppArmor 配置

### Q: 自动续期不工作

**A:** 检查：

- ✅ 检查cron服务是否运行
- ✅ 验证证书目录权限
- ✅ 查看acme.sh日志文件

### Q: curl命令不存在

**A:** 安装工具：

```bash
# Ubuntu/Debian
apt-get install curl

# CentOS/RHEL
yum install curl
```

### Q: 如何卸载

**A:** 手动卸载 acme.sh：

```bash
~/.acme.sh/acme.sh --uninstall
rm -rf ~/.acme.sh
```

## 高级用法

### 通配符证书

在输入域名时使用通配符：

```
主域名: example.com
附加域名: *.example.com
```

### 多域名证书

一次签发包含多个域名的证书：

```
主域名: example.com
附加域名: www.example.com api.example.com shop.example.com
```

### 自定义安装目录

在安装证书时指定自定义目录：

```
默认: /etc/ssl/example.com/
自定义: /usr/local/nginx/ssl/example.com/
```

## 故障排除

### 日志查看

acme.sh 日志位置：
```bash
tail -f ~/.acme.sh/acme.sh.log
```

### 查看详细日志

```bash
# 查看acme.sh详细日志
~/.acme.sh/acme.sh --issue --dns dns_cf -d example.com --debug
```

### 测试DNS解析

```bash
# 测试域名解析
dig example.com
nslookup example.com
```

### 检查API权限

确保API密钥具有足够的DNS管理权限。

## 自动续期

CertCafe 自动配置证书续期：
- 📅 自动检测证书有效期
- 🔔 提前30天开始续期
- 📧 可选邮件通知（需配置）
- 📝 续期日志记录

## 安全建议

1. **保护API密钥**: 妥善保管DNS API凭据
2. **最小权限原则**: 为API密钥分配最小必要权限
3. **定期轮换密钥**: 定期更新API密钥
4. **监控证书状态**: 定期检查证书有效期
5. **备份私钥**: 安全备份证书私钥

## 许可证

本项目基于 MIT 许可证开源。

## 贡献

欢迎提交 Issue 和 Pull Request！

## 致谢

感谢以下项目的支持：
- [acme.sh](https://github.com/acmesh-official/acme.sh) - 优秀的ACME客户端
- 所有支持的DNS服务商
- 开源社区贡献者

---

**CertCafe** - 让SSL证书管理像喝咖啡一样简单愉悦！ ☕✨

*最后更新: 2025年12月*