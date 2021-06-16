#!/bin/bash
printf "Memory\t\tDisk\t\tCPU\n"
end=$((SECONDS+3600))
#while [ $SECONDS -lt $end ]; do
#MEMORY=$(free -m | awk 'NR==2{printf "%.2f\t\t", $3*100/$2 }')
MEMORY=$(free -m | awk 'NR==2{printf "%.2f\t",$2} NR==3{printf "%.2f", $3}' | awk 'NR==1{printf "%.2f\t\t",$2*100/$1}')
DISK=$(df -h | awk '$NF=="/"{printf "%s\t\t", $5}')
CPU=$(cat <(grep 'cpu ' /proc/stat) <(sleep 1 && grep 'cpu ' /proc/stat) | awk -v RS="" '{print ($13-$2+$15-$4)*100/($13-$2+$15-$4+$16-$5)}')
echo "$MEMORY$DISK$CPU"
#sleep 5
#done
