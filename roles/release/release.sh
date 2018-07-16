#!/bin/bash

# prod
release_yml="/etc/ansible/release.yml"
upstream="/etc/ansible/roles/config/lb-nginx/files/conf.d/upstream/*api_upstream.conf"
lb_yml="/etc/ansible/lb-server.yml"

# debug
#release_yml="/root/test_deploy/debug.yml"
#upstream="/root/test_deploy/shop_api_upstream.conf"
#lb_yml="/root/test_deploy/lb-server.yml"

disrupt="----------------------------------------------------"

#ansible-playbook $release_yml --extra-vars "host=$1" --list-hosts | awk 'NR>6' > /tmp/release.temp

echo "$hosts_group"  > /tmp/release.temp
cat /tmp/release.temp

check(){
    if [  $? != 0 ];then error "遇到错误，中断执行";fi
}

error(){
    printf "ERROR: $1\n"
    exit 1
}

info(){
    printf "INFO: $1\n"
}

waiting(){
    printf "Waiting "
    for null in `seq 1 $1`;do printf '.';sleep 1;done
    printf "\n"
}

node_remove(){
    info " $list Nginx 移出集群 $disrupt"
    sed -r -i "/$list/s@(.*)@#\1@g" $upstream
    ansible-playbook $lb_yml --skip-tags "release-skip"
}

node_add(){
    info " $list Nginx 加入集群 $disrupt"
    sed -r -i "/$list/s@#(.*)@\1@g" $upstream
    ansible-playbook $lb_yml --skip-tags "release-skip"
}

count=1
for list in  `cat /tmp/release.temp`;do
    case "$list" in
        *web-api*)
             node_remove
             check
             waiting 5
             ansible-playbook $release_yml --extra-vars "host=$list" 
             check
             waiting 15
             node_add
             ;;
        *inner-api*)
             ansible-playbook $release_yml --extra-vars "host=$list"
             waiting 15
             ;;
        *)
             ansible-playbook $release_yml --extra-vars "host=$list"
             ;;
    esac
    check
    info "第${count}个服务: $list successful $disrupt"
    ((count=count+1))
done

echo "主机列表: "
cat /tmp/release.temp
exit
