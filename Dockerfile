FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

ARG SLACK_VERSION=4.37.94
ARG TZ=Asia/Tokyo

# Install mate desktop environment, and other tools
RUN apt-get update && apt-get install -y mate-desktop-environment-core mate-themes ubuntu-mate-wallpapers xrdp \
        curl wget sudo vim zip unzip git locales tzdata zsh python3-pip bash-completion openjdk-17-jdk-headless \
        libgconf-2-4 libappindicator3-1 \
        ibus ibus-mozc ibus-pinyin ttf-wqy-microhei && \
    # Install Google Chrome
    wget -qO /tmp/google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    apt-get install -y /tmp/google-chrome-stable_current_amd64.deb && \
    rm -f /tmp/google-chrome-stable_current_amd64.deb && \
    # Install VSCode
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg && \
    install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/ && \
    echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" >> /etc/apt/sources.list.d/vscode.list && \
    apt-get install -y apt-transport-https && apt-get -y update && apt-get install -y code && \
    # Install Slack
    wget https://downloads.slack-edge.com/releases/linux/${SLACK_VERSION}/prod/x64/slack-desktop-${SLACK_VERSION}-amd64.deb -O /tmp/slack-desktop.deb && \
    cd /tmp/ && \
    dpkg -i slack-desktop.deb && \
    rm -f /etc/apt/sources.list.d/google.list && \
    rm -f /etc/apt/sources.list.d/vscode.list && \
    rm -rf /tmp/slack-desktop*.deb && \
    rm -rf /var/lib/apt/lists/*

COPY etc/skel /etc/skel

# Add user configurations
RUN echo "export LANG=en_US.UTF-8" >> /etc/skel/.bashrc && \
    echo "export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64" >> /etc/skel/.bashrc && \
    echo 'export PATH=$JAVA_HOME/bin:$PATH' >> /etc/skel/.bashrc

# Setting default time zone to TZ and locale to en_US.UTF-8
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata && \
    localedef -i en_US -f UTF-8 en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8

# Expose 3389 port, start xrdp
COPY entrypoint.sh /entrypoint.sh

RUN sed -i 's/allowed_users=console/allowed_users=anybody/' /etc/X11/Xwrapper.config

EXPOSE 3389
ENTRYPOINT /entrypoint.sh