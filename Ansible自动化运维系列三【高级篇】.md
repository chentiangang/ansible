# Ansible高级用法
## roles
虽然可以在一个非常大的文件中编写一个剧本（并且你可能会开始以这种方式学习剧本），但最终你会希望某些任务可以重用，并用来组织更复杂的任务。

在Ansible中，有三种方法可以做到这一点：include，import和roles。

### roles目录结构
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
- tasks - 包含roles要执行的主要任务列表。
- handlers - 包含handlers，可以由此roles使用，甚至可以在此roles之外的任何位置使用。
- files - 放在这个文件中的配置文件在tasks中引用时不需要写全路径。
- templates -放在这个文件中的配置模板文件在tasks中引用时不需要写全路径。
- meta - 为此roles定义一些依赖（一般常用）。
- defaults- roles的默认变量(不常用)。
- vars- roles的其他变量（不常用）。


### 角色依赖
角色依赖性允许您在使用角色时自动引入其他角色。
meta/main.yml如上所述，角色依赖关系存储在角色目录中包含的文件中。
此文件应包含要在指定角色之前插入的角色和参数列表，例如以下示例roles/myapp/meta/main.yml：
```sh
cat /etc/ansible/roles/install/tomcat/meta/main.yml
---
dependencies:
  - role: init
  - role: jdk
```
## 变量
### 有效的变量名
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
### 在主机清单文件中定义变量
   参考第一节的内容

### 在playbook中定义变量
在剧本中，可以直接内联定义变量，如下所示：
```yaml
- hosts: webservers
  vars:
    http_port: 80
```
### 在yaml中引用变量的坑
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

### 收集系统信息: Facts
在Ansible中，还有其他可以来自变量的地方，但这些是发现的变量类型，不是由用户设置的。
Facts是通过与你的远程系统通信而获得的信息
例如，ip地址、操作系统等。
要查看收集到的所有信息,请尝试以下操作:
```sh
ansible web01 -m setup
```

在template或剧本引用主机名的方法为: `{{ ansible_hostname }}`

同样，网卡eth0的ip地址为: `{{ ansible_eth0.ipv4.address }}`

系统信息为: `{{ ansible_os_family }}`

这些变量通常用于`when`语句(条件判断)和`template`中。

### 关闭Facts
收集Facts需要消耗一些ansible的执行时间，如果你知道自己不需要任何有关主机的Facts数据，则可以关闭Facts。在任何playbook中，只需要这样做:
```yaml
- hosts: webservers
  gather_facts: no
```
### 访问复杂的变量数据
一些提供的Facts(如网络信息)可用作嵌套数据结构。要直接访问它们是不行的，但它仍然很容易做到。以下是获取ip地址的方式:
`{{ ansible_eth0["ipv4"]["address"] }}`

或者  `{{ ansible_eth0.ipv4.address }}`

如果是一个列表,你可以这样:  `{{ foo[0] }}`

### 如何访问其他主机的变量
即使你没有自己定义它们，Ansible也会自动为您提供一些变量，最重要的有hostvars, group_names和groups。

用户不应使用这些名称作为变量，因为它们是系统保留的。

hostvars让您询仍另一个主机的变量，包括已收集的有关该主机的Facts。
获取别一台主机的主机名，你只需要这样做: `{{ hostvars['web01']['ansible_hostname'] }}`

### 变量文件分离
将您的剧本保持在源代码控制之下是一个好主意，但您可能希望将剧本源公开，同时保持某些重要变量的私密性。

同样，有时您可能只想将某些信息保存在远离主要剧本的不同文件中。

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

### 在命令行上传递变量
可以使用--extra-vars或-e参数在命令行中设置变量，这是读取变量最高的优先级别。

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
### 变量优先级
Ansible有很多的位置可以放置变量，变量可能会被另一个变量覆盖，Ansible的理念是，你知道在哪里放置变量会更好，但这不应该是你最需要考虑的。

避免在47个位置中定义一个变量"x",然后询问"哪个x会被使用"这样的问题。

为什么？因为这不是使用Ansible的最佳实践。也不符合Ansible的设计理念。

相同的变量名尽可能只在一处定义。找到定义变量的位置，不要让它变得复杂。

但你依然有可能会在不同的位置定义多个同名变量，按特定顺序覆盖它们。

以下是从最小到最大的优先顺序:
- role defaults [1]
- inventory file or script group vars [2]
- inventory group_vars/all [3]
- playbook group_vars/all [3]
- inventory group_vars/* [3]
- playbook group_vars/* [3]
- inventory file or script host vars [2]
- inventory host_vars/*
- playbook host_vars/*
- host facts / cached set_facts [4]
- inventory host_vars/* [3]
- playbook host_vars/* [3]
- host facts
- play vars
- play vars_prompt
- play vars_files
- role vars (defined in role/vars/main.yml)
- block vars (only for tasks in block)
- task vars (only for the task)
- include_vars
- set_facts / registered vars
- role (and include_role) params
- include params
- extra vars (优先级最高)

## 模板(Jinja2)
为什么叫Jinja2？这是我在刚学ansible的时候很苦恼的问题
Jinja2给我们提供很的条件及过虑表达式，以下是一些可能用到的表达式用方。

### 测试
#### 测试字符串
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

#### 测试任务状态

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

## 条件判断
通常playbook的结果可能取决于变量的值，Facts或先前的任务结果。在某些情况下，变量的值可能取决于其他变量。

### when语句
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

### 将when应用于roles
有这样一个roles：
```ymal
cat /etc/ansible/install-tomcat.yml
- hosts: webservers
  roles:
     - role: tomcat
       when: ansible_os_family == 'Debian'
```

### 变量注册
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

## 循环
通常，您希望在一个任务中执行许多操作，例如创建大量用户，安装大量软件或重复轮询步骤时，可能使用到循环。
### 标准循环
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

## block
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
在上面的示例中，在从块中附加when条件并在任务的上下文中对其进行评估之后，将执行3个任务中的每个任务。
他们还继承了权限升级指令，使所有封闭的任务“成为root”。
## tags
如果你有一个大型的剧本，那么能够在不运行整个剧本的情况下运行配置的特定部分可能会很有用。
出于这个原因，播放和任务都支持“tags：”属性。
您只能使用--tags或从命令行基于标记过滤任务--skip-tags。
在游戏的任何部分（包括角色）中添加“tags：”会将这些标记添加到包含的任务中。
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
### 标签重用
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
### 标签继承
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
### 特殊标签
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
## 从指定位置开始执行playbook
如果您想在特定任务中开始执行您的剧本，您可以使用以下--start-at-task选项：
```sh
ansible-playbook playbook.yml --start-at-task="install packages"
```
这些对于测试新的playbook或调试非常有用。

