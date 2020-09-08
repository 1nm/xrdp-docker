FROM ubuntu:20.04 as base

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Tokyo

FROM base
LABEL description="XRDP Docker"
LABEL maintainer "1nm  <1nm@users.noreply.github.com>"

# Install mate desktop environment, and other tools
RUN apt update && apt install -y mate-desktop-environment-core mate-themes ubuntu-mate-wallpapers xrdp \
        curl wget sudo vim zip unzip git locales tzdata zsh python3-pip bash-completion openjdk-11-jdk-headless \
        libgconf-2-4 \
        ibus ibus-mozc ibus-pinyin && \
    # Install Google Chrome
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list && \
    apt update -y && apt-get install -qq -y google-chrome-stable && \
    # Install VSCode
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg && \
    install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/ && \
    echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" >> /etc/apt/sources.list.d/vscode.list && \
    apt install -y apt-transport-https && apt -y update && apt install -y code && \
    rm -rf /tmp/* && \
    rm -f /etc/apt/sources.list.d/google.list && \
    rm -f /etc/apt/sources.list.d/vscode.list && \
    rm -rf /var/lib/apt/lists/*

COPY etc/skel /etc/skel

# Add user configurations
RUN echo "export LANG=en_US.UTF-8" >> /etc/skel/.bashrc && \
    echo "export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64" >> /etc/skel/.bashrc && \
    echo "export MAVEN_HOME=/opt/maven-$MAVEN_VERSION" >> /etc/skel/.bashrc && \
    echo "export GRADLE_HOME=/opt/gradle-$GRADLE_VERSION" >> /etc/skel/.bashrc && \
    echo 'export PATH=$JAVA_HOME/bin:$MAVEN_HOME/bin:$GRADLE_HOME/bin:$PATH' >> /etc/skel/.bashrc

# Setting default time zone to Asia/Tokyo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata \
# Change locale to en_US.UTF-8
    && localedef -i en_US -f UTF-8 en_US.UTF-8 && update-locale LANG=en_US.UTF-8

# Expose 3389 port, start xrdp
COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN sed -i 's/allowed_users=console/allowed_users=anybody/' /etc/X11/Xwrapper.config

EXPOSE 3389
ENTRYPOINT /docker-entrypoint.sh
