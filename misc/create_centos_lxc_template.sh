#!/usr/bin/env bash
cd $(dirname $0)
apt-get install -y yum
lxc-create -t centos -n centos -- -R 7
sed -i -re "s/lxc.network.link =.*/lxc.network.link = copslxcbr/g" /var/lib/lxc/centos/config 
sed -i -re "s/lxc.utsname =.*/lxc.utsname = centos/g" /var/lib/lxc/centos/config 
bin/ansible-playbook-wrapper -c local -i localhost, \
    /srv/corpusops/corpusops.bootstrap/roles/corpusops.lxc_create/role.yml -e "lxc_container_name=copscentos from_container=centos"
