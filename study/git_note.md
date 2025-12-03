SSH 密钥的工作原理
每个设备/环境都需要自己的 SSH 密钥对（公钥 + 私钥）。这就像每台电脑都有自己的"钥匙"。

# 1. 生成密钥
ssh-keygen -t ed25519 -C "your_email@example.com"

# 2. 启动 ssh-agent
eval "$(ssh-agent -s)"

# 3. 添加私钥
ssh-add ~/.ssh/id_ed25519

# 4. 查看并复制公钥
cat ~/.ssh/id_ed25519.pub

# 5. 去 GitHub 添加这个新公钥（起个容易识别的名字，比如 "MacBook-Pro" 或 "Work-PC"）

# 6. 克隆仓库（使用 SSH 地址）
git clone git@github.com:0Hzc/Os.git