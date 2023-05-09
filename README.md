
如何使用？

1.安装docker
2.安装docker-compose

如果你是redhat，debian系列的ubuntu,debian,centos，
可以使用[docker_docker-compose-install.sh](./docker_docker-compose-install.sh)进行快速安装

```
git clone https://github.com/marksugar/docker-typecho-deploy.git
cd docker-typecho-deploy
bash docker_docker-compose-install.sh
```

如果docker-compose下载失败，请尝试Yum或者apt

## 安装php和nginx

默认的root数据库账号密码: root/PASSWORDABCD

默认创建了typecho库，用户名密码：typecho/PASSWORDABCD

```
  mysql:
    container_name: mysql
    image: registry.cn-hangzhou.aliyuncs.com/marksugar/mysql:8.0.29-debian
    restart: always
    environment:
      - MYSQL_ROOT_PASSWORD=root
      - MYSQL_ROOT_PASSWORD=PASSWORDABCD
      - MYSQL_DATABASE=typecho
      - MYSQL_USER=typecho
      - MYSQL_PASSWORD=PASSWORDABCD
```

默认的得到的ip如下

| id   | ip             | 所属应用 | 版本          |
| ---- | -------------- | -------- | ------------- |
| 1    | 172.200.10.100 | nginx    | 1.23.4        |
| 2    | 172.200.10.101 | php-fpm  | 7.4.33        |
| 3    | 172.200.10.102 | mysql    | 8.0.29-debian |

开始启动
```
docker-compose up -d
```
启动完成，浏览器访问88端口测试Phpinfo界面

## 更新typecho
此前，1.2.0被曝出漏洞，因此在wwwroot/typecho目录下已经下载好了typecho的1.2.1.RC版本，此时你只需要删除wwwroot/typecho/下的所有文件，替换到你想要的typecho版本文件解压极可。

需要更新，可以使用如下命令：
```
# 进入网站根目录
cd wwwroot/typecho
# 解压从github下载的zip包，解压完成删除包
unzip typecho.zip && rm -rf typecho.zip
```

或者，使用当前版本

你只需要cp wwwroot/typecho wwwroot/typecho-bak就完成了全局备份

## 配置nginx

你需要修改域名

在nginx/vhost下有

- typecho.conf
- typecho_443.conf.bak

0.http端口配置
- 80

```
server {
    listen       80;
   
    server_name  localhost;  # 你的域名
    # error_log /data/logs/error_nginx.log debug;
    access_log /data/logs/access.log upstream2;
    root /data/wwwroot/typecho;

    index index.html index.htm index.php default.html default.htm default.php;

    if (!-e $request_filename) {
      rewrite ^(.*)$ /index.php$1 last;
    }
    location ~ [^/]\.php(/|$){
      fastcgi_pass  172.200.10.101:9000;
      fastcgi_index index.php;
      include fastcgi.conf;
    }

    location ~* ^.+\.(ico|gif|jpg|jpeg|png)$ {
      access_log   off;
      expires      30d;
    }

    location ~* ^.+\.(css|js|txt|xml|swf|wav)$ {
      access_log   off;
      expires      24h;
    }

    location ~* ^.+\.(html|htm)$ {
      expires      1h;
    }
    location ~* ^.+\.(eot|ttf|otf|woff|svg)$ {
      access_log   off;
      expires max;
    }
    location ~ /\.{
      deny all;
    }
}
```
- 443

1.配置Https

只需要重命名

```
mv typecho_443.conf.bak typecho_443.conf
# 同时，你需要注释掉80端口，于是
mv typecho.conf typecho.conf.bak
```

但是你需要修改证书的位置，不需要修改/etc/nginx路径，因为这是映射容器内位置，需要在nginx/cert下存放证书并且修改配置文件名字极可

```
cd nginx/vhost/
```
- 443
```
server {
	listen 80;
    #  替换 你的域名
	server_name www.yuming.com yuming.com;
    if ($scheme = 'http' ) { rewrite ^(.*)$ https://$host$1 permanent; }
	index index.html index.htm index.php default.html default.htm default.php;
}
server {
    listen       443 ssl;
    #  替换 你的域名
    server_name   www.yuming.com yuming.com;
    # error_log /data/logs/error_nginx.log debug;
    access_log /data/logs/_443.log upstream2;
    root /data/wwwroot/typecho;
    index index.html index.htm index.php default.html default.htm default.php;

    # 访问限速。可以注释
    limit_conn conn_one 20;
    limit_conn perserver 20;
    limit_rate 100k;
    #limit_req zone=anti_spider burst=10 nodelay;
    limit_req zone=req_one burst=5 nodelay;

    index index.html index.htm index.php default.html default.htm default.php;

    # include fangzhuru.conf;
    #9557818_www.linuxea.com.pem 替换 你的域名证书
    ssl_certificate   /etc/nginx/cert/9557818_www.linuxea.com.pem; 
    ssl_certificate_key  /etc/nginx/cert/9557818_www.linuxea.com.key;


    if (!-e $request_filename) {
      rewrite ^(.*)$ /index.php$1 last;
    }
    location ~ [^/]\.php(/|$){
      fastcgi_pass  172.200.10.101:9000;
      fastcgi_index index.php;
      include fastcgi.conf;
    }

    location ~* ^.+\.(ico|gif|jpg|jpeg|png)$ {
      access_log   off;
      expires      30d;
    }

    location ~* ^.+\.(css|js|txt|xml|swf|wav)$ {
      access_log   off;
      expires      24h;
    }

    location ~* ^.+\.(html|htm)$ {
      expires      1h;
    }
    location ~* ^.+\.(eot|ttf|otf|woff|svg)$ {
      access_log   off;
      expires max;
    }
    location ~ /\.{
      deny all;
    }
}
```

## 数据库备份


备份

```
docker exec mysql sh -c 'exec mysqldump --all-databases -uroot -p"$MYSQL_ROOT_PASSWORD"' > /path/on/all-databases.sql
```

恢复

```
docker exec -i mysql sh -c 'exec mysql -uroot -p"$MYSQL_ROOT_PASSWORD"' < /path/on/all-databases.sql
```