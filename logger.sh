#!/usr/bin/env bash

LC_NUMERIC="en_US.UTF-8"

SCRIPTPATH=$(dirname $0)
FILE=$SCRIPTPATH/iperf3.csv

HOSTS[0]=speedtest.serverius.net:5002-5002
HOSTS[1]=speedtest.wtnet.de:5200-5209
HOSTS[2]=ping.online.net:5200-5209
HOSTS[3]=bouygues.testdebit.info:5200-5209
HOSTS[4]=bouygues.iperf.fr:5200-5209
HOSTS[5]=ping-ams1.online.net:5200-5209

killall -9 iperf3

printf '"%s",' "$(date +'%FT%T%:z')" >> $FILE

for TYPE in "download" "upload"; do
    HOST_INDEX=0
    while true; do
        HOST_CONFIG=${HOSTS[$HOST_INDEX]}
        HOST_AND_PORTS=(${HOST_CONFIG//:/ })
        HOST=${HOST_AND_PORTS[0]}
        PORT_RANGE=${HOST_AND_PORTS[1]}
        START_AND_ENDPORT=(${PORT_RANGE//-/ })
        START_PORT=${START_AND_ENDPORT[0]}
        END_PORT=${START_AND_ENDPORT[1]}
        PORT=$START_PORT
        while true; do
            CMD="iperf3 --client $HOST --port $PORT --parallel 10 --version4 --interval 0 --json"
            if [ "$TYPE" = "download" ]; then
                CMD="$CMD --reverse --time 60"
            fi
            if [ "$TYPE" = "upload" ]; then
                CMD="$CMD --time 30"
            fi
            BITS=$(jq -r '.end.sum_received.bits_per_second' <<< $($CMD))
            if [ "$BITS" != "null" ]; then
                break 2
            fi
            let PORT++
            if [ $PORT -gt $END_PORT ]; then
                break 1
            fi
        done
        let HOST_INDEX++
        if [ $HOST_INDEX -ge ${#HOSTS[@]} ]; then
            break 1
        fi
    done
    printf '"%.3f",' "$(awk '{print $0 / 1000000}' <<< $BITS)" >> $FILE
    printf '"%s"' "$HOST:$PORT" >> $FILE
    if [ "$TYPE" = "download" ]; then
        printf ',' >> $FILE
    fi
done

printf '\n' >> $FILE
