# 说明
本文档记录如何在不进行系统重启的条件下，给服务器的nvcc版本升级
## 服务器信息记录
```bash
Wed Dec  3 17:15:53 2025       
+---------------------------------------------------------------------------------------+
| NVIDIA-SMI 535.54.03              Driver Version: 535.54.03    CUDA Version: 12.2     |
|-----------------------------------------+----------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |         Memory-Usage | GPU-Util  Compute M. |
|                                         |                      |               MIG M. |
|=========================================+======================+======================|
|   0  NVIDIA A40                     Off | 00000000:D5:00.0 Off |                    0 |
|  0%   25C    P8              21W / 300W |      4MiB / 46068MiB |      0%      Default |
|                                         |                      |                  N/A |
+-----------------------------------------+----------------------+----------------------+
                                                                                    
+---------------------------------------------------------------------------------------+
| Processes:                                                                            |
|  GPU   GI   CI        PID   Type   Process name                            GPU Memory |
|        ID   ID                                                             Usage      |
|=======================================================================================|
|  No running processes found                                                           |
+---------------------------------------------------------------------------------------+
```
```bash
nvcc: NVIDIA (R) Cuda compiler driver
Copyright (c) 2005-2021 NVIDIA Corporation
Built on Mon_Oct_11_21:27:02_PDT_2021
Cuda compilation tools, release 11.4, V11.4.152
Build cuda_11.4.r11.4/compiler.30521435_0
```
## 分析
**关键分析：**
1.  **Driver (驱动):** 你的 `nvidia-smi` 显示驱动版本为 **535.54.03**。这个驱动版本非常新，它已经支持最高 **CUDA 12.2** 的环境。
2.  **Toolkit (工具包):** 你当前的 `nvcc` (CUDA Toolkit) 是 **11.4**。
3.  **结论:** 显卡驱动（Driver）已经满足要求（兼容 CUDA 11.6+ 甚至 12.x），**不需要动驱动**。只需要安装新的 CUDA Toolkit，并修改环境变量即可。由于不修改内核层的驱动，因此**不需要重启**。

以下是推荐的方案（以安装广泛使用的 **CUDA 11.8** 为例，它符合你“11.6及以上”的要求，且对 PyTorch 等框架兼容性极佳）：

-----

### 第一步：下载 CUDA Toolkit Runfile

为了避免系统包管理器（apt/yum）自动更新驱动导致冲突，**必须使用 `.run` 文件（Runfile）方式安装**。

在服务器上执行以下命令下载 CUDA 11.8 安装包（约 3-4GB）：

```bash
wget https://developer.download.nvidia.com/compute/cuda/11.8.0/local_installers/cuda_11.8.0_520.61.05_linux.run
```

### 第二步：运行安装程序（关键步骤）

运行下载的安装包：

```bash
sh cuda_11.8.0_520.61.05_linux.run
```
**报错：出现报错**
```bash
(base) root@ai:~# sh cuda_11.8.0_520.61.05_linux.run
./cuda-installer: error while loading shared libraries: libxml2.so.2: cannot open shared object file: No such file or directory
```
这个错误 libxml2.so.2: cannot open shared object file 是因为NVIDIA 的安装程序本身（Installer UI）依赖于 Linux 系统的一个基础库 libxml2 来显示图形化/文本菜单界面。服务器系统里恰好缺少这个库。

**解决方案**
1.  CUDA 安装包依赖 `libxml2` 库。
2.  试图安装 `libxml2` 时，发现系统的 `apt` 包管理器被 NVIDIA 的旧源配置搞坏了（Keyring 冲突），导致任何 `apt` 命令都无法执行。

**不用担心，我们只需要先把捣乱的源配置文件移走，修好 apt，装好库，就能继续安装 CUDA 了。**
#### 第一步：修复 apt（移除冲突的源）

既然我们现在是用 `.run` 文件手动安装 CUDA，暂时不需要系统里的 NVIDIA `apt` 源（而且它现在坏了）。我们把它暂时移走，让 `apt` 恢复正常。

1.  **查看有哪些 CUDA 相关的源文件：**

    ```bash
    ls /etc/apt/sources.list.d/cuda*
    ```

    *(通常会看到类似 `cuda.list` 或者 `cuda-ubuntu2004.list` 的文件)*

2.  **暴力移除（备份）导致冲突的配置文件：**
    将所有 cuda 开头的 list 文件移动到 `/tmp` 目录（或者加个 .bak 后缀），让 apt 看不到它们。

    ```bash
    # 将所有的 cuda 源文件移走备份
    mv /etc/apt/sources.list.d/cuda*.list /tmp/
    ```

3.  **更新 apt 缓存：**
    现在没有坏掉的源了，更新应该能成功：

    ```bash
    apt-get update
    ```

    *(如果有报错请忽略，只要最后一行显示 `Reading package lists... Done` 即可)*

-----

#### 第二步：安装缺失的库 libxml2

现在 `apt` 应该恢复正常了，可以安装那个缺失的库了：

```bash
apt-get install libxml2
```

-----

#### 第三步：再次尝试安装 CUDA

库装好后，再次执行之前的静默安装命令：

```bash
sh cuda_11.8.0_520.61.05_linux.run --silent --toolkit
```

  * **--silent**: 不显示界面（避免再次因为缺图形库报错）。
  * **--toolkit**: 只安装工具包（避免动驱动）。

如果命令执行后没有报错直接结束，说明安装成功。

-----

### 第四步：后续配置

安装完成后，修改环境变量指向新版本，在~/.bashrc的最后换行新加如下内容：

1.  **编辑配置：** `vim ~/.bashrc`
2.  **添加/修改：**
    ```bash
    export PATH=/usr/local/cuda-11.8/bin:$PATH
    export LD_LIBRARY_PATH=/usr/local/cuda-11.8/lib64:$LD_LIBRARY_PATH
    ```
3.  **生效并验证：**
    ```bash
    source ~/.bashrc
    nvcc -V
    ```

