#!/bin/bash

# 获取所有虚拟机的名称
vms=($(virsh list --name))

# 循环遍历每个虚拟机
for vm in "${vms[@]}"; do
    # 使用virsh domid获取虚拟机的内部ID
    domid=$(virsh domid "$vm" 2>/dev/null)

    # 检查virsh domid是否成功执行（即没有错误输出）
    if [ $? -eq 0 ]; then
        # 输出虚拟机的名称和内部ID
        echo "虚拟机名称: $vm, 内部ID: $domid"
        outjson=$(virsh qemu-agent-command $domid '{"execute":"guest-exec","arguments":{"path":"ntpdate","arg":["-s","ntp.aliyun.com"],"capture-output":true}}')
        echo $outjson
        pid=$(echo "$outjson" | jq -r '.return.pid')
        echo $pid
        sleep 8
        virsh qemu-agent-command $domid "{\"execute\":\"guest-exec-status\",\"arguments\":{\"pid\":$pid}}"
    else
        # 如果virsh domid失败（比如虚拟机不存在或未运行），则输出错误信息
        echo "无法获取虚拟机 $vm 的内部ID"
    fi
done
