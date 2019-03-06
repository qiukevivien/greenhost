描述：
	一个基于django的，包含nginx/ftp/python/django/sqlite继承环境。后台新建用户的同时，可以建立相应的FTP用户，配置相应的UWSGI，以及nginx服务。

	OS：Centos 7.x,
	前期准备：关闭SELINX,更新系统。
	执行： curl https://github.com/qiukevivien/greenhost/blob/master/ghinstall.sh
		chmod +x ./ghinstall.sh
		./ghinstall.sh
	自动安装内容包括:vsftpd,mariadb,python36,pip3,nginx以及基于requirements.txt的pypi包，同时下载程序代码(greenhost.tar),配置基于mysql认证的vsftpd auth,按照django项目-greenhost新建相应的mariadb数据库和django/admin管理员密码(安装过程中需要手工输入mariadb管理员密码和django/admin管理员信息和密码)；
	目前没有完成自动运行管理程序，需要手工执行或者配置到nginx中去。请到相应的目录(/greenhost/)下自己启动项目，配置端口。
	
	
	
	

