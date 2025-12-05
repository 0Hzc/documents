#!/bin/bash
LOG_FILE="build.log"
if [ -f "${LOG_FILE}" ];then
    rm -rf ${LOG_FILE}
fi
echo "=== 开始构建 LFS 环境 ===">${LOG_FILE}
echo "正在下载源码包...">>${LOG_FILE}
ls /bu_cun_zai_de_wen_jian >> ${LOG_FILE} 2>&1
echo "脚本运行结束，以下是日志内容："
