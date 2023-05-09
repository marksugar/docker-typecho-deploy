#!/bin/bash
DOCKER_PATH=/opt/kube/bin
mkdir -p ${DOCKER_PATH} /etc/docker/
curl -Lk4 https://mirrors.ustc.edu.cn/docker-ce/linux/static/stable/x86_64/docker-23.0.3.tgz | tar -xz --strip-components 1 -C ${DOCKER_PATH}
cp  ${DOCKER_PATH}/docker /usr/local/sbin/
cat >  /etc/systemd/system/docker.service << EOF
[Unit]
Description=Docker Application Container Engine
Documentation=http://docs.docker.io

[Service]
Environment="PATH=${DOCKER_PATH}:/bin:/sbin:/usr/bin:/usr/sbin"
ExecStart=${DOCKER_PATH}/dockerd
ExecStartPost=/sbin/iptables -I FORWARD -s 0.0.0.0/0 -j ACCEPT
ExecReload=/bin/kill -s HUP \$MAINPID
Restart=always
RestartSec=5
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
Delegate=yes
KillMode=process

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/docker/daemon.json << EOF
{
  "data-root": "/var/lib/docker",
  "exec-opts": ["native.cgroupdriver=systemd"],
  "insecure-registries": ["172.168.150.16"],
  "max-concurrent-downloads": 10,
  "live-restore": true,
  "log-driver": "json-file",
  "log-level": "warn",
  "log-opts": {
    "max-size": "50m",
    "max-file": "1"
    },
  "storage-driver": "overlay2",
  "registry-mirrors": ["https://registry.cn-zhangjiakou.aliyuncs.com"]
}
EOF
systemctl enable docker
systemctl start docker

#curl -L https://github.com/docker/compose/releases/download/v2.17.1/docker-compose-`uname -s`-`uname -m`  > /usr/local/sbin/docker-compose
curl -L https://ghdl.feizhuqwq.cf/https://github.com/docker/compose/releases/download/v2.17.0/docker-compose-linux-x86_64 -o /usr/local/sbin/docker-compose
chmod +x /usr/local/sbin/docker-compose

docker -v
docker-compose -v
