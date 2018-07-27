#	ansible入门
##	关于ansible
- Ansible是一款IT自动化工具。它可以配置管理，部署软件并编排更高级的任务，例如持续部署或零停机滚动升级。
- Ansible的主要目标是简单易用。它还非常注重安全性和可靠性，具有最少的移动部件，使用OpenSSH进行传输（其他传输和拉模式作为替代方案），以及围绕人类可审计性设计的语言，即使那些不熟悉该程序。
- 我们相信简单性与各种规模的环境相关，因此我们为各种类型的繁忙用户进行设计：开发人员，系统管理员，发布工程师，IT经理以及其他人员。Ansible适用于管理所有环境，从少数几个实例的小型设置到数千个实例的企业环境。
- Ansible以无代理方式管理机器。永远不会有如何升级远程守护进程或由于守护进程被卸载而无法管理系统的问题。由于OpenSSH是同行评审最多的开源组件之一，安全风险大大降低。Ansible是分散的，它依赖于您现有的操作系​​统凭据来控制对远程机器的访问。如果需要，Ansible可以轻松连接Kerberos，LDAP和其他集中式身份验证管理系统。

## 安装ansible
需要epel源
```sh
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
yun install ansible -y
```
分发密钥
```sh
ssh-keygen -t dsa -P '' -f ~/.ssh/id_dsa
sshpass -p'1q2w3e$R' ssh-copy-id -i /root/.ssh/id_dsa.pub "-o StrictHostKeyChecking=no" root@10.0.0.10
```
##	第一个命令
编辑（或创建）/etc/ansible/hosts并将一个或多个远程系统放入其中。
```ini
[apiservers]
10.0.0.23
10.0.0.24
```

现在，ping所有节点：
```sh
$ ansible all -m ping
```

在所有节点上运行一个实时命令：
```sh
$ ansible all -a "/bin/echo hello"
```




##	配置文件的读取顺序
可以在配置文件中进行更改并使用该配置文件，该文件将按以下顺序搜索：
- ANSIBLE_CONFIG （如果设置了环境变量）
- ansible.cfg （在当前目录中）
- ~/.ansible.cfg （在家目录中）
- /etc/ansible/ansible.cfg

##		ansible ad-hoc执行模式
###	什么是ad-hoc命令?
ad-hoc命令是您可以输入的内容，以便快速执行某些操作，但不希望稍后保存。

一般来说，Ansible的真正强大之处在于剧本。
为什么你会使用临时任务与剧本？
例如，如果你想要重启所有web服务，则可以在Ansible中快速执行一行，而无需编写剧本。
不过，对于配置管理和部署，则需要选择使用ansible-playbook 。
开始执行命令，先列出匹配主机的列表: 
```sh
$ ansible "10.0.0.*" --list-hosts
  hosts (2):
    10.0.0.24
    10.0.0.23
```
###	执行shell命令:
```sh
ansible "10.0.0.*" -m shell -a "hostname"
```
###	文件传输:
要将文件直接传输到多台服务器：
```sh
ansible "10.0.0.*" -m copy -a "src=/etc/hosts dest=/etc/hosts owner=root group=root"
```
###	创建文件
```sh
ansible "10.0.0.*" -m file -a "path=/tmp/a.txt state=file mode=0644 owner=root group=root"
```
###	创建目录
```sh
ansible "10.0.0.*" -m file -a "path=/tmp/test state=directory mode=0755 owner=root group=root"
```
###	删除目录
```sh
ansible "10.0.0.*" -m file -a "path=/tmp/test state=absent"
```
###	管理软件包
#### 确保已安装软件包，但不要进行更新：
```sh
ansible "webservers" -m yum -a "name=iotop state=present"
```
#### 确保包装是最新版本：
```sh
ansible "webservers" -m yum -a "name=vim state=latest"
```
#### 确保未安装软件包
```sh
ansible "webservers" -m yum -a "name=iotop state=absent"
```
#### 管理服务
```sh
ansible "webservers" -m service -a "name=network state=restarted"
```

###	查看模块帮助
```sh
ansible-doc module_name
```
###	收集系统信息
```sh
ansible all -m setup 
```
###	获取目标主机的信息
```sh
ansible all -m setup -a "filter=ansible_os_family"
```
###	常用参数
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

##	主机组
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
##	默认组
有两个默认组：`all`和`ungrouped`

`all`包含每个主机
`ungrouped`包含没有属组的主机

##	主机变量和组变量
###	主机变量
```ini
[webservers]
web01 ansible_port=25535 ansible_host=10.0.0.23
web02 ansible_port=25535 ansible_host=10.0.0.24
```

```sh
ansible web01 -m ping
```
###	组变量
修改web01  web02的ssh端口为25535，并添加组变量
```ini
[webservers:vars]
ansible_port=25535
```
```sh
ansible webservers -m ping
```

###	拆分主机和组特定变量
Ansible中的首选做法是不将变量存储在主清单文件(/etc/ansible/hosts)中。

除了将变量直接存储在主清单文件中之外，主机和组变量还可以存储在相对于库存文件的单个文件中（不是目录，它始终是文件）。
这些变量文件采用YAML格式。
```sh
mkdir -p /etc/ansible/hosts_vars
mkdir -p /etc/ansible/group_vars
```
#	Ansible进阶
##	playbook简介
与adhoc任务执行模式相比，Playbooks使用ansible是一种完全不同的方式，并且功能特别强大。

简而言之，playbooks是真正简单的配置管理和多机器部署系统的基础，与已有的系统不同，并且非常适合部署复杂的应用程序。

Playbooks可以声明配置，但它们也可以协调任何手动订购流程的步骤，即使不同的步骤必须在特定订单的机器组之间来回跳转。他们可以同步或异步启动任务。

虽然您可以运行/usr/bin/ansible主程序来执行临时任务，但是更有可能将源代码保留在源代码管理中并用于推出配置或确保远程系统的配置符合规范。

Playbooks以YAML格式表示，并且具有最少的语法，有意尝试不是编程语言或脚本，而是配置或进程的模型。

##	playbook示例
```sh
cat httpd-install.yml
```
```yaml
---
- hosts: web01
  tasks:
    - name: install httpd
      yum:
        name: httpd
        state: present

    - name: start httpd
service: name=httpd state=started enabled=yes

一个playbook的文件可以包含多个剧本。你可能有一个首先针对web01，然后是web02。例如：
---
- hosts: web01
  tasks:
  - name: install httpd
    yum:
      name: httpd
      state: present

  - name: start httpd
    service: name=httpd state=started enabled=yes

- hosts: web02
  tasks:
  - name: install nginx
    yum:
      name: nginx
      state: present

  - name: copy nginx.conf
    copy:
      src: /etc/ansible/nginx.conf
      dest: /etc/nginx/conf/
    notify: restart nginx

  - name: start nginx
    service: name=nginx state=started enabled=yes

  handlers:
  - name: restart nginx
    service: name=nginx state=restarted
```
##	控制主机的执行顺序
```yaml
- hosts: all
  order: sorted
  gather_facts: False
  tasks:
    - debug:
        var: inventory_hostname
```
使用`order`关键字来控制主机的执行顺序

`order`的值可以为:
-	inventory： 默认值，执行顺序按照/etc/ansible/hosts文件提供的清单依次执行
-	reverse_inventory： 反转默认的执行顺序
-	sorted： 按主机名字母顺序排序
-	reverse_sorted： 按主机名字母顺序反向排序
-	shuffle： 随机排序执行

##	handlers
handlers是由全局唯一名称引用并由通知程序通知的任务列表，与常规任务实际上没有任何不同。如果没有通知handlers，它将不会运行。无论通知handlers的任务有多少，在特定游戏中完成所有任务后，它只会运行一次。


从Ansible 2.2开始，handlers也可以“listen”通用主题，任务可以通知如下主题：
```yaml
handlers:
    - name: restart memcached
      service:
        name: memcached
        state: restarted
      listen: "restart web services"
    - name: restart apache
      service:
        name: apache
        state:restarted
      listen: "restart web services"

tasks:
    - name: restart everything
      command: echo "this task will restart the web services"
      notify: "restart web services"
```
这种使用使得触发多个handlers变得更加容易。它还将handlers与其名称分离，从而更容易在playbooks和角色之间共享处理程序。

##	注意
-	通知handlers始终按照定义的顺序运行，而不是以notify-statement中列出的顺序运行。使用listen的handlers也是如此。
-	handlers名称和listen名称位于全局命名空间中。
-	如果两个handlers任务具有相同的名称，则只运行一个。
-	您无法通知在include内定义的处理程序。从Ansible 2.1开始，这确实有效，但是include必须是静态的。
##	刷新handlers
如果您想立即刷新所有处理程序命令，可以执行以下操作：
```yaml
tasks:
   - shell: some tasks go here
   - meta: flush_handlers
   - shell: some other task
```
在上面的示例中，任何排队的处理程序将在meta 到达语句时尽早处理。这是一个简单的案例，但有时可以派上用场。

##	提示和技巧
-	要检查剧本的语法，使用ansible-playbook与`--syntax-check`标志。这将通过解析器运行playbook文件，以确保其包含的文件，roles等没有语法问题。

-	要在运行之前查看哪个主机会受到剧本的影响，可以执行以下操作,该操作也能起到检查语法的效果：
```sh
ansible-playbook playbook.yml --list-hosts
```

-	如果你想查看成功模块及不成功模块的详细输出，请使用--verbose或 -vvv -v -vv等。

-	playbook执行的底部查看了解目标节点及其执行结果的统计。

# Ansible高级用法
##	roles
虽然可以在一个非常大的文件中编写一个剧本（并且你可能会开始以这种方式学习剧本），但最终你会希望某些任务可以重用，并用来组织更复杂的任务。在Ansible中，有三种方法可以做到这一点：include，import和roles。

###	roles目录结构
示例项目结构：
```sh
site.yml
webservers.yml
fooservers.yml
roles/
   common/
     tasks/
     handlers/
     files/
     templates/
     vars/
     defaults/
     meta/
   webservers/
     tasks/
     defaults/
     meta/
```
-	tasks - 包含roles要执行的主要任务列表。
-	handlers - 包含handlers，可以由此roles使用，甚至可以在此roles之外的任何位置使用。
-	files - 放在这个文件中的配置文件在tasks中引用时不需要写全路径。
-	templates -放在这个文件中的配置模板文件在tasks中引用时不需要写全路径。
-	meta - 为此roles定义一些依赖（一般常用）。
-	defaults- roles的默认变量(不常用)。
-	vars- roles的其他变量（不常用）。


###	角色依赖
角色依赖性允许您在使用角色时自动引入其他角色。meta/main.yml如上所述，角色依赖关系存储在角色目录中包含的文件中。此文件应包含要在指定角色之前插入的角色和参数列表，例如以下示例roles/myapp/meta/main.yml：
```sh
cat /etc/ansible/roles/install/tomcat/meta/main.yml
---
dependencies:
  - role: init
  - role: jdk
```
##	变量
###	有效的变量名
变量名称应为字母，数字和下划线。变量应始终以字母开头。
在YMAL语法中，还支持将键映射到值的字典形式，例如:
```yaml
foo:
  field1: one
  field2: two
```

然后，您可以使用括号或点引用字典中的特定字段：
```
foo['field1']
foo.field1
```

但是，如果您选择使用点表示法，请注意某些键可能会导致问题，因为它们会与python字典的属性和方法发生冲突。
###	在主机清单文件中定义变量
    参考第一章内容

###	在playbook中定义变量
在剧本中，可以直接内联定义变量，如下所示：
```yaml
- hosts: webservers
  vars:
    http_port: 80
```
###	在yaml中引用变量的坑
你会发现这样做不起作用，或报错:
```yaml
- hosts: app_servers
  vars:
      app_path: {{ base_path }}/22
```

这样做你会没事:
```yaml
- hosts: app_servers
  vars:
       app_path: "{{ base_path }}/22"
```

###	收集系统信息: Facts
在Ansible中，还有其他可以来自变量的地方，但这些是发现的变量类型，不是由用户设置的。
Facts是通过与你的远程系统通信而获得的信息
例如，ip地址、操作系统等。
要查看收集到的所有信息,请尝试以下操作:
```sh
ansible hostname -m setup
```

在template或剧本引用主机名的方法为:
`{{ ansible_hostname }}`
同样，网卡eth0的ip地址为:
`{{ ansible_eth0.ipv4.address }}`
系统信息为:
`{{ ansible_os_family }}`

这些变量通常用于`when`语句(条件判断)和`template`中。
###	关闭Facts
收集Facts需要消耗一些ansible的执行时间，如果你知道自己不需要任何有关主机的Facts数据，则可以关闭Facts。在任何playbook中，只需要这样做:
```yaml
- hosts: webservers
  gather_facts: no
```
###	访问复杂的变量数据
一些提供的Facts(如网络信息)可用作嵌套数据结构。要直接访问它们是不行的，但它仍然很容易做到。以下是我们获取ip地址的方式:
`{{ ansible_eth0["ipv4"]["address"] }}`
或者
`{{ ansible_eth0.ipv4.address }}`
如果是一个列表,你可以这样:
`{{ foo[0] }}`

###	如何访问其他主机的变量
即使你没有自己定义它们，Ansible也会自动为您提供一些变量，最重要的有hostvars, group_names和groups。用户不应使用这些名称作为变量，因为它们是系统保留的。

hostvars让您询仍另一个主机的变量，包括已收集的有关该主机的Facts。
获取别一台主机的主机名，你只需要这样做:
`{{ hostvars['web01']['ansible_hostname'] }}`

###	变量文件分离
将您的剧本保持在源代码控制之下是一个好主意，但您可能希望将剧本源公开，同时保持某些重要变量的私密性。同样，有时您可能只想将某些信息保存在远离主要剧本的不同文件中。
您可以使用外部变量文件或文件来执行此操作，如下所示：
```yaml
---
- hosts: all
  remote_user: root
  vars:
    favcolor: blue
  vars_files:
- /vars/external_vars.yml

  tasks:
  - name: this is just a placeholder
    command: /bin/echo foo
```

###	在命令行上传递变量
可以使用--extra-vars或-e参数在命令行中设置变量。

key=values的格式:
```sh
ansible-playbook release.yml --extra-vars "host=web01 version=1.0.1"
```
json字符串格式:
```sh
ansible-playbook release.yml --extra-vars '{"host":"web01","version":"1.0.1"}'
ansible-playbook arcade.yml --extra-vars {"host":["web01","web02"],"version":"1.0.1"}'
```
YMAL字符串格式:
```sh
ansible-playbook release.yml --extra-vars '
host: web01
version: 1.0.1'

ansible-playbook release.yml --extra-vars '
host: 
  - web01
  - web02
version: 1.0.1'
```
来自json或yaml文件的变量:
```sh
ansible-playbook release.yml --extra-vars "@vars_file.yml"
```
###	变量优先级
Ansible有很多的位置可以放置变量，变量可能会被另一个变量覆盖，Ansible的理念是，你知道在哪里放置变量会更好，但这不应该是你最需要考虑的。

避免在47个位置中定义一个变量"x",然后询问"哪个x会被使用"这样的问题。为什么？因为这不是使用Ansible的最佳实践。也不符合Ansible的设计理念。

相同的变量名尽可能只在一处定义。找到定义变量的位置，不要让它变得复杂。

但你依然有可能会在不同的位置定义多个同名变量，按特定顺序覆盖它们。
是的，这是真实存在的。

以下是从最小到最大的优先顺序:
-	role defaults [1]
-	inventory file or script group vars [2]
-	inventory group_vars/all [3]
-	playbook group_vars/all [3]
-	inventory group_vars/* [3]
-	playbook group_vars/* [3]
-	inventory file or script host vars [2]
-	inventory host_vars/*
-	playbook host_vars/*
-	host facts / cached set_facts [4]
-	inventory host_vars/* [3]
-	playbook host_vars/* [3]
-	host facts
-	play vars
-	play vars_prompt
-	play vars_files
-	role vars (defined in role/vars/main.yml)
-	block vars (only for tasks in block)
-	task vars (only for the task)
-	include_vars
-	set_facts / registered vars
-	role (and include_role) params
-	include params
-	extra vars (优先级最高)

##	模板(Jinja2)
###	测试
####	测试字符串
要将字符串与子字符串或正则表达式匹配，请使用“match”或“search”过滤器：
```yaml
vars:
  url: "http://example.com/users/foo/resources/bar"
tasks:
    - debug:
        msg: "matched pattern 1"
      when: url is match("http://example.com/users/.*/resources/.*")

    - debug:
        msg: "matched pattern 2"
      when: url is search("/users/.*/resources/.*")

    - debug:
        msg: "matched pattern 3"
      when: url is search("/users/")
```
'match'需要字符串中的完全匹配，而'search'仅需要匹配字符串的子集。

####	测试任务状态

以下任务说明了用于检查任务状态的测试：
```yaml
tasks:
  - shell: /usr/bin/foo
    register: result
    ignore_errors: True

  - debug:
      msg: "it failed"
    when: result is failed

  # in most cases you'll want a handler, but if you want to do something right now, this is nice
  - debug:
      msg: "it changed"
    when: result is changed

  - debug:
      msg: "it succeeded in Ansible >= 2.1"
    when: result is succeeded

  - debug:
      msg: "it succeeded"
    when: result is success

  - debug:
      msg: "it was skipped"
    when: result is skipped
```

##	条件判断
    通常playbook的结果可能取决于变量的值，Facts或先前的任务结果。在某些情况下，变量的值可能取决于其他变量。

###	when语句
    有时候你会想要跳过特定主机上的特定步骤。如果操作系统是特定版本，在Ansible中使用when语句很容易做到这一点，该子句包含一个没有双花括号的原始jinja2表达式。如:
```yaml
tasks:
  - name: "shut down Debian flavored systems"
    command: /sbin/shutdown -t now
    when: ansible_os_family == "Debian"
```

您还可以使用括号对条件进行分组：
```yaml
tasks:
  - name: "shut down CentOS 6 and Debian 7 systems"
    command: /sbin/shutdown -t now
    when: (ansible_distribution == "CentOS" and ansible_distribution_major_version == "6") or
          (ansible_distribution == "Debian" and ansible_distribution_major_version == "7")
```

当需要多个条件为真的时候也可以指定列表:
```yaml
tasks:
  - name: "shut down CentOS 6 systems"
    command: /sbin/shutdown -t now
    when:
      - ansible_distribution == "CentOS"
- ansible_distribution_major_version == "6"
```

###	将when应用于roles
有这样一个roles：
```sh
cat /etc/ansible/install-tomcat.yml
- hosts: webservers
  roles:
     - role: tomcat
       when: ansible_os_family == 'Debian'
```
###	变量注册
变量注册的用途是运行命令并使改命令的结果保存到变量中，结果因模块而异。 使用-v 执行playbook时将显示结果的可能值。
`register`关键字决定保存结果的变量。结果变量可用于模板，操作行或when语句。它看起来像这样（显然，这是一个简单的例子）：

```yaml
tasks:
  - name: register variables
    shell: echo "hello,world!"
    register: result

  - debug:
msg: "{{ result.stdout }}"

  - shell: hostname
    when: result.rc != 0
```
如上所示，可以使用stdout值访问已注册变量的字符串内容。如果将注册结果转换为列表(或已经是列表)，则可以在任务的循环中使用该注册结果。 “stdout_lines”已经可以在对象上使用了
```yaml
- name: registered variable usage as a loop list
  hosts: all
  tasks:

    - name: retrieve the list of home directories
      command: ls /home
      register: home_dirs

    - name: add home dirs to the backup spooler
      file:
        path: /mnt/bkspool/{{ item }}
        src: /home/{{ item }}
        state: link
      loop: "{{ home_dirs.stdout_lines }}"
      # same as loop: "{{ home_dirs.stdout.split() }}"
```

##	循环
通常，您希望在一个任务中执行许多操作，例如创建大量用户，安装大量软件或重复轮询步骤时，可能使用到循环。
###	标准循环
为了节省一些打字，重复的任务可以用简写的方式，如下：
```yaml
- name: yum install
  yum: name="{{ item }}" state=present
  loop:
    - iotop
    - telnet
```
如果您已在变量文件或"vars"部分中定义了YAML列表，则还可以执行以下操作。
```
loop: "{{ package_list }}"
```
它相当于:
```yaml
- name: yum install
  yum: name=iotop state=present

- name: yum install
  yum: name=telnet state=present
```
注意:
>   在ansible 2.5主要使用with_items关键字创建循环，loop关键字基本上类似于with_items。


迭代的类型不必是简单的字符串列表。如果您有哈希列表，则可以使用以下内容引用子键:
```yaml
- name: touch file
  file:
    path: "{{ item.path }}"
    state: touch
    mode: "{{ item.mode }}"
  loop:
    - { path: '/tmp/hosts', mode: '0644' }
    - { path: '/tmp/test', mode: '0600' }
```
###	do-until循环
有时您会想要重试任务，直到满足某个条件。这是一个例子：
```yaml
- shell: /usr/bin/foo
  register: result
  until: result.stdout.find("all systems go") != -1
  retries: 5
  delay: 10
```

上面的示例递归地运行shell模块，直到模块的结果在其stdout中“所有系统都进入”或者任务已经被重试了5次，延迟为10秒。“重试”的默认值为3，“延迟”为5。
该任务返回上次任务运行返回的结果。可以通过-vv选项查看单个重试的结果。注册变量还将具有新的键“尝试”，其将具有该任务的重试次数。
注意
如果until未定义retries参数，则参数的值将强制为1。
##	block
您可以在块级别应用大多数可应用于单个任务的内容，这也使得设置任务共有的数据或指令变得更加容易。这并不意味着该指令会影响块本身，而是由块所包含的任务继承。即何时将应用于任务，而不是块本身。
```yaml
tasks:
   - name: Install Apache
     block:
       - yum:
           name: "{{ item }}"
           state: installed
         with_items:
           - httpd
           - memcached
       - template:
           src: templates/src.j2
           dest: /etc/foo.conf
       - service:
           name: bar
           state: started
           enabled: True
     when: ansible_distribution == 'CentOS'
     become: true
     become_user: root
```
在上面的示例中，在从块中附加when条件并在任务的上下文中对其进行评估之后，将执行3个任务中的每个任务。他们还继承了权限升级指令，使所有封闭的任务“成为root”。
###	错误处理
块还引入了以类似于大多数编程语言中的异常的方式处理错误的能力。
```yaml
tasks:
 - name: Attempt and graceful roll back demo
   block:
     - debug:
         msg: 'I execute normally'
     - command: /bin/false
     - debug:
         msg: 'I never execute, due to the above task failing'
   rescue:
     - debug:
         msg: 'I caught an error'
     - command: /bin/false
     - debug:
         msg: 'I also never execute :-('
   always:
     - debug:
         msg: "This always executes"
```
这里的任务block会正常执行，如果有任何错误，该rescue部分将被执行，无论你需要做什么来从上一个错误中恢复。always无论先前的错误在block和rescue部分中发生或没有发生，该部分都会运行。应该注意的是，如果一个rescue部分成功完成，因为它“擦除”错误状态（但不是报告），播放将继续 ，这意味着它不会触发max_fail_percentage或any_errors_fatal配置，但会出现在剧本统计中。

另一个例子是在发生错误后如何运行处理程序：
在错误处理中阻止运行处理程序
```yaml
tasks:
   - name: Attempt and graceful roll back demo
     block:
       - debug:
           msg: 'I execute normally'
         notify: run me even after an error
       - command: /bin/false
     rescue:
       - name: make sure all handlers run
         meta: flush_handlers
 handlers:
    - name: run me even after an error
      debug:
        msg: 'This handler runs even on error'
```
##	tags
如果你有一个大型的剧本，那么能够在不运行整个剧本的情况下运行配置的特定部分可能会很有用。
出于这个原因，播放和任务都支持“tags：”属性。您只能使用--tags或从命令行基于标记过滤任务--skip-tags。在游戏的任何部分（包括角色）中添加“tags：”会将这些标记添加到包含的任务中。
```yaml
tasks:
    - yum:
        name: "{{ item }}"
        state: installed
      loop:
         - httpd
         - memcached
      tags:
         - packages

    - template:
        src: templates/src.j2
        dest: /etc/foo.conf
      tags:
         - configuration
```
如果你想只运行一个很长的剧本的“配置”和“包”，你可以这样做：
```sh
ansible-playbook example.yml --tags"configuration，packages"
```
另一方面，如果你想在没有特定任务的情况下运行一本剧本，你可以这样做：
```sh
ansible-playbook example.yml --skip-tags "notification"
```
###	标签重用
您可以将同一标记名称应用于同一文件或包含文件中的多个任务。这将使用该标记运行所有任务。如:
```yaml
---
# file: roles/common/tasks/main.yml

- name: be sure ntp is installed
  yum:
    name: ntp
    state: installed
  tags: ntp

- name: be sure ntp is configured
  template:
    src: ntp.conf.j2
    dest: /etc/ntp.conf
  notify:
    - restart ntpd
  tags: ntp

- name: be sure ntpd is running and enabled
  service:
    name: ntpd
    state: started
    enabled: yes
  tags: ntp
```
###	标签继承
您可以将tags应用于多个任务，但它们只会影响任务本身。在任何其他地方应用tags只是一种便利，因此您不必在每个任务上编写它：
```yaml
- hosts: all
  tags:
    - bar
  tasks:
    ...

- hosts: all
  tags: ['foo']
  tasks:
    ...
```
您还可以将标记应用于角色导入的任务：
```yaml
roles:
  - role: webserver
    vars:
      port: 5000
    tags: [ 'web', 'foo' ]
```
所有这些都将指定的标签应用于播放，导入的文件或角色中的EACH任务，以便在使用相应的标签调用播放簿时可以选择性地运行这些任务。
没有办法'只导入这些标签'; 如果你发现自己正在寻找这样的功能，你可能想要分成更小的角色/包括。
以上信息不适用于include_tasks或其他动态包含，因为应用于包含的属性仅影响包含本身。
标签被继承下来的依赖链。为了将标记应用于角色及其所有依赖项，标记应该应用于角色，而不是应用于角色中的所有任务。
通过ansible-playbook使用该--list-tasks选项运行，您可以查看哪些标记应用于任务。您可以使用该--list-tags选项显示所有标签。
###	特殊标签
always除非特别跳过（），否则有一个特殊标记将始终运行任务--skip-tags always
```yaml
tasks:
    - debug:
        msg: "Always runs"
      tags:
        - always

    - debug:
        msg: "runs when you use tag1"
      tags:
        - tag1
```
##	从指定位置开始执行playbook
如果您想在特定任务中开始执行您的剧本，您可以使用以下--start-at-task选项：
```sh
ansible-playbook playbook.yml --start-at-task="install packages"
```
这些对于测试新的playbook或调试非常有用。


#	Ansible例子
##	一个系统初始化剧本
```yaml
- name: copy to /root/.bash_profile
  copy: src={{ item.src }} dest={{ item.dest }}
  loop:
    - { src: '.bash_profile', dest: '/root/.bash_profile' }
    - { src: 'su', dest: '/etc/pam.d/su' }
    - { src: 'bashrc', dest: '/etc/bashrc' }
    - { src: '/etc/hosts', dest: '/etc/hosts' }

- name: copy sshd_config
  copy: src=sshd_config dest=/etc/ssh/
  notify: restart sshd

- name: yum install
  yum: name={{ item }} state=latest
  loop:
    - iotop
    - unzip
    - bash-completion
    - wget
    - tree
    - lsof
    - telnet

- name: change rc.local privileges
  file: path=/etc/rc.d/rc.local mode=0755
```
##	部署tomcat
#### 安装jdk
```sh
cat /etc/ansible/roles/install/jdk/tasks/main.yml
```
```yaml
- name: copy jdk
  copy:
    src: "{{ jdk_version }}.tar.gz"
    dest: /usr/local/src/

- name: create install dir
  file:
    path: /application
    state: directory

- name: unarchive jdk
  unarchive:
    src: "/usr/local/src/{{ jdk_version }}.tar.gz"
    dest: /application
    remote_src: yes

- name: link jdk
  file:
    src: "/application/jdk1.8.0_131"
    dest: /application/jdk
    state: link

- name: add profile
  lineinfile:
    path: /etc/profile
    line: "{{ item }}"
  with_items:
    - 'export JAVA_HOME=/application/jdk'
    - 'export PATH=$JAVA_HOME/bin:$JAVA_HOME/jre/bin:$PATH'
    - 'export CLASSPATH=.$CLASSPATH:$JAVA_HOME/lib:$JAVA_HOME/jre/lib:$JAVA_HOME/lib/tools.jar'

- name: yum install rngd
  yum: name=rng-tools state=present

- name: started rngd
  service: name=rngd state=started enabled=yes
```
#### 安装tomcat
```sh
cat /etc/ansible/roles/install/tomcat/tasks/main.yml
```
```yaml
- name: test /application/tomcat exist
  shell: test -d /application/tomcat
  ignore_errors: yes
  register: result

- name: 解压文件
  unarchive:
    src: "apache-tomcat-{{ tomcat_version }}.tar.gz"
    dest: "/application/"
    creates: "apache-tomcat-{{ tomcat_version }}"
  when: result.rc != 0

- name: create link tomcat
  file:
    src: "/application/apache-tomcat-{{ tomcat_version }}"
    dest: /application/tomcat
    state: link

- name: configure tomcat
  copy: src={{ item.src }} dest={{ item.dest }} mode={{ item.mode }}
  loop:
    - { src: 'tomcatd', dest: '/etc/init.d/', mode: '0755' }
    - { src: 'server.xml', dest: '/application/tomcat/conf/', mode: '0600' }
    - { src: 'catalina.sh', dest: '/application/tomcat/bin/', mode: '0750' }
  notify: restart tomcatd

- name: insert '/etc/init.d/tmocatd start' to /etc/rc.local
  lineinfile:
    path: /etc/rc.d/rc.local
    line: "{{ item }}"
    mode: 0755
  loop:
    - 'source /etc/profile'
    - '/etc/init.d/tomcatd start'

- name: "delete webapps/{{ item }}"
  file:
    path: "/application/tomcat/webapps/{{ item }}"
    state: absent
  loop:
    - docs
    - examples
    - host-manager
    - manager
```

####查看依赖
```sh
cat /etc/ansible/roles/install/tomcat/meta/main.yml
```
```yaml
---
dependencies:
  - role: init
  - role: jdk
```
##	自动化扩容	

- 1、	将主机ip做主机名解析添加到/etc/hosts
- 2、	对被管理服务器做ssh密钥认证
- 3、	将主机名添加到对应的/etc/ansible/hosts群组，按需要配置组变量.
- 4、	执行对应的roles剧本。

##	滚动升级
https://docs.ansible.com/ansible/latest/user_guide/playbooks_delegation.html

```yaml
---
- hosts: "webservers"
  serial: 1
  roles:
    - release
```
这只是一个正常的播放定义，在webservers小组上运行。该`serial`关键字告诉Ansible一次操作多少台服务器。如果未指定，Ansible将这些操作并行化，直到配置文件中指定的默认“forks”(并发数)限制。但是对于零停机时间滚动升级，您可能不希望同时在那么多主机上运行。如果您只有少数几个Web服务器，您可能希望`serial`一次为一个主机设置为1。如果你有100，也许你可以设置`serial`为10，一次10。

注意:
>	该`serial`关键字强制发挥在“批”执行。每个批次都计为主机的子选择的完整游戏。这对游戏行为有一些影响。例如，如果批处理中的所有主机都出现故障，则播放将失败，从而导致整个运行失败。结合时应该考虑这个`max_fail_percentage`。
最大失败百分比：

默认情况下，只要批处理中的主机尚未发生故障，Ansible将继续执行操作。播放的批量大小由serial参数决定。如果serial未设置，则批量大小是该hosts:字段中指定的所有主机。在某些情况下，例如通过上述滚动更新，可能希望在达到某个故障阈值时中止播放。要实现此目的，您可以在播放中设置最大失败百分比，如下所示：

```yaml
- hosts: webservers
  max_fail_percentage: 30
  serial: 10
```
注意： 
> 在上面的示例中，如果组中的10个服务器中有3个以上发生故障，则播放的其余部分将中止。
> 必须超过百分比集，而不是等于。例如，如果serial设置为4并且您希望在2个系统发生故障时中止任务，则百分比应设置为49而不是50。




