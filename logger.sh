#!/usr/bin/env bash

LC_NUMERIC="en_US.UTF-8"

SCRIPTPATH=$(dirname $0)
FILE=$SCRIPTPATH/$0.csv

START_PORT=5200
END_PORT=5209
HOST[0]=speedtest.wtnet.de
HOST[1]=ping.online.net
HOST[2]=ping6.online.net
HOST[3]=bouygues.testdebit.info
HOST[4]=ping-ams1.online.net


printf '"%s",' "$(date +'%FT%T%:z')" >> $FILE

for TYPE in "download" "upload"; do
    PORT=$START_PORT
    HOST_INDEX=0
    while true; do
        CMD="iperf3 --client ${HOST[$HOST_INDEX]} --port $PORT --parallel 10 --version4 --interval 0 --connect-timeout 50 --json"
        if [ "$TYPE" = "download" ]; then
            CMD="$CMD --reverse"
        fi
        BITS=$(jq -r '.end.sum_received.bits_per_second' <<< $($CMD))
        if [ "$BITS" != "null" ]; then
            break
        fi
        if [ $(($HOST_INDEX + 1)) -ge ${#HOST[@]} ]; then
            break
        fi
        let PORT++
        if [ $PORT -gt $END_PORT ]; then
            let HOST_INDEX++
            PORT=$START_PORT
        fi
    done
    printf '"%.3f",' "$(awk '{print $0 / 1000000}' <<< $BITS)" >> $FILE
    printf '"%s"' "${HOST[$HOST_INDEX]}:$PORT" >> $FILE
    if [ "$TYPE" = "download" ]; then
        printf ',' >> $FILE
    fi
done

printf '\n' >> $FILE
