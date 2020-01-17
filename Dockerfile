FROM ubuntu:bionic as builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y wget
# Install Eclipse
RUN wget -O /tmp/eclipse.tar.gz ${ECLIPSE_URL}/technology/epp/downloads/release/${ECLIPSE_RELEASE}/R/eclipse-jee-${ECLIPSE_RELEASE}-R-linux-gtk-x86_64.tar.gz && \
    mkdir -p /opt/eclipse && \
    tar -xf /tmp/eclipse.tar.gz --strip-components=1 -C /opt/eclipse

# Install IntelliJ IDEA
RUN wget -q -O /tmp/intellij.tar.gz https://download-cf.jetbrains.com/idea/ideaIC-${INTELLIJ_VERSION}.tar.gz && \
    mkdir -p /opt/intellij && \
    tar -xf /tmp/intellij.tar.gz --strip-components=1 -C /opt/intellij

COPY etc/skel /etc/skel

FROM ubuntu:bionic
LABEL description="Eclipse Intellij Docker"
LABEL maintainer "1nm  <1nm@users.noreply.github.com>"

ENV DEBIAN_FRONTEND=noninteractive \
    ECLIPSE_RELEASE=2019-03 \
    ECLIPSE_URL=http://ftp.jaist.ac.jp/pub/eclipse \
    INTELLIJ_VERSION 2019.1.3 \
    TZ=Asia/Tokyo

# Install mate desktop environment, and other tools
RUN apt update && apt install -y mate-desktop-environment-core mate-themes ubuntu-mate-wallpapers xrdp \
        curl wget sudo vim zip unzip git locales tzdata firefox zsh python3-pip bash-completion terminator \
        libgconf-2-4 \
        ibus ibus-mozc ibus-pinyin && \
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list && \
    apt update -y && apt-get install -qq -y google-chrome-stable && \
    wget -q -O /tmp/vscode.deb https://go.microsoft.com/fwlink/?LinkID=760868 && \
    dpkg -i /tmp/vscode.deb && \
    rm -rf /tmp/* && \
    # apt clean  -y && \
    # apt autoclean -y && \
    # apt autoremove -y && \
    rm -f /etc/apt/sources.list.d/google.list && \
    rm -rf /var/lib/apt/lists/*

FROM maven as maven
FROM gradle as gradle

COPY --from=builder /opt /opt
COPY --from=builder /etc/skel /etc/skel
COPY --from=maven /usr/share/maven /opt/maven
COPY --from=gradle /opt/gradle /opt/gradle

# # Build xrdp
# RUN apt-get update -qq && apt-get install -qq -y git autoconf libtool pkg-config gcc g++ make  libssl-dev libpam0g-dev libjpeg-dev libx11-dev libxfixes-dev libxrandr-dev flex bison libxml2-dev intltool xsltproc xutils-dev python-libxml2 g++ xutils libfuse-dev libmp3lame-dev nasm libpixman-1-dev xserver-xorg-dev xorg && \
#     apt-get clean -qq -y && \
#     apt-get autoclean -qq -y && \
#     apt-get autoremove -qq -y && \
#     rm -f /etc/apt/sources.list.d/google.list && \
#     rm -rf /var/lib/apt/lists/* && \
#     rm -rf /tmp/*

# RUN BD="/tmp/xrdp-build" && mkdir -p "${BD}"/git/neutrinolabs && cd "${BD}"/git/neutrinolabs && \
#     wget https://github.com/neutrinolabs/xrdp/releases/download/v${XRDP_VERSION}/xrdp-${XRDP_VERSION}.tar.gz && \
#     wget https://github.com/neutrinolabs/xorgxrdp/releases/download/v${XORGXRDP_VERSION}/xorgxrdp-${XORGXRDP_VERSION}.tar.gz && \

#     cd "${BD}"/git/neutrinolabs && tar xvfz xrdp-${XRDP_VERSION}.tar.gz && cd "${BD}"/git/neutrinolabs/xrdp-${XRDP_VERSION} && \
#     ./bootstrap && ./configure --enable-fuse --enable-mp3lame --enable-pixman && make && make install && \
#     ln -s /usr/local/sbin/xrdp{,-sesman} /usr/sbin && \

#     cd "${BD}"/git/neutrinolabs && tar xvfz xorgxrdp-${XORGXRDP_VERSION}.tar.gz && cd "${BD}"/git/neutrinolabs/xorgxrdp-${XORGXRDP_VERSION} && \
#     ./bootstrap && ./configure && make && make install && \

#     rm -fr "${BD}" && \
#     xrdp-keygen xrdp auto 2048

# RUN systemctl enable xrdp.service && \
#     systemctl enable xrdp-sesman.service

# MATE configuration

# Add user configurations
RUN echo "export LANG=en_US.UTF-8" >> /etc/skel/.bashrc && \
    echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64" >> /etc/skel/.bashrc && \
    echo "export MAVEN_HOME=/opt/maven-$MAVEN_VERSION" >> /etc/skel/.bashrc && \
    echo "export GRADLE_HOME=/opt/gradle-$GRADLE_VERSION" >> /etc/skel/.bashrc && \
    echo 'export PATH=$JAVA_HOME/bin:$MAVEN_HOME/bin:$GRADLE_HOME/bin:$PATH' >> /etc/skel/.bashrc

# Setting default time zone to Asia/Tokyo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata \
# Change locale to en_US.UTF-8
    && localedef -i en_US -f UTF-8 en_US.UTF-8 && update-locale LANG=en_US.UTF-8

# Expose 3389 port, start xrdp
COPY docker-entrypoint.sh /docker-entrypoint.sh

# Install VSCode

RUN sed -i 's/allowed_users=console/allowed_users=anybody/' /etc/X11/Xwrapper.config

EXPOSE 3389
ENTRYPOINT /docker-entrypoint.sh
