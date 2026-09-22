## 2026-09-22 模型加载测试

- 环境：Python 3.11.9, scikit-learn 1.5.0
- 命令：python test_model.py
- 结果：通过（normal �?1, anomaly �?-1�?
- 警告�?
  - 模型实际�?scikit-learn 1.8.0 训练，与 README 声称�?1.5.0 不符
  - 预测时输入带 feature names，训练时不带
- 处置：暂不升级版本，等真实数据重训时一并解�
