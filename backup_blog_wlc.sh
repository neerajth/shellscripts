#!/bin/bash
logfile="/var/www/vhosts/gitdbbackup.log"
/usr/bin/mysqldump -h134.213.54.176 -uwlcbloglocal -p'igkhpek439h36fdhremote' wlcblog_local | gzip > /var/www/vhosts/backups/rackspace/blog.worldlotteryclub.com/db/blog_wlc-`date +\%d\%m_\%Y_\%H\%M`.sql.gz
#echo "`rsync -vuar /var/www/vhosts/insiderlifestyles.com/ /var/www/vhosts/backups/insiderlifestyles/site/`" | tee -a $logfile
cd /var/www/vhosts/backups/rackspace/
/usr/bin/git add .
/usr/bin/git commit -m "auto gitpush of zipped blog.wlc database"
echo "`date +\%d\%m_\%Y_\%H\%M` db zipped and pushed" | tee -a $logfile
echo "`/usr/bin/git push https://neerajannexio:Welcome1234@github.com/AnnexioLtd/rackspace.git`" | tee -a $logfile
