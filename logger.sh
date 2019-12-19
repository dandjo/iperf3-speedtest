#!/usr/bin/env bash

LC_NUMERIC="en_US.UTF-8"

LOGFILE=/var/log/iperf3.csv

HOSTS[0]=speedtest.serverius.net:5002-5002
HOSTS[1]=speedtest.wtnet.de:5200-5209
HOSTS[2]=ping.online.net:5200-5209
HOSTS[3]=bouygues.testdebit.info:5200-5209
HOSTS[4]=bouygues.iperf.fr:5200-5209
HOSTS[5]=ping-ams1.online.net:5200-5209

DURATION_DOWNLOAD=30
DURATION_UPLOAD=10
PARALLEL_CONNECTIONS=10

killall -9 iperf3 1>/dev/null 2>&1

printf '"%s",' "$(date +'%FT%T%:z')" >> $LOGFILE

for TYPE in "download" "upload"; do
    HOST_INDEX=0
    while true; do
        HOSTS_CONFIG=${HOSTS[$HOST_INDEX]}
        HOSTS_AND_PORTS=(${HOSTS_CONFIG//:/ })
        HOST=${HOSTS_AND_PORTS[0]}
        PORT_RANGE=${HOSTS_AND_PORTS[1]}
        START_END_PORT=(${PORT_RANGE//-/ })
        START_PORT=${START_END_PORT[0]}
        END_PORT=${START_END_PORT[1]}
        PORT=$START_PORT
        while true; do
            CMD="iperf3 --client $HOST --port $PORT --parallel $PARALLEL_CONNECTIONS --interval 0 --json"
            if [ "$TYPE" = "download" ]; then
                CMD="$CMD --reverse --time $DURATION_DOWNLOAD"
            fi
            if [ "$TYPE" = "upload" ]; then
                CMD="$CMD --time $DURATION_UPLOAD"
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
    printf '"%.3f",' "$(awk '{print $0 / 1000000}' <<< $BITS)" >> $LOGFILE
    printf '"%s"' "$HOST:$PORT" >> $LOGFILE
    if [ "$TYPE" = "download" ]; then
        printf ',' >> $LOGFILE
    fi
done

printf '\n' >> $LOGFILE
