#!/bin/bash
logfile="/root/ginstall/ginstall.log"

log(){
	echo $1;
	echo $1>>$logfile;
	exit;
}


ready(){
    {
        yum install -y wget;
	yum groupinstall "Development Tools" -y;
        yum install -y zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel libffi-devel gcc make;
    }||{
    	log "yum install is failed~!";
    }
}

createbasedir(){
	if [ ! -d /root/ginstall  ];then
		mkdir /root/ginstall;
	else
		rm -rf /root/ginstall/*;
		log "/root/ginstall is exist~! now will clear /root/ginstall";
	fi		
}

createworkdir(){
	{
		wget http://www.irecode.cn/greenhost.tar -O /root/ginstall/greenhost.tar&&tar -xvf /root/ginstall/greenhost.tar -C /;
	}||{
		log "Download or Tar fail~!";
	}
}

installpython3_make(){
	{
		wget https://www.python.org/ftp/python/3.7.2/Python-3.7.2.tgz -O /root/ginstall/Python-3.7.2.tgz&&cd /root/ginstall/&&tar -xvf Python-3.7.2.tgz&&cd /root/ginstall/Python-3.7.2/&&./configure --prefix=/greenhost/python3  --enable-optimizations && make && make install;
	}||{
		log "Python3 install fail~!";
	}
}

installpython3(){
	{
		yum install epel-release -y&&yum install https://centos7.iuscommunity.org/ius-release.rpm -y&&yum install python36u -y&&yum install python36u-pip -y;
		ln -s /bin/python3.6 /bin/python3;
		ln -s /bin/pip3.6 /bin/pip3;


	}||{
		log "Python3 install fail~!";
	}
}

installpip(){
	{
		curl https://bootstrap.pypa.io/get-pip.py -o /root/ginstall/get-pip.py&&python /root/ginstall/get-pip.py&&/greenhost/python3/bin/pip3 install --upgrade pip&&echo "export PATH=/greenhost/python3/bin:\$PATH">>/etc/profile && source /etc/profile;
	}||{
		log "pip install or path change error;";
	}
}

installvsftpd(){
	{
		yum install vsftpd -y;
		if [ ! -d "/etc/vsftpd/vusers"  ];then
			mkdir /etc/vsftpd/vusers;
		else
			rm -rf /etc/vsftpd/vusers;
		fi
		if [ ! -d "/home/vhost" ];then
			useradd -s /sbin/nologin -d /home/vhost vuser
		else
			rm -rf /home/vhost
			useradd -s /sbin/nologin -d /home/vhost vuser
		fi
		chmod go+rx /home/vhost;
		chmod a-w -R /home/vhost;
		\cp /greenhost/vsftpd.conf /etc/vsftpd/vsftpd.conf -f;
		stemctl enable vsftpd.service;
		systemctl start vsftpd.service;

	}||{
		log "vsftpd install faild~!";
	}
}

installmysql(){
	{
		yum install mariadb mariadb-server mariadb-devel pam-devel -y;
		systemctl enable mariadb.service;
		systemctl start mariadb.service;
		wget https://jaist.dl.sourceforge.net/project/pam-mysql/pam-mysql/0.7RC1/pam_mysql-0.7RC1.tar.gz -O /root/ginstall/pam_mysql-0.7RC1.tar.gz;
		cd /root/ginstall/
		tar -xvf pam_mysql-0.7RC1.tar.gz;
		cd /root/ginstall/pam_mysql-0.7RC1;
		./configure --with-mysql=/usr --with-pam=/usr --with-pam-mods-dir=/usr/lib64/security && make && make install;
		mysql -u root  -e 'drop database test;';
		mysql -u root -e 'create database greenhost;';
		mysql -u root -e 'delete from mysql.user where User="root" and Host="%";';
		mysql -u root -e 'FLUSH PRIVILEGES;'
		read  -p "请输入MYSQL的root密码:" password
		mysqladmin -u root password $password;
		sed -i "s/{{password}}/$password/g" /greenhost/manage/manage/settings.py
		/usr/bin/python3 /greenhost/manage/manage.py makemigrations&&/usr/bin/python3 /greenhost/manage/manage.py migrate&&/usr/bin/python3 /greenhost/manage/manage.py createsuperuser
		echo -e "auth required /lib64/security/pam_mysql.so user=root passwd="$password" host=localhost db=greenhost table=sitemanage_member usercolumn=username passwdcolumn=ftppassword crypt=0\naccount required /lib64/security/pam_mysql.so user=root passwd="$password" host=localhost db=greenhost table=sitemanage_member usercolumn=username passwdcolumn=ftppassword crypt=0" >> /etc/pam.d/vsftpd.mysql;

	}||{
		log "mysql install failed~!";
	}
}

uwsgiinstall(){
	{
		/usr/bin/pip3 install  -r  /greenhost/requirements.txt;
		if [ ! -d "/etc/uwsgi/" ] ;then
		mkdir /etc/uwsgi
		fi
		nohup uwsgi --emperor /etc/uwsgi/&
		echo "uwsgi --emperor /etc/uwsgi/&" >> /etc/rc.local;

	}||{
		log "uwsgi install failed~!";
	}
}

nginxinstall(){
	{
		\cp -f /greenhost/nginx.repo /etc/yum.repos.d/nginx.repo;
		yum install nginx -y;
		systemctl enable nginx.service;
		systemctl start nginx.service;

	}||{
		log "nginx install failed~!";
	}
}

firewallset(){
	{
		firewall-cmd --zone=public --add-port=80/tcp --permanent;
		firewall-cmd --zone=public --add-port=8000/tcp --permanent;
		firewall-cmd --zone=public --add-port=21/tcp --permanent;
		firewall-cmd --reload;
	}||{
		log "firewalld setting is failed~!";
	}
}

main(){
	ready&&createbasedir&&createworkdir&&installpython3&&installvsftpd&&uwsgiinstall&&installmysql&&nginxinstall&&firewallset&&echo "ginstall is finished~!"
}
main
