#i!/bin/bash

# define globals variables
NC1='\033[0m'
RED='\033[0;31m'
BLUE='\033[1;34m'
YELLOW='\033[0;33m'
__file__=$(basename $0)
log_name=$(basename $__file__ .sh).log
CWD=$PWD
logdir=$CWD/reports
revision="`grep 'Rev:' README.md | grep -Eo '([0-9]+\.){2}[0-9]+'`"

function prerequisite
{
    # import rpm keys for os
    local modules=(dm_snapshot
                   dm_mirror
                   dm_thin_pool)
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY*
    for m in "${modules[@]}"
    do
        if [ $(lsmod | awk '{print $1}' | grep -ci $m) -ge 1 ]; then
            continue
        fi
        modprobe $m
    done

    # set timezone
    timedatectl set-timezone Asia/Shanghai
    timedatectl set-local-rtc 0

    # disable selinux
    setenforce 0
    sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config

    # disable firewalld
    systemctl disable firewalld
    systemctl stop firewalld
}

function chkcmd
{
    local pkg=$1
    if [ $(rpm -qa | grep -c $pkg) -eq 0 ]; then
        printf "\n%-40s [${RED} %s ${NC1}]\n" \
               " * package: $pkg " \
               " not found "
        return 1
    fi
    printf "\n${BLUE} %s ${NC1}\n" " --->, package: $pkg exist."
    return 0
}

function checknet
{
    local count=0
    local network=$1
    local USERNAME='admin'
    local PASSWORD='ZD7EdEpF9qCYpDpu'
    local proxy="http://${USERNAME}:${PASSWORD}@10.99.104.251:8081/"
    while true
    do
        if [ $(rpm -qa | egrep -ico "curl") -eq 0 ]; then
            ping $network -c 1 -q > /dev/null 2>&1
        else
            curl $network -c 1 -q > /dev/null 2>&1
        fi
        case $? in
            0)
                printf "%-40s [${BLUE} %s ${NC1}]\n" \
                       " * network " \
                       " success "
                return 0;;
            *)
                export {https,http}_proxy=$proxy

                # check fail count
                if [ $count -ge 4 ]; then
                    printf "%-40s [${RED} %s ${NC1}]\n" \
                           " * network " \
                           " disconnect "
                    exit 1
                fi;;
        esac
        count=$(( count + 1 ))
    done
}

function installserverfail
{
    if [ ! -f /etc/yum.repos.d/CentOS-Base.repo.bak ]; then
        cp -rp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
    fi
    wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
    sed -i  's/$releasever/7/g' /etc/yum.repos.d/CentOS-Base.repo
    yum repolist
    yum clean all
    rpm --rebuilddb
    yum -y update
    package-cleanup --dupes > /dev/null 2>&1
    package-cleanup --cleandupes > /dev/null 2>&1
    sed -i s',http://mirrors.cloud.aliyuncs.com,http://mirrors.aliyun.com,'g /etc/yum.repos.d/CentOS-Base.repo
    yum clean all
    yum makecache
}


function installreq
{
    local packages=(centos-release-gluster
                    glusterfs
                    glusterfs-server
                    glusterfs-fuse
                    glusterfs-rdma
                    glusterfs-cli)

    for p in "${packages[@]}"
    do
        if [ $(rpm -qa | egrep -ci "$p") -eq 0 ]; then
            case "$p" in
                "centos-release-gluster")
                    yum install -y $p
                    chkcmd $p
                    if [ $? -ne 0 ]; then
                        yum --enablerepo=epel install $p -y
                    fi
                    ;;
                "glusterfs")
                    yum install -y $p
                    chkcmd $p
                    if [ $? -ne 0 ]; then
                        yum --enablerepo=epel install $p -y
                    fi
                    ;;
                "glusterfs-server")
                    yum install -y $p
                    chkcmd $p
                    if [ $? -ne 0 ]; then
                        installserverfail
                        yum install -y $p || yum --enablerepo=epel install $p -y
                        chkcmd $p
                    fi
                    ;;
                "glusterfs-fuse")
                    yum install -y $p
                    chkcmd $p
                    if [ $? -ne 0 ]; then
                        yum --enablerepo=epel install $p -y
                    fi
                    ;;
                "glusterfs-rdma")
                    yum install -y $p
                    chkcmd $p
                    if [ $? -ne 0 ]; then
                        yum --enablerepo=epel install $p -y
                    fi
                    ;;
                "glusterfs-cli")
                    yum install -y $p
                    chkcmd $p
                    if [ $? -ne 0 ]; then
                        yum --enablerepo=epel install $p -y
                    fi
                    ;;
            esac
        else
            printf "%-40s [${YELLOW} %s ${NC1}]\n" \
                   " * package: $p " \
                   " exist "
            continue
        fi
    done
}

function startglusterfs
{
    systemctl enable glusterd.service
    systemctl start glusterd.service

    local state=$(systemctl list-unit-files --state=enabled \
                  | grep glusterd.service \
                  | awk '{print $2}')

    if [ "$state" != "enabled" ]; then
        printf "%-40s [${RED} %s ${NC1}]\n" \
               " * daemon: glusterd.service " \
               " not found "
        exit 1
    fi

    printf "%-40s [${YELLOW} %s ${NC1}]\n" \
           " * daemon: glusterd.service " \
           " success "
}

function main
{
    # confirmed the network status
    checknet www.google.com

    # before install operation
    prerequisite

    # install glusterfs service
    installreq

    # startup glusterfs daemon
    startglusterfs
}

main | tee ${logdir}/${log_name}
