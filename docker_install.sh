import pexpect
import os


try:
    # 使用 wget 下载 vps.sh 脚本并赋予执行权限
    #os.system('wget -O vps.sh --no-check-certificate "https://raw.githubusercontent.com/xinling123/vps-sh/master/vps.sh" && chmod +x vps.sh')
    # 启动脚本
    child = pexpect.spawn('./vps.sh', encoding='utf-8')
    # 等待脚本输出 "请输入选择的数字：" 提示符，设置超时时间为 30 秒
    child.expect("请输入选择的数字：", timeout=20)
    # 发送第一个指令 (选择 0)
    child.sendline('0')
    # 等待任务执行完成，等待提示 "是否挂载硬盘[默认n]："，超时时间为 60 秒
    child.expect("挂载硬盘", timeout=5)
    # 发送第二个指令
    child.sendline('n')
    # 等待任务执行完成，等待提示 "是否增加虚拟内存[默认n]："，超时时间为 60 秒
    child.expect("增加虚拟内存", timeout=5)
    # 发送第二个指令
    child.sendline('n')
    # 等待任务执行完成，等待提示 "是否启动bbr加速[默认y]："，超时时间为 60 秒
    child.expect("启动bbr加速", timeout=5)
    # 发送第二个指令
    child.sendline('y')
    # 等待任务执行完成，等待提示 "请输入数字 :"，超时时间为 60 秒
    child.expect("请输入数字 :", timeout=15)
    # 发送第二个指令
    child.sendline('12')
    # 等待任务执行完成，等待提示 "请输入数字 :"，超时时间为 60 秒
    child.expect("重启", timeout=2)
    # 发送第二个指令
    child.sendline('y')

    # 获取最终输出并打印
    child.expect(pexpect.EOF)
    print(child.before)
except pexpect.TIMEOUT:
    print(child.before)
    print("操作超时，请检查脚本运行状态。")
except pexpect.EOF:
    print("脚本提前结束或无法继续执行。")

