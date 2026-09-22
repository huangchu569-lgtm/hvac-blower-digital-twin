# 项目日志

## 2026-09-22 环境搭建与模型加载测试

### 环境
- Python 3.11.9（虚拟环境 .venv）
- pip 24.0
- scikit-learn 1.5.0
- numpy 2.4.6, scipy 1.17.1, pandas 3.0.6
- paho-mqtt 2.1.0, joblib 1.6.0, influxdb-client 1.50.0

### 命令
- python test_model.py
- python -m pytest -q tests（待补）

### 结果
- Model test passed
- normal prediction: 1
- anomaly prediction: -1

### 警告
- 模型实际由 scikit-learn 1.8.0 训练保存，与 README 声称的 1.5.0 不符（InconsistentVersionWarning）。
- 预测时输入带 feature names，训练时不带（UserWarning）。
- 处置：暂不升级版本，等真实数据重训时一并解决。

### 备注
- 系统 Python 3.13 无法安装 scikit-learn 1.5.0，改用系统已有 Python 3.11.9 创建虚拟环境。
- PATH 顺序较乱，已备份到桌面 PATH-user-backup.txt 与 PATH-machine-backup.txt。