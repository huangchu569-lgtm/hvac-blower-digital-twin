# HVAC Blower Digital Twin — 项目日志

本文件记录项目从原版复现到后续改造的全过程。作为工创赛工程报告素材。

---

## 一、项目概述

将 GitHub 开源项目 HVAC Blower Digital Twin Predictive Maintenance 改造成工创赛参赛作品。

原项目是 IIoT 数字孪生预测性维护系统，包含：

- 感知层：ESP32-S3 + ACS712 电流传感器（原版为 Python 模拟器代替）
- 传输层：MQTT（Eclipse Mosquitto）
- 边缘层：Node-RED
- 应用层：InfluxDB + Grafana

当前阶段：原版完整复现成功，作为改造基线。

---

## 二、环境搭建

### 操作系统与工具

- Windows 10.0.26200
- Git（已配置 GitHub 代理）
- Python 3.11.9（系统自带，用于虚拟环境）
- Docker Desktop 4.92.0
- WSL2 2.7.14.0

### Python 环境

- 问题：系统 Python 3.13 无法安装 scikit-learn 1.5.0
- 解决：使用系统已有 Python 3.11.9 创建虚拟环境 .venv
- 依赖：scikit-learn 1.5.0、numpy 2.4.6、scipy 1.17.1、pandas 3.0.6、paho-mqtt 2.1.0、influxdb-client 1.50.0、joblib 1.6.0
- 额外安装：pytest（requirements.txt 未声明）

### Docker 配置

配置镜像加速器解决国内拉取超时，registry-mirrors 列表：

- https://docker.xuanyuan.me
- https://docker.1ms.run
- https://hub.rat.dev
- https://docker.m.daocloud.io

添加并发下载参数：

- max-concurrent-downloads: 10
- max-download-attempts: 10

---

## 三、原版复现过程中的修复

### 修复 1：python/Dockerfile

问题：构建时报错 ModuleNotFoundError: No module named 'micromlgen'

原因：Dockerfile 中执行 RUN python train_model.py，而 train_model.py 依赖未声明的 micromlgen；且 fan_anomaly_model.pkl 已在仓库中，无需重新训练。

修复：删除 Dockerfile 中以下两行：

    RUN python generate_data.py
    RUN python train_model.py

### 修复 2：Node-RED dashboard 模块

问题：flows.json 加载后提示缺少节点类型 ui_base、ui_tab、ui_gauge、ui_chart 等

原因：node-red/package.json 已声明 node-red-dashboard 依赖，但容器构建时未自动安装

修复命令：

    docker compose exec node-red npm install node-red-dashboard --registry=https://registry.npmmirror.com
    docker compose restart node-red

### 修复 3：Grafana dashboard 首次加载

问题：provisioner 未自动加载 dashboard

解决：浏览器中手动 Import grafana/dashboards/fan-dashboard.json

---

## 四、当前系统状态（原版基线）

### 5 个容器全部正常运行

| 容器 | 镜像 | 端口 | 状态 |
|---|---|---|---|
| mqtt | eclipse-mosquitto:2.0 | 1883 | Up |
| influxdb | influxdb:2.7 | 8086 | Up |
| python-edge | 本地构建 | — | Up |
| node-red | nodered/node-red:latest | 1880 | Up |
| grafana | grafana/grafana:9.5.3 | 3000 | Up |

### 访问地址

- Node-RED 编辑器：http://localhost:1880
- Node-RED UI：http://localhost:1880/ui
- Grafana：http://localhost:3000 （admin / admin）
- InfluxDB：http://localhost:8086 （admin / adminpass）
- MQTT broker：localhost:1883

### 数据流验证

MQTT 主题：

- sensors/group20/hvac-blower/data
- alerts/group20/hvac-blower/status

InfluxDB 存储：

- measurement = fan_metrics
- fields = current、moving_avg
- tags = device=fan01
- 采样间隔 = 2 秒

Grafana 面板：

- fan-dashboard → Fan Current 面板
- 查询语句：
  from(bucket:"hvac") |> range(start: -1h) |> filter(fn: (r) => r._measurement == "fan_metrics" and r._field == "current") |> aggregateWindow(every: 10s, fn: mean, createEmpty: false) |> yield()
- 可观察到约每 2 分钟一次的异常电流尖峰（模拟故障注入）

Node-RED：

- Flow "MQTT Sensor Data" 订阅 MQTT，解析 JSON，输出到 UI 仪表盘
- Flow "MQTT Alert Test" 订阅告警主题

---

## 五、一键启动脚本

已添加 scripts/ 目录：

- start.ps1：检查 Docker → 启动 5 个容器 → 打印访问地址
- stop.ps1：停止所有容器，保留数据卷
- status.ps1：查看容器状态 + 最近日志

使用方式：

    .\scripts\start.ps1
    .\scripts\stop.ps1
    .\scripts\status.ps1

---

## 六、已知问题（不影响核心功能）

### 1. 模型版本警告

InconsistentVersionWarning: Trying to unpickle estimator OneClassSVM from version 1.8.0 when using version 1.5.0

模型文件用 scikit-learn 1.8.0 训练，运行环境 1.5.0。功能正常，等重训模型时自然解决。

### 2. InfluxDB 启动延迟

python-edge 启动时 InfluxDB 未就绪，短暂报连接失败，之后自动恢复。

### 3. PowerShell 引号转义

查询 InfluxDB 时引号被吃掉，需进容器执行：

    docker compose exec influxdb sh
    进入后：
    influx query 'from(bucket:"hvac") |> range(start: -10m) |> limit(n: 5)' --org group20 --token super-secret-token
    exit

---

## 七、Git 版本管理

远程仓库：https://github.com/huangchu569-lgtm/hvac-blower-digital-twin

主要提交历史：

- Initial import from ZIP
- chore: add docs and environment snapshot
- docs: fix notes.md encoding
- fix: remove model training from Dockerfile; docs: log docker bring-up
- docs: 原版项目完整跑通，5 容器正常运行
- feat: add one-click start/stop/status scripts

Tag：v0.1-original — 原版完整复现基线

---

## 八、下一步计划

### 改造阶段

1. B1：加控制能力（软件层）
   - 新增 MQTT 主题 commands/group20/hvac-blower/control 接收指令
   - 新增 status/group20/hvac-blower/mode 反馈当前模式
   - 三种模式：RUN / SLOW / STOP
   - 自动保护：连续 5 次 ANOMALY 自动降级到 SLOW

2. B2：丰富可视化
   - Grafana 增加 mode 状态时间线、异常计数、健康度面板

3. B3：Node-RED 流程改造
   - 订阅告警 → 写入 InfluxDB → 触发动作

4. B4：RUL 估算
   - 趋势分析 + 剩余可用时间预测

### 硬件阶段

5. 接入 ESP32-S3 + ACS712 + 继电器 + 12V 风扇
6. 多传感器融合：MPU6050 振动、DS18B20 温度
7. 真实故障数据采集与模型重训

---

## 九、比赛材料积累

- docs/requirements-actual.txt：实际依赖快照
- docs/screenshots/：（待补充）界面截图
- docs/logs/：（待补充）关键运行日志