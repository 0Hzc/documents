TOOL_INFO="bison (GNU Bison) 3.8.2"
if echo "${TOOL_INFO}" | grep -q "GNU"; then
    echo "发现 GNU 工具，继续检查..."
    VERSION=$(echo "${TOOL_INFO}" | awk '{print $NF}')
    echo "检测到 Bison 版本为：${VERSION}"
else 
    echo "非 GNU 工具，停止。"
    exit 0
fi