#/bin/sh

USERNAME=${USERNAME:-dev}
PASSWORD=${PASSWORD:-docker}
USER_ID=${USER_ID:-1000}
GROUP_ID=${GROUP_ID:-${USER_ID}}
LOGIN_SHELL=${LOGIN_SHELL:-/bin/bash}

sed 's|\([^:]*\):.*|\1|' /etc/passwd | grep $USERNAME > /dev/null

if [ $? -ne 0 ]; then
    echo "Creating user ${USERNAME}..."
    # dev user doesn't exist - create one
    groupadd -g ${GROUP_ID} ${USERNAME}
    useradd -G sudo -u ${USER_ID} -g ${GROUP_ID} -m -s $LOGIN_SHELL ${USERNAME}
    echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    echo "${USERNAME}:${PASSWORD}" | chpasswd
fi

echo "Starting xrdp..."
rm -fr /var/run/xrdp*
/usr/local/sbin/xrdp-sesman
/usr/local/sbin/xrdp

echo "Done.  System is ready."
tail -f /dev/null

