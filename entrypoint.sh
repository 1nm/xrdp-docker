#/bin/sh

USERNAME=${USERNAME:-xrdp}
PASSWORD=${PASSWORD:-docker}
USER_ID=${USER_ID:-1000}
GROUP_ID=${GROUP_ID:-${USER_ID}}
LOGIN_SHELL=${LOGIN_SHELL:-/bin/bash}

sed 's|\([^:]*\):.*|\1|' /etc/passwd | grep $USERNAME > /dev/null

if [ $? -ne 0 ]; then
    echo "Creating user ${USERNAME} ..."
    groupadd -g ${GROUP_ID} ${USERNAME}
    useradd -G sudo -u ${USER_ID} -g ${GROUP_ID} -m -s $LOGIN_SHELL ${USERNAME}
    echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    echo "${USERNAME}:${PASSWORD}" | chpasswd
fi

echo "Starting xrdp ..."
rm -fr /var/run/xrdp*
/usr/sbin/xrdp-sesman
/usr/sbin/xrdp

echo "xrdp started"
tail -f /dev/null
