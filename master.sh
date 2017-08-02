#!/bin/bash
#部署yum源
export PATH=$PATH
PWD=`pwd`
MysqlName="root"
Mysqlpasswd="root@123"
Yumdir=/etc/yum.repos.d
NodeName=`cat /etc/hosts | grep -v "localhost" | awk '/./ {print $2}' | head -n1`
#mount 
#	for i in `ls $Yumdir/`;do mv $Yumdir/$i $Yumdir/$i.bak;done
	rm -f $Yumdir/*
	mount -o loop $PWD/file/centos7.iso /mnt
	echo "[iso]" >> $Yumdir/iso.repo
	echo "name=iso" >> $Yumdir/iso.repo
	echo "baseurl=file:///mnt" >> $Yumdir/iso.repo
	echo "enabled=1" >> $Yumdir/iso.repo
	echo "gpgcheck=0" >> $Yumdir/iso.repo
	yum install httpd createrepo -y >/dev/null 2>>err.log
	systemctl start httpd
	systemctl enable httpd
	umount /mnt
	mkdir /var/www/html/yum
	mount -o loop $PWD/file/centos7.iso /var/www/html/yum
	mv $Yumdir/iso.repo $Yumdir/iso.repo.bak
	cp $PWD/file/yum.repo $Yumdir/
	cp -rp $PWD/file/cm /var/www/html/		#配置cm的yum源
	cp -rp $PWD/file/cdh /var/www/html/
	cp $PWD/file/cm.repo $Yumdir/
	cd /var/www/html/cm
	createrepo .
	echo "success mount......"
	cd /root/cm
#mysql install
	yum install mariadb-server -y >/dev/null 2>>err.log
	echo "y" | cp -b $PWD/file/my.cnf.mariadb /etc/my.cnf	
	systemctl start mariadb
	systemctl enable mariadb
	mysqladmin -u $MysqlName password "$Mysqlpasswd"
	mysql -u$MysqlName -p"$Mysqlpasswd" -e " 
	create user 'amon'@'%' identified by '$Mysqlpasswd';
	create database amon DEFAULT CHARACTER SET utf8;
	grant all privileges on amon.* to 'amon'@'%';
	create user 'rman'@'%' identified by '$Mysqlpasswd';
	create database rman DEFAULT CHARACTER SET utf8;
	grant all privileges on rman.* to 'rman'@'%';
	create user 'oozie'@'%' identified by '$Mysqlpasswd';
	create database oozie DEFAULT CHARACTER SET utf8;
	grant all privileges on oozie.* to 'oozie'@'%';
	create user 'hive'@'%' identified by '$Mysqlpasswd';
	create database hive DEFAULT CHARACTER SET utf8;
	grant all privileges on hive.* to 'hive'@'%';
	create user 'nav'@'%' identified by '$Mysqlpasswd';
	create database nav DEFAULT CHARACTER SET utf8;
	grant all privileges on nav.* to 'nav'@'%';
	create user 'navms'@'%' identified by '$Mysqlpasswd';
	create database navms DEFAULT CHARACTER SET utf8;
	grant all privileges on navms.* to 'navms'@'%';
	create user 'sentry'@'%' identified by '$Mysqlpasswd';
	create database sentry DEFAULT CHARACTER SET utf8;
	grant all privileges on sentry.* to 'sentry'@'%';
	create user 'hue'@'%' identified by '$Mysqlpasswd';
	create database hue DEFAULT CHARACTER SET utf8;
	grant all privileges on hue.* to 'hue'@'%';
	grant all privileges on hue.* to 'amon'@'$NodeName' identified by '$Mysqlpasswd';
	grant all privileges on hue.* to 'rman'@'$NodeName' identified by '$Mysqlpasswd';
	grant all privileges on hue.* to 'oozie'@'$NodeName' identified by '$Mysqlpasswd';
	grant all privileges on hue.* to 'hive'@'$NodeName' identified by '$Mysqlpasswd';
	grant all privileges on hue.* to 'sentry'@'$NodeName' identified by '$Mysqlpasswd';
	grant all privileges on hue.* to 'hue'@'$NodeName' identified by '$Mysqlpasswd';
	grant all privileges on hue.* to 'nav'@'$NodeName' identified by '$Mysqlpasswd';
	grant all privileges on hue.* to 'navms'@'$NodeName' identified by '$Mysqlpasswd';
	flush privileges;"
	echo "mysql install success"


#krb5 install
	yum install krb5* -y >/dev/null 2>>err.log
	echo "y" | cp -b $PWD/file/krb5.conf /etc/
	echo "y" | cp -b $PWD/file/kdc.conf /var/kerberos/krb5kdc
	echo "y" | cp -b $PWD/file/kadm5.acl /var/kerberos/krb5kdc
	kdb5_util create -s
	echo "wait............"
	sleep 300
	if [ $? -eq 0 ];then
		echo "success"
		systemctl start krb5kdc
		systemctl enable krb5kdc
	 	systemctl start kadmin
		systemctl enable kadmin
	else
		echo "fail"
		echo "请手动设置"
	fi
	echo "管理员账号请手动添加"
#jdk install
	yum -y install oracle-j2sdk1.7 >/dev/null 2>>err.log
	echo "export JAVA_HOME=/usr/java/jdk1.7.0_67-cloudera" >> /etc/profile
	echo "export JRE_HOME=/usr/java/jdk1.7.0_67-cloudera/jre" >> /etc/profile
	cp $PWD/file/mysql-connector-java-5.1.34.jar /usr/java/jdk1.7.0_67-cloudera/lib
	ln -s /usr/java/jdk1.7.0_67-cloudera/lib/mysql-connector-java-5.1.34.jar /usr/java/jdk1.7.0_67-cloudera/lib/mysql-connector-java.jar
	if [ ! -d "/usr/share/java" ];then
		mkdir -p /usr/share/java
		cp $PWD/file/mysql-connector-java-5.1.34.jar /usr/share/java
	else
	   	cp $PWD/file/mysql-connector-java-5.1.34.jar /usr/share/java
	fi
	echo "jdk install success"
#ntp install
	yum install ntp -y >/dev/null 2>>err.log
	cp $PWD/file/ntp.conf.master /etc/ntp.conf
	systemctl start ntpd
	systemctl enable ntpd
#cm install
	yum -y install cloudera* >/dev/null 2>>err.log
#	yum -y install mysql-connector-java >/dev/null 2>>err.log
	cp $PWD/file/mysql-connector-java-5.1.34.jar /usr/share/cmf/lib/
	/usr/share/cmf/schema/scm_prepare_database.sh mysql cm -hlocalhost -uroot -proot@123 --scm-host localhost scm scm scm
	sed -i "3c server_host=$NodeName" /etc/cloudera-scm-agent/config.ini
	/etc/init.d/cloudera-scm-agent start
	/etc/init.d/cloudera-scm-server start
	yum install expect -y >/dev/null 2>>err.log