## 不同服务器推送代码进行ssh密钥设置
SSH 密钥的工作原理
每个设备/环境都需要自己的 SSH 密钥对（公钥 + 私钥）。这就像每台电脑都有自己的"钥匙"。

#### 1. 生成密钥
ssh-keygen -t ed25519 -C "your_email@example.com"

#### 2. 启动 ssh-agent
eval "$(ssh-agent -s)"

#### 3. 添加私钥
ssh-add ~/.ssh/id_ed25519

#### 4. 查看并复制公钥
cat ~/.ssh/id_ed25519.pub

#### 5. 去 GitHub 添加这个新公钥（起个容易识别的名字，比如 "MacBook-Pro" 或 "Work-PC"）

#### 6. 克隆仓库（使用 SSH 地址）
git clone git@github.com:0Hzc/Os.git

## 多账号 Git 使用场景
要使用账号 B 推送代码到账号 A 的仓库

#### 第一步：赋予账号 B 推送权限 (至关重要)
仓库是公开的，默认情况下也只有拥有者（账号 A）有权修改/推送代码。其他人只能读取。
```
登录 账号 A 的 GitHub。

进入仓库 A_rep 的页面。

点击 Settings (设置) -> Collaborators (协作者)。

点击 Add people，搜索 账号 B 的用户名并添加。

账号 B 会收到一封邮件（或在 GitHub 通知中），必须点击 Accept invitation (接受邀请)。
```
#### 第二步：在本地仓库配置账号 B 的身份
为了让提交记录显示是由账号 B 提交的（而不是账号 A），你需要在这个仓库中单独设置用户信息。

在终端中进入该仓库目录，运行：
```bash
## 设置账号 B 的用户名
git config user.name "Tutehzc"

## 设置账号 B 的注册邮箱
git config user.email "0422241253@tute.edu.cn"
```
不加 --global 参数，这样设置仅对当前仓库有效，不会影响其他仓库的默认设置。

#### 第三步：修改远程地址以强制使用账号 B 认证
这是最关键的一步。因为之前用账号 A 登录过，Git 可能缓存了账号 A 的凭据。为了强制 Git 使用账号 B 进行推送，修改远程仓库的 URL，在里面显式加上账号 B 的用户名。

```bash
## 格式：git remote set-url origin https://<账号B的用户名>@github.com/<账号A>/<仓库名>.git

git remote set-url origin https://Tutehzc@github.com/0Hzc/documents.git
```
**此时，Git 会识别到 URL 中的用户名是账号 B，它会询问你 账号 B 的密码。**

#### 第四步：推送代码
尝试推送
```bash
git push
```
若出现报错：
```
remote: Invalid username or token. Password authentication is not supported for Git operations.
fatal: Authentication failed for 'https://github.com/0Hzc/documents.git/'
```
报错信息 Password authentication is not supported ：你刚才输入的（或者 Git 尝试使用的）是你的 GitHub 登录密码，但 GitHub 现在要求必须使用 Personal Access Token (个人访问令牌，简称 PAT) 来代替密码。
###### 解决办法
需要登录账号 B (Tutehzc) 的 GitHub 网页，生成一个 Token，然后在 git push 询问密码时，粘贴这个 Token

 第一步：生成 Token (在 GitHub 网页上操作)
```
登录 GitHub 账号 Tutehzc。

点击右上角头像 -> Settings (设置)。

在左侧菜单最底部，点击 Developer settings。

点击 Personal access tokens -> Tokens (classic)。

点击 Generate new token -> Generate new token (classic)。

Note (备注): 随便填，比如 "LinuxStudy"。

Expiration (过期时间): 可以选 "No expiration" (永不过期) 或者 30天，看你喜好。

Select scopes (选择权限): 必须勾选 repo (这代表你可以读写仓库)。

点击底部的 Generate token 绿色按钮。

复制生成的 Token (以 ghp_ 开头的一长串字符)。注意：这个 Token 只显示一次，关掉页面就看不到了，请先复制好！
```
 第二步：使用 Token 推送
回到终端，再次运行推送命令：
```bash
git push
```

**系统会提示：**
Password for 'https://Tutehzc@github.com':

在这里粘贴刚才复制的 Token (注意：在 Linux 终端里粘贴密码时，屏幕上通常不会显示任何字符，这是正常的，粘贴后直接按回车即可)。
