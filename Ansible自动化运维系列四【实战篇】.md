# Ansible实战
在实战部分，引用一个完整的tomcat服务器的部署流程示例.
当你购买或新装了一台机器时，你可能需要准备以下操作:
- 对系统进行环境变量配置、安全优化、hosts文件解析、常用软件安装等
- 安装运行依赖，如部署java运行环境，jdk，包括配置环境变量等
- 安装守护进程服务，如tomcat，你可能要调整jvm参数，添加启动脚本等。
- 对安装的服务进行监控

往下，有完整的剧本示例

## 一个系统初始化剧本

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

## 安装jdk
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
## 安装tomcat
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

#### 依赖关系
```sh
cat /etc/ansible/roles/install/tomcat/meta/main.yml
```
```yaml
---
dependencies:
  - role: init
  - role: jdk
```
## 扩容	

- 1、将主机ip做主机名解析添加到/etc/hosts
- 2、对被管理服务器做ssh密钥认证
- 3、将主机名添加到对应的/etc/ansible/hosts群组，按需要配置组变量.
- 4、执行对应的roles剧本。

最后，有关ansible更多高级用法和最佳实践欢迎大家一起讨论。
