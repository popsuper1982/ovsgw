#!/bin/bash  
  
# 假设你的私钥文件是 ~/.ssh/id_rsa，并且已经添加到了目标服务器的authorized_keys中  
PRIVATE_KEY_FILE=~/.ssh/id_rsa  
USER="root"  # 替换为你的用户名  
COMMAND="/root/runscript.sh"  # 替换为你要执行的命令  
  
# 检查参数数量  
if [ "$#" -lt 1 ]; then  
    echo "使用方法：$0 IP1 [IP2 ...]"  
    exit 1  
fi  
  
# 遍历所有的命令行参数，这些应该是IP地址  
for IP in "$@"; do  
    # 使用SSH登录并执行命令  
    # 注意：这里使用了-o StrictHostKeyChecking=no来避免首次连接时的host key确认提示  
    # 在生产环境中，你应该考虑其他方法来处理host key的验证  
    ssh -i "$PRIVATE_KEY_FILE" -o StrictHostKeyChecking=no "$USER@$IP" "$COMMAND"  
  
    # 检查SSH命令的退出状态，并据此决定是否继续执行  
    if [ $? -ne 0 ]; then  
        echo "连接到 $IP 失败或命令执行出错"  
    fi  
done  

chmod +x ssh_command.sh  # 添加执行权限  
./ssh_command.sh 192.168.1.1 192.168.1.2 10.0.0.1

#!/bin/bash  
  
# 获取所有虚拟机的名称  
vms=($(virsh list --name | tail -n +2))  
  
# 循环遍历每个虚拟机  
for vm in "${vms[@]}"; do  
    # 使用virsh domid获取虚拟机的内部ID  
    domid=$(virsh domid "$vm" 2>/dev/null)  
      
    # 检查virsh domid是否成功执行（即没有错误输出）  
    if [ $? -eq 0 ]; then  
        # 输出虚拟机的名称和内部ID  
        echo "虚拟机名称: $vm, 内部ID: $domid"  
        virsh qemu-agent-command $domid --cmd '{"execute":"guest-exec" }'
    else  
        # 如果virsh domid失败（比如虚拟机不存在或未运行），则输出错误信息  
        echo "无法获取虚拟机 $vm 的内部ID"  
    fi  
done  

# mkdir /root/.ssh
virsh qemu-agent-command ${DOMAIN} '{"execute":"guest-exec","arguments":{"path":"mkdir","arg":["-p","/root/.ssh"],"capture-output":true}}'

# 假设上一步返回{"return":{"pid":911}}，接下来查看结果（通常可忽略）
virsh qemu-agent-command ${DOMAIN} '{"execute":"guest-exec-status","arguments":{"pid":911}}' 

# chmod 700 /root/.ssh，此行其实可不执行，因为上面创建目录后就是700，但为了防止权限不正确导致无法使用，这里还是再刷一次700比较稳妥
virsh qemu-agent-command ${DOMAIN} '{"execute":"guest-exec","arguments":{"path":"chmod","arg":["700","/root/.ssh"],"capture-output":true}}' 

# 假设上一步返回{"return":{"pid":912}}，接下来查看结果（通常可忽略）
virsh qemu-agent-command ${DOMAIN} '{"execute":"guest-exec-status","arguments":{"pid":912}}'

<channel type='unix'>
  <source mode='bind' path='/var/lib/libvirt/qemu/instance-000000a1.sock'/>
  <target type='virtio' name='org.qemu.guest_agent.0'/>
  <address type='virtio-serial' controller='0' bus='0' port='1'/>
</channel>
  
# 保存脚本，例如为 get_vm_ids.sh  
# 然后运行脚本：chmod +x get_vm_ids.sh && ./get_vm_ids.sh

<domain type='qemu' id='200'>
  <name>instance-200</name>
  <memory unit='KiB'>262144</memory>
  <currentMemory unit='KiB'>262144</currentMemory>
  <vcpu placement='static'>1</vcpu>
  <cputune>
    <shares>1024</shares>
  </cputune>
  <resource>
    <partition>/machine</partition>
  </resource>
  <sysinfo type='smbios'>
    <system>
      <entry name='manufacturer'>OpenStack Foundation</entry>
      <entry name='product'>OpenStack Nova</entry>
      <entry name='version'>23.2.3</entry>
      <entry name='serial'>59bca235-9d4e-43d9-a7b8-0e97bdc4d553</entry>
      <entry name='uuid'>59bca235-9d4e-43d9-a7b8-0e97bdc4d553</entry>
      <entry name='family'>Virtual Machine</entry>
    </system>
  </sysinfo>
  <os>
    <type arch='x86_64' machine='pc-i440fx-4.2'>hvm</type>
    <boot dev='hd'/>
    <smbios mode='sysinfo'/>
  </os>
  <features>
    <acpi/>
  </features>
  <cpu mode='custom' match='exact' check='full'>
    <model fallback='forbid'>qemu64</model>
    <topology sockets='1' cores='1' threads='1'/>
    <feature policy='require' name='hypervisor'/>
    <feature policy='require' name='lahf_lm'/>
  </cpu>
  <clock offset='utc'/>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>destroy</on_crash>
  <devices>
    <emulator>/usr/bin/qemu-system-x86_64</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2' cache='none'/>
      <source file='/root/centos7_1.qcow2' index='1'/>
      <target dev='vda' bus='virtio'/>
      <alias name='virtio-disk0'/>
    </disk>
    <controller type='pci' index='0' model='pci-root'>
    </controller>
    <interface type='ethernet'>
      <mac address='fa:16:3e:19:cb:95'/>
      <target dev='tap05fe3570-dd'/>
      <model type='virtio'/>
      <driver name='qemu'/>
      <mtu size='1450'/>
      <alias name='net0'/>
    </interface>
    <interface type='bridge'>
      <mac address='fa:16:3e:c1:d4:05'/>
      <source bridge='test'/>
      <target dev='tap1'/>
      <model type='virtio'/>
      <alias name='net0'/>
    </interface>
    <serial type='pty'>
      <source path='/dev/pts/1'/>
      <log file='/root/console1.log' append='off'/>
      <target type='isa-serial' port='0'>
        <model name='isa-serial'/>
      </target>
      <alias name='serial0'/>
    </serial>
    <console type='pty' tty='/dev/pts/1'>
      <source path='/dev/pts/1'/>
      <log file='/root/console1.log' append='off'/>
      <target type='serial' port='0'/>
      <alias name='serial0'/>
    </console>
    <channel type='unix'>
      <source mode='bind' path='/var/lib/libvirt/qemu/instance-200.sock'/>
      <target type='virtio' name='org.qemu.guest_agent.0'/>
      <address type='virtio-serial' controller='0' bus='0' port='1'/>
    </channel>
    <input type='mouse' bus='ps2'>
      <alias name='input0'/>
    </input>
    <input type='keyboard' bus='ps2'>
      <alias name='input1'/>
    </input>
    <graphics type='vnc' port='5900' autoport='yes' listen='192.168.10.8'>
      <listen type='address' address='192.168.10.8'/>
    </graphics>
    <memballoon model='virtio'>
      <stats period='10'/>
      <alias name='balloon0'/>
    </memballoon>
    <rng model='virtio'>
      <backend model='random'>/dev/urandom</backend>
      <alias name='rng0'/>
    </rng>
  </devices>
</domain>

root@devstack-controller:~# virsh qemu-agent-command 1 '{"execute":"guest-exec","arguments":{"path":"ntpdate","arg":["-s","ntp.aliyun.com"],"capture-output":true}}'
{"return":{"pid":4231}}

root@devstack-controller:~# virsh qemu-agent-command 1 '{"execute":"guest-exec-status","arguments":{"pid":4231}}'
{"return":{"exitcode":0,"exited":true}}

json_str='{"return":{"pid":4231}}'  
pid=$(echo "$json_str" | jq -r '.return.pid')  
echo "$pid"  # 输出: 4231

[root@localhost ~]# cat hisory.out
    1  ls
    2  ip addr
    3  ifconfig eth0 192.168.57.100/24
    4  ip addr
    5  ping 192.168.57.1
    6  ip route
    7  ip route add default dev eth0
    8  ip route
    9  ip addr
   10  ifconfig eth0 192.168.57.100/24
   11  ip addr
   12  ifconfig eth0 192.168.57.100/24
   13  ip addr
   14  cd /etc/sysconfig/
   15  ls
   16  cd network-scripts/
   17  ls
   18  cat ifcfg-ens3
   19  ip addr
   20  cp ifcfg-ens3 ifcfg-eth0
   21  ip addr
   22  ifconfig eth0 192.168.57.100/24
   23  ip addr
   24  ping 8.8.8.8
   25  route add
   26  route add default gw 192.168.57.1
   27  ip addr
   28  ip route
   29  ping 8.8.8.8
   30  ping 114.114.114.114
   31  ping 192.168.57.1
   32  ip route
   33  yum update
   34  ping 114.114.114.114
   35  ping www.baidu.com\
   36  ping www.baidu.com
   37  ip addr
   38  ping 180.101.50.188
   39  cat /etc/resolv.conf
   40  vim /etc/resolv.conf
   41  ping www.baidu.com
   42  ping 180.101.50.188
   43  yum search ntpdate
   44  yum install ntpdate -y
   45  yum install qemu-guest-agent -y
   46  shutdown -h now
   47  ps aux | grep qga
   48  ps aux | grep qemu
   49  cat /etc/sysconfig/qemu-ga
   50  vim /etc/sysconfig/qemu-ga
   51  systemctl restart qemu-guest-agent.service
   52  ps aux | grep qemu
   53  ls
   54  pwd
   55  ls
   56  ps aux | grep qemu
   57  ls
   58  ps aux | grep qemu
   59  touch a
   60  ls
   61  setenforce 0
   62  ntpdate -s 127.0.0.1
   63  echo ?
   64  echo $?
   65  ntpdate -s 127.0.0.1
   66  echo $?
   67  ntpdate
   68  echo $?
   69  ip addr
   70  ifconfig eth0 192.168.57.100
   71  route add default gw 192.168.57.1
   72  ip route
   73  ping www.baidu.com
   74  vim /etc/resolv.conf
   75  ping 192.168.57.1
   76  ip addr
   77  ifconfig eth0 0
   78  ifconfig eth1 192.168.57.100
   79  ip route
   80  ping 192.168.57.1
   81  route add default gw 192.168.57.1
   82  ping www.baidu.com
   83  ntpdate -s time.aliyun.com
   84  ntpdate -s ntp.aliyun.com
   85  echo $?
   86  history
   87  history > hisory.out

////////////这个结果是对的

root@devstack-controller:~# cat runscript.sh
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

root@devstack-controller:~# cat runallhosts.sh
#!/bin/bash

# 假设你的私钥文件是 ~/.ssh/id_rsa，并且已经添加到了目标服务器的authorized_keys中
PRIVATE_KEY_FILE=~/.ssh/id_rsa
USER="root"  # 替换为你的用户名
COMMAND="/root/runntpscript.sh"  # 替换为你要执行的命令

# 检查参数数量
if [ "$#" -lt 1 ]; then
    echo "使用方法：$0 IP1 [IP2 ...]"
    exit 1
fi

# 遍历所有的命令行参数，这些应该是IP地址
for IP in "$@"; do
    # 使用SSH登录并执行命令
    # 注意：这里使用了-o StrictHostKeyChecking=no来避免首次连接时的host key确认提示
    # 在生产环境中，你应该考虑其他方法来处理host key的验证
    #ssh -i "$PRIVATE_KEY_FILE" -o StrictHostKeyChecking=no "$USER@$IP" "$COMMAND"
    ssh "$USER@$IP" "$COMMAND"
    # 检查SSH命令的退出状态，并据此决定是否继续执行
    if [ $? -ne 0 ]; then
        echo "连接到 $IP 失败或命令执行出错"
    fi
done

1. 虚拟机里面要安装qemu-guest-agent，在4.0的里面是默认安装的，可以查看

root@devstack-compute:~# ps aux | grep qemu-ga
root         818  0.0  0.0   6448  3568 ?        Ss   May10   0:00 /usr/sbin/qemu-ga

或者

[root@testovs ~]# ps aux | grep qemu
root         770  0.0  0.0  82056  4740 ?        Ssl  Mar12   0:00 /usr/bin/qemu-ga --method=virtio-serial --path=/dev/virtio-ports/org.qemu.guest_agent.0 --blacklist= -F/etc/qemu-ga/fsfreeze-hook

都可以

如果没有请安装
yum install qemu-guest-agent -y

2. 虚拟机里面要安装ntpdate

如果没有请安装
yum install ntpdate -y

安装后如果虚拟机能连公网，请尝试ntpdate -u ntp.aliyun.com

虚拟机里面也可以尝试ntpdate -u 169.254.169.254连接租户ntp

宿主机上直接连接管理ntp的地址

3. 虚拟机里面要关闭selinux，否则会阻止命令执行

root@devstack-compute:~# getenforce
Disabled

就没有问题

可以执行

setenforce 0

关闭

4. 在每台宿主机上需要安装jq，用于解析命令返回的json

5. 在每台宿主机的/root/下面放脚本runntpscript.sh，chmod +x runntpscript.sh让其可执行

尝试在宿主机上执行，应该得到如下的结果

root@devstack-controller:~# ./runntpscript.sh
虚拟机名称: instance-200, 内部ID: 1
{"return":{"pid":4837}}
4837
{"return":{"exitcode":0,"exited":true}}

虚拟机名称: instance-300, 内部ID: 2
{"return":{"pid":3838}}
3838
{"return":{"exitcode":0,"exited":true}}

5. 在管理区上执行脚本runallhosts.sh，参数是IP地址，以空格分隔

root@devstack-controller:~# ./runallhosts.sh 192.168.10.8 192.168.10.9
虚拟机名称: instance-200, 内部ID: 1
{"return":{"pid":4723}}
4723
{"return":{"exitcode":0,"exited":true}}

虚拟机名称: instance-300, 内部ID: 2
{"return":{"pid":3585}}
3585
{"return":{"exitcode":0,"exited":true}}

虚拟机名称: instance-00000003, 内部ID: 2
{"return":{"pid":4723}}
4723
{"return":{"exitcode":0,"exited":true}}

虚拟机名称: instance-00000002, 内部ID: 3
{"return":{"pid":3585}}
3585
{"return":{"exitcode":0,"exited":true}}