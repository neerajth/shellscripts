#!/bin/bash
removeips="`ufw status | grep 'DENY' | awk '{print $3}'`"
echo ${removeips[0]}
removeipsarr=(${removeips[0]})
echo ${#removeipsarr[@]}
for ((i=0; i<${#removeipsarr[@]}; ++i));
do
ufw delete deny from ${removeipsarr[$i]}
#sleep 2
done
