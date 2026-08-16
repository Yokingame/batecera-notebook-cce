#!/bin/bash
LOG=/userdata/system/custom.log
echo "custom.sh rodou em $(date) (PID \$\$)" >> $LOG
echo "passo1-inicio $(date)" >> $LOG
sleep 5
echo "passo2-pos-sleep $(date)" >> $LOG
for name in lircd sixad-bin sixad bluetoothd rngd ntpd avahi-daemon thd; do
    killall -9 "$name" 2>>$LOG
done
echo "passo3-pos-killall $(date)" >> $LOG
grep -qs 'swapfile' /proc/swaps || swapon /userdata/swapfile 2>>$LOG
sysctl -w vm.swappiness=60 >> $LOG 2>&1
amixer set Master mute >> $LOG 2>&1
echo "custom.sh terminou em $(date)" >> $LOG