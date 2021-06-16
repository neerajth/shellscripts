#!/bin/bash
IPsCount=5
ipsArray="`awk '/xmlrpc/ {print $1,$2}' /var/log/apache2/insiderlifestyles.com-access.log | sort -k3nr | uniq -c`"
SAVEIFS=$IFS
#echo $ipsArray[0]
# Change IFS to new line.
IFS=$'\n'
ipsArray=($ipsArray[0])
# Restore IFS
IFS=$SAVEIFS
#echo {$ipsArray[@]}
#echo "====="
#echo ${ipsArray[@]}
echo "----------"
for ((i=0; i<${#ipsArray[@]}; ++i));
do
        strline=${ipsArray[$i]}
        arr=($strline)
        if [[ ${arr[0]} -gt $IPsCount ]]
        then
                revisedarray+=${arr[1]}' '${arr[2]}'|'
                echo $strline
                continue
        fi
done
echo "====="
echo $revisedarray

#ipsArray="`awk '/xmlrpc/ {print $1,$2}' /var/log/apache2/insiderlifestyles.com-access.log | sort -k3nr | sort -u`"
#echo "${ipsArray[0]}"
SAVEIFS=$IFS
# Change IFS to new line. 
IFS=$'|'
ipsArray=($revisedarray)
# Restore IFS
IFS=$SAVEIFS
SAVEIFSBEFORELOOP=$IFS
IFS=$' '
m=0
for ((i=0; i<${#ipsArray[@]}; ++i));
do
	strline=${ipsArray[$i]}
	arr=($strline)
	#echo ${arr[0]}	echo "====-------="
	if [[ ${arr[0]} =~ .*:.* ]]	#ignore ipv6
	then
  		continue
	fi
	first=$(echo ${arr[0]} | xargs)
	#first=${first/,/}
	SAVEIFS=$IFS
	# Change IFS to new line.
	IFS=$','
	first=($first)
	first=${first[0]}
	# Restore IFS
	IFS=$SAVEIFS

	second=$(echo ${arr[1]} | xargs)
	second=${second/,/}
	second=${second/'[0]'/}
	#echo "first : " ${first} ${#first} " second : " ${second} ${#second}
	#firstthree=$(echo ${first} | cut -d . -f 1,2,3)
	#secondthree=$(echo ${second} | cut -d . -f 1,2,3)
	firstfirst=$(echo ${first} | cut -d . -f 1)
        secondfirst=$(echo ${second} | cut -d . -f 1)
	if [[ ${firstfirst} != "10" && ${first} != "-" ]];
	then
		firstIPcheck=$(echo $first | /bin/egrep "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}")
		if [[ ${firstIPcheck} != "" ]];
		then
  			#echo "BLOCK 1st column IP : " ${first}
			blockIParray[$m]=${first}
			m=${m}+1
		fi
	elif [[ ${first} =~ "-" && ${secondfirst} != "10" ]];	#10.189.246
	then
		secondIPcheck=$(echo $second | /bin/egrep "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}")
		if [[ ${secondIPcheck} != "" ]]; 
		then
                        #echo "BLOCK 2nd column IP : " ${second}
			blockIParray[$m]=${second}
			m=${m}+1
                fi
	fi
done
# Restore IFS
IFS=$SAVEIFSBEFORELOOP
#echo ${#blockIParray[@]}
blockIPsarray=($(printf "%s\n" "${blockIParray[@]}" | sort -u))
echo "IPs to block logged in apache log..." 
echo ${blockIPsarray[@]}
echo "----"
echo "Blocked IPs in UFW.... "
blockedIPs=($(ufw status | awk '/DENY/ {print $3}'))
echo ${blockedIPs[@]}
#echo ${blockedIPs[2]}
#echo ${blockedIPs[@]} ${blockIPsarray[@]} | tr ' ' '\n' | sort | uniq -u
echo "--------"
blockIPs=$(echo ${blockedIPs[@]} ${blockIPsarray[@]} | sed 's/ /\n/g' | sort | uniq -d | xargs echo ${blockIPsarray[@]} | sed 's/ /\n/g' | sort | uniq -u)
echo "IPs to block - Blocked IPs : "
echo ${blockIPs[0]}
blockIPAdd=($blockIPs[0])
echo ${blockIPAdd[@]}
echo "count: "${#blockIPAdd[@]}
cloudserverlog="/var/www/vhosts/cloudserverlog.log"
for ((i=0; i<${#blockIPAdd[@]}; ++i));
do
	finalIP=${blockIPAdd[$i]}
	finalIP=${finalIP/'[0]'/}
	echo $finalIP
	if [[ $finalIP != "" ]]
	then
		ufwoutput=`ufw insert 1 deny from ${finalIP}`
		echo $(date +'%d-%m-%Y %T') ": UFW " ${finalIP} ":" ${ufwoutput} | tee -a $cloudserverlog	
		sleep 1
	fi
done
sudo service ufw restart

#following takes care of blocking IP in Rackspace loadbalancer via API
loadbalancerlog="/var/www/vhosts/rackspaceloadbalancerlog.log"
tokenjson=`curl -s https://identity.api.rackspacecloud.com/v2.0/tokens -X POST  -d '{"auth":{"RAX-KSKEY:apiKeyCredentials":{"username":"annexiolimited12","apiKey":"3fe3049273ca4f0a86fca818e89dbe76"}}}'  -H "Content-type: application/json" | python -m json.tool`
#echo ${tokenjson}
xauthtoken=`echo ${tokenjson} | jq '.access.token.id' | tr -d '"'`
#echo ${xauthtoken}
publicURL=`echo ${tokenjson} | jq '.access.serviceCatalog | .[1].endpoints | .[0].publicURL' | tr -d '"'`
#echo ${publicURL}

#echo ${publicURL}'/loadbalancers/180039/accesslist'

#get existing accesslist
curloutput=`curl -s https://lon.loadbalancers.api.rackspacecloud.com/v1.0/10049880/loadbalancers/180039/accesslist -X GET -H 'cache-control: no-cache' -H 'Content-type: application/json' -H 'x-auth-token: '${xauthtoken} | python -m json.tool | jq '.accessList[] | select(.type == "DENY") .address' | tr -d '"' | sed 's/{}//g'`
#echo $curloutput
lbblockedIPs=( $curloutput )
echo "--Rackspace loadbalancer blocked IPs--"
echo ${lbblockedIPs[@]}
blockIPs=$(echo ${lbblockedIPs[@]} ${blockIPsarray[@]} | sed 's/ /\n/g' | sort | uniq -d | xargs echo ${blockIPsarray[@]} | sed 's/ /\n/g' | sort | uniq -u)
echo "--IPs to block in Rackspace Loadbalancer--"
#echo ${blockIPs[0]}
blockIPss=($blockIPs[0])
#echo ${blockIPss[@]}
echo "Total : " ${#blockIPss[@]}
min=50
if [[ ${#blockIPss[@]} -gt $min ]]
then
	for ((i=0; i<$min; ++i));
	do
		blockIPssFinal[$i]=${blockIPss[$i]}
	done
else
	blockIPssFinal=($blockIPs[0])
fi
echo "Actual IPs to block in Rackspace this time..."
#echo ${blockIPssFinal[@]}
#echo ${#blockIPssFinal[@]}

#build json for Rackspace deny API
jsonrequest='{"accessList": ['
for((i=0; i<${#blockIPssFinal[@]}; ++i))
do
	finalIPtoblock=${blockIPssFinal[$i]}
        finalIPtoblock=${finalIPtoblock/'[0]'/}
        echo "one ip at a time: "$finalIPtoblock
        if [[ $finalIPtoblock != "" ]]
        then
		ipvalue+='{"address": "'$finalIPtoblock'","type": "DENY"}'
		curloutput=`curl -s https://lon.loadbalancers.api.rackspacecloud.com/v1.0/10049880/loadbalancers/180039/accesslist -X POST -H 'cache-control: no-cache' -H 'content-type: application/json' -H 'x-auth-token: '${xauthtoken} -d '{"accessList": [{"address": "'$finalIPtoblock'","type": "DENY"}]}'`
		echo {$curloutput}
		echo $(date +'%d-%m-%Y %T') ": Rackspace " ${finalIPtoblock} ":" {${curloutput}} | tee -a $loadbalancerlog
		sleep 5
	fi
	ipvalue+=","
done
exit;
#end......
