# ansible入门
在入门阶段首先展示的不是ansible强大的配置、部署、编排功能，这些功能由剧本处理，这些将单独介绍。
## 关于ansible
* Ansible是一款IT自动化工具。它可以配置管理，部署软件并编排更高级的任务，例如持续部署或零停机滚动升级。
* Ansible的主要目标是简单易用。它还非常注重安全性和可靠性，具有最少的移动部件，使用OpenSSH进行传输（其他传输和pull模式作为替代方案），以及围绕人类可审计性设计的语言，即使那些不熟悉该程序。
* Ansible相信简单性与各种规模的环境相关，因此Ansible为各种类型的繁忙用户进行设计：开发人员，系统管理员，发布工程师，IT经理以及其他人员。Ansible适用于管理所有环境，从少数几个实例的小型设置到数千个实例的企业环境。
* Ansible以无代理方式管理机器。永远不会有如何升级远程守护进程或由于守护进程被卸载而无法管理系统的问题。由于OpenSSH是同行评审最多的开源组件之一，安全风险大大降低。Ansible是分散的，它依赖于您现有的操作系统凭据来控制对远程机器的访问。如果需要，Ansible可以轻松连接Kerberos，LDAP和其他集中式身份验证管理系统。

## 安装ansible
#### 需要epel源
```sh
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
yum install ansible -y
```
#### 分发密钥
```sh
yum install sshpass -y
ssh-keygen -t dsa -P '' -f ~/.ssh/id_dsa
sshpass -p'123456' ssh-copy-id -i /root/.ssh/id_dsa.pub "-o StrictHostKeyChecking=no" root@10.0.0.21
```
## 第一个命令
编辑或创建/etc/ansible/hosts并将一个或多个远程系统放入其中。
```ini
[webservers]
10.0.0.21
10.0.0.22
```

现在，ping所有节点：
```sh
$ ansible all -m ping
```

在所有节点上运行一个实时命令：
```sh
$ ansible all -a "/bin/echo hello"
```




## 配置文件的读取顺序
可以在配置文件中进行更改并使用该配置文件，该文件将按以下顺序搜索：
- ANSIBLE_CONFIG （如果设置了环境变量）
- ansible.cfg （在当前目录中）
- ~/.ansible.cfg （在家目录中）
- /etc/ansible/ansible.cfg (默认的配置文件)

## ansible ad-hoc执行模式
### 什么是ad-hoc命令?
ad-hoc命令是您可以输入的内容，以便快速执行某些操作，但不希望稍后保存。

一般来说，Ansible的真正强大之处在于剧本。

为什么你会使用临时任务与剧本？

例如，如果你想要重启所有web服务，则可以在Ansible中快速执行一行，而无需编写剧本。

不过，对于配置管理和部署，则需要选择使用ansible-playbook 。


### 开始执行命令，先列出匹配主机的列表: 
```sh
$ ansible "10.0.0.*" --list-hosts
  hosts (2):
    10.0.0.24
    10.0.0.23
```
### 执行shell命令:
```sh
ansible "10.0.0.*" -m shell -a "hostname"
```
### 文件传输:
要将文件直接传输到多台服务器：
```sh
ansible "10.0.0.*" -m copy -a "src=/etc/hosts dest=/etc/hosts owner=root group=root"
```
### 创建文件
```sh
ansible "10.0.0.*" -m file -a "path=/tmp/test.txt state=touch mode=0644 owner=root group=root"
```
### 创建目录
```sh
ansible "10.0.0.*" -m file -a "path=/tmp/test state=directory mode=0755 owner=root group=root"
```
### 删除目录
```sh
ansible "10.0.0.*" -m file -a "path=/tmp/test state=absent"
```
### 管理软件包
#### 确保已安装软件包，但不要进行更新：
```sh
ansible "webservers" -m yum -a "name=iotop state=present"
```
### 确保包装是最新版本：
```sh
ansible "webservers" -m yum -a "name=vim state=latest"
```
### 确保未安装软件包
```sh
ansible "webservers" -m yum -a "name=iotop state=absent"
```
### 管理服务
```sh
ansible "webservers" -m service -a "name=network state=restarted"
```

## 小结
> 以上是ansible一些模块的简单使用，这些模块更多用于playbook

也许你已经发现shell模块可以为我们执行几乎所有的操作，为什么要选择用特定的模块来执行ansible任务?

如果只用shell模块，你无法知道你执行后的结果是否有改变，并且需要添加额外的判断语句.

使用特定的模块执行任务，会让playbook更加安全可靠。

往下，你会发现更多有趣的功能。


### 查看模块帮助
```sh
ansible-doc module_name
```
### 收集系统信息
```sh
ansible web01 -m setup 
```
### 获取目标主机的信息
```sh
ansible all -m setup -a "filter=ansible_os_family"
```

### 常用参数
```sh
--list-hosts 输出匹配主机的列表; 不执行任何其他事情
--version显示程序的版本号并退出
-C, --check不要做任何改变; 相反，试着预测一些可能发生的变化
-m --module-name 要执行的模块名称（默认=command）
-a  模块参数
-e, --extra-vars 将其他变量设置为key = value或YAML / JSON，如果文件名前缀为@
-f <FORKS>, --forks <FORKS> 指定要使用的并行进程数（默认值= 5）
-v, --verbose详细模式（-vvv for more，-vvvv启用连接调试）
```

## 主机组
定义主机和组的文件默认在/etc/ansible/hosts，除了默认的格式之外，还可以使用ymal格式(不常用)来定义。
YAML格式如:

```yml
all ：
  hosts ：
    mail.example.com ：
  children ：
    webservers ：
      hosts ：
        foo.example.com ：
        bar.example.com ：
    dbservers ：
      hosts ：
        one.example.com ：
        two.example.com ：
        three.example.com ：

```

###  默认组

有两个默认组：`all`和`ungrouped`

* `all`包含每个主机
* `ungrouped`包含没有属组的主机

## 主机变量和组变量
### 主机变量
```ini
[webservers]
web01 ansible_port=45535 ansible_host=10.0.0.21
web02 ansible_port=45535 ansible_host=10.0.0.22
```

```sh
ansible web01 -m ping
```
### 组变量
修改web01  web02的ssh端口为45535，并添加组变量

```ini
[webservers:vars]
ansible_port=45535
```

```sh
ansible webservers -m ping
```

### 拆分主机和组特定变量
Ansible中的首选做法是不将变量存储在主清单文件(/etc/ansible/hosts)中。

除了将变量直接存储在主清单文件中之外，主机和组变量还可以存储在相对于库存文件的单个文件中（不是目录，它始终是文件）。
这些变量文件采用YAML格式。
```sh
mkdir -p /etc/ansible/hosts_vars
mkdir -p /etc/ansible/group_vars
```
创建这两个目录，它是Ansible默认的主机变量和组变量文件的目录。
