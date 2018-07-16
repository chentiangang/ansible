#!/bin/bash
# Java Status Minitor Scripts
# Author: chentiangang
# Time: 2018/3/10

HOST=`hostname`

# 检查java进程是否为1个
if [ `pgrep java |wc -l` != 1 ];then
    echo "java process unusual."
    exit 1
fi

PID=$(pgrep java)

# Jstat Command Options
JSTAT_OPTS="$1"

# 监控数据临时文件
CACHEFILE="/tmp/$HOST-java-${JSTAT_OPTS}.txt"

# 监控项取值
ITEM=$2

# 格式化监控数据
format_monitor_data(){
    sed -nr '1s#[ ]+#\n#gp' $CACHEFILE | awk '$1 != ""' > /tmp/1.txt
    sed -nr '2s#[ ]+#\n#gp' $CACHEFILE | awk '$1 != ""' > /tmp/2.txt
    paste -d " " /tmp/1.txt /tmp/2.txt > $CACHEFILE
    rm -f /tmp/1.txt /tmp/2.txt
}

if [ $# != 2 ];then
    echo "Please input two paremater."
    exit 1
else
    if [ -s $CACHEFILE ];then
        TIMEFLM=`stat -c %Y $CACHEFILE`
        TIMENOW=`date +%s`
        if [ `expr $TIMENOW - $TIMEFLM` -gt 90 ];then
            rm -f $CACHEFILE
            /application/jdk/bin/jstat -${JSTAT_OPTS} $PID  > $CACHEFILE
            format_monitor_data
        fi
    else
        /application/jdk/bin/jstat -${JSTAT_OPTS} $PID  > $CACHEFILE
        format_monitor_data
    fi
    awk -v v="$ITEM" '$1 == v {print $2}' $CACHEFILE
    exit 0
fi
