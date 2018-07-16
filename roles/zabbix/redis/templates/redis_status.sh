#!/bin/bash
# redis minitor scripts

# redis auth password
PASSWD=""

# redis ip addr
REDIS_IP="{{ ansible_eth0.ipv4.address }}"

# redis port
REDIS_PORT="6380"

# redis command
CMD="/usr/local/redis/bin/redis-cli -h $REDIS_IP -p $REDIS_PORT -x"

# monitor item
ITEM="$1"

# info cache file
CACHEFILE="/tmp/redis_${REDIS_PORT}_status.txt"

if [ `/usr/local/redis/bin/redis-cli -h $REDIS_IP -p $REDIS_PORT PING ` != "PONG" ];then
    echo "redis $REDIS_PORT is not running."
    exit 1
fi

if [ $# != 1 ];then
    echo "Please input  paremater."
    exit 1
else
    if [ -s $CACHEFILE ];then
        TIMEFLM=`stat -c %Y $CACHEFILE`
        TIMENOW=`date +%s`
        if [ `expr $TIMENOW - $TIMEFLM` -gt 60 ];then
            rm -f $CACHEFILE
            echo -en "AUTH $PASSWD\r\ninfo\r\n" | $CMD |sed -r '/db0:keys/s#[:,]#\n#g' > $CACHEFILE
        fi
    else
        echo -en "AUTH $PASSWD\r\ninfo\r\n" | $CMD |sed -r '/db0:keys/s#[:,]#\n#g' > $CACHEFILE
    fi
    awk -F "[:=]" -v v="$ITEM" '$1 == v {print $2}' $CACHEFILE
    exit 0
fi
