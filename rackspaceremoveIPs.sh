#!/bin/bash
#following takes care of blocking IP in Rackspace loadbalancer via API
loadbalancerlog="/var/www/vhosts/loadbalancerRemovelog.log"
tokenjson=`curl -s https://identity.api.rackspacecloud.com/v2.0/tokens -X POST  -d '{"auth":{"RAX-KSKEY:apiKeyCredentials":{"username":"annexiolimited12","apiKey":"3fe3049273ca4f0a86fca818e89dbe76"}}}'  -H "Content-type: application/json" | python -m json.tool`
#echo ${tokenjson}
xauthtoken=`echo ${tokenjson} | jq '.access.token.id' | tr -d '"'`
#echo ${xauthtoken}
#publicURL=`echo ${tokenjson} | jq '.access.serviceCatalog | .[1].endpoints | .[0].publicURL' | tr -d '"'`
#echo ${publicURL}
#echo ${publicURL}'/loadbalancers/180039/accesslist'
#remove IPs from load balancer
curloutput=`curl -s https://lon.loadbalancers.api.rackspacecloud.com/v1.0/10049880/loadbalancers/180039/accesslist -X DELETE -H 'cache-control: no-cache' -H 'Content-type: application/json' -H 'x-auth-token: '${xauthtoken} | python -m json.tool`
echo "Delete response: "
echo $curloutput
echo $(date +'%d-%m-%Y %T') ": Rackspace accesslist removed." | tee -a $loadbalancerlog
