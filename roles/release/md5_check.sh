#!/bin/bash

cd /home/chentiangang/test/
ls * |xargs md5sum > /tmp/md5.txt

for i in $md5_list ;do
    result=`grep "$i" /tmp/md5.txt`
    if [ "$result" == "" ];then
        echo -e "\n$i 不存在\n"
    else
        echo $result
    fi
done
    
