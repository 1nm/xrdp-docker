FROM ubuntu:17.04
LABEL description="xrdp docker"
LABEL maintainer "Xiangning Liu <xiangningliu@gmail.com>"

ENV DEBIAN_FRONTEND noninteractive
ENV JAVA_VERSION 1.8.0_sr4fp11

# Install mate desktop environment, and other tools
RUN apt-get update -qq && apt-get install -qq -y mate-desktop-environment-core mate-themes wget sudo emacs25 vim zip unzip git locales tzdata firefox zsh python3-pip openjdk-8-jdk && \
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list && \
    apt-get update -qq -y && apt-get install -qq -y google-chrome-stable && \
    apt-get clean -qq -y && \
    apt-get autoclean -qq -y && \
    apt-get autoremove -qq -y && \
    rm -f /etc/apt/sources.list.d/google.list && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*

# Build xorg 0.9.4
RUN apt-get update -qq && apt-get install -qq -y git autoconf libtool pkg-config gcc g++ make  libssl-dev libpam0g-dev libjpeg-dev libx11-dev libxfixes-dev libxrandr-dev  flex bison libxml2-dev intltool xsltproc xutils-dev python-libxml2 g++ xutils libfuse-dev libmp3lame-dev nasm libpixman-1-dev xserver-xorg-dev xorg && \
    apt-get clean -qq -y && \
    apt-get autoclean -qq -y && \
    apt-get autoremove -qq -y && \
    rm -f /etc/apt/sources.list.d/google.list && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*

RUN BD="/tmp/xrdp-build" && mkdir -p "${BD}"/git/neutrinolabs && cd "${BD}"/git/neutrinolabs && \
    wget https://github.com/neutrinolabs/xrdp/releases/download/v0.9.4/xrdp-0.9.4.tar.gz && \
    wget https://github.com/neutrinolabs/xorgxrdp/releases/download/v0.2.4/xorgxrdp-0.2.4.tar.gz && \

    cd "${BD}"/git/neutrinolabs && tar xvfz xrdp-0.9.4.tar.gz && cd "${BD}"/git/neutrinolabs/xrdp-0.9.4 && \
    ./bootstrap && ./configure --enable-fuse --enable-mp3lame --enable-pixman && make && make install && \
    ln -s /usr/local/sbin/xrdp{,-sesman} /usr/sbin && \

    cd "${BD}"/git/neutrinolabs && tar xvfz xorgxrdp-0.2.4.tar.gz && cd "${BD}"/git/neutrinolabs/xorgxrdp-0.2.4 && \
    ./bootstrap && ./configure && make && make install && \

    rm -fr "${BD}" && \
    xrdp-keygen xrdp auto 2048

RUN systemctl enable xrdp.service && \
    systemctl enable xrdp-sesman.service

# MATE configuration
COPY conf/mate/user /tmp/
RUN mkdir -p /etc/skel/.config/dconf && \
    mv /tmp/user /etc/skel/.config/dconf/user

ENV JAVA_HOME=/opt/ibm/java/jre \
    PATH=/opt/ibm/java/bin:$PATH

# Setting default time zone to Asia/Tokyo
ENV TZ=Asia/Tokyo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata \
# Change locale to en_US.UTF-8
    && localedef -i en_US -f UTF-8 en_US.UTF-8 && update-locale LANG=en_US.UTF-8

# Expose 3389 port, start xrdp
COPY docker-entrypoint.sh /docker-entrypoint.sh

# Install IME
RUN apt-get update -qq && apt-get install -qq -y ibus ibus-mozc ibus-pinyin && \
    apt-get clean -qq -y && \
    apt-get autoclean -qq -y && \
    apt-get autoremove -qq -y && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*

# Auto start ibus-daemon on mate desktop
RUN mkdir -p /etc/skel/.config/autostart && \
    echo "[Desktop Entry]" >> /etc/skel/.config/autostart/ibus-daemon.desktop && \
    echo "Type=Application" >> /etc/skel/.config/autostart/ibus-daemon.desktop && \
    echo "Exec=/usr/bin/ibus-daemon -d" >> /etc/skel/.config/autostart/ibus-daemon.desktop && \
    echo "Hidden=false" >> /etc/skel/.config/autostart/ibus-daemon.desktop && \
    echo "X-MATE-Autostart-enabled=true" >> /etc/skel/.config/autostart/ibus-daemon.desktop && \
    echo "Name[en_US]=IBus Daemon" >> /etc/skel/.config/autostart/ibus-daemon.desktop && \
    echo "Name=IBus Daemon" >> /etc/skel/.config/autostart/ibus-daemon.desktop && \
    echo "Comment[en_US]=" >> /etc/skel/.config/autostart/ibus-daemon.desktop && \
    echo "Comment=" >> /etc/skel/.config/autostart/ibus-daemon.desktop && \
    chmod +x /etc/skel/.config/autostart/ibus-daemon.desktop

EXPOSE 3389
ENTRYPOINT /docker-entrypoint.sh

