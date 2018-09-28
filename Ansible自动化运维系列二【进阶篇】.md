# Ansible进阶
## playbook简介
与ad-hoc任务执行模式相比，Playbooks使用ansible是一种完全不同的方式，并且功能特别强大。

简而言之，playbooks是真正简单的配置管理和多机器部署系统的基础，并且非常适合部署复杂的应用程序。

Playbooks可以声明配置，但它们也可以协调任何手动部署流程的步骤，即使不同的步骤必须在特定清单的机器组之间来回跳转。它们可以同步或异步启动任务。

虽然您可以运行/usr/bin/ansible主程序来执行临时任务，但是更有可能将源代码保留在源代码管理中并用于推送配置或确保远程系统的配置符合规范。

Playbooks以YAML格式表示，并且具有最少的语法，有意尝试不是编程语言或脚本，而是配置或进程的模型。

## playbook示例
```yaml
cat httpd-install.yml


---
- hosts: web01
  tasks:
    - name: install httpd
      yum:
        name: httpd
        state: present

    - name: start httpd
      service: name=httpd state=started enabled=yes
```

一个playbook的文件可以包含多个剧本。你可能有一个首先针对web01，然后是web02。例如：
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

## 控制主机的执行顺序
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
- inventory： 默认值，执行顺序按照/etc/ansible/hosts文件提供的清单依次执行
- reverse_inventory： 反转默认的执行顺序
- sorted： 按主机名字母顺序排序
- reverse_sorted： 按主机名字母顺序反向排序
- shuffle： 随机排序执行

## handlers
handlers是由全局唯一名称引用并由通知程序通知的任务列表，与常规任务实际上没有任何不同。

如果没有通知handlers，它将不会运行。

无论通知handlers的任务有多少，在特定剧本中完成所有任务后，它只会运行一次。

从Ansible 2.2开始，handlers也可以使用“listen”关键字，任务可以以如下方式触发handlers:
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
这种使用使得触发多个handlers变得更加容易。它还将handlers与其名称分离，从而更容易在playbooks和角色之间共享handlers。

## 注意
- 通知handlers始终按照定义的顺序运行，而不是以notify语句中列出的顺序运行。使用listen的handlers也是如此。
- handlers名称和listen名称位于全局命名空间中。
- 如果两个handlers任务具有相同的名称，则只运行一个。
- 您无法通知在include内定义的处理程序。从Ansible 2.1开始，这确实有效，但是include必须是静态的。

## 刷新handlers
如果您想立即刷新所有handlers命令，可以执行以下操作：
```yaml
tasks:
   - shell: some tasks go here
   - meta: flush_handlers
   - shell: some other task
```
在上面的示例中，任何排队的handlers将在meta 到达语句时尽早处理。这是一个简单的案例，但有时可以派上用场。

## 提示和技巧
- 要检查剧本的语法，使用ansible-playbook与`--syntax-check`标志。这将通过解析器运行playbook文件，以确保其包含的文件，roles等没有语法问题。

- 要在运行之前查看哪个主机会受到剧本的影响，可以执行以下操作,该操作也能起到检查语法的效果：
```sh
ansible-playbook playbook.yml --list-hosts
```

- 如果你想查看成功模块及不成功模块的详细输出，请使用--verbose或 -v -vvv等。

- playbook执行的底部查看了解目标节点及其执行结果的统计。
