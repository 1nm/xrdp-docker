FROM ubuntu:18.04
LABEL description="Eclipse Intellij Docker"
LABEL maintainer "Xiangning Liu <xiangningliu@gmail.com>"

ENV DEBIAN_FRONTEND noninteractive

# Install mate desktop environment, and other tools
RUN apt-get update -qq && apt-get install -qq -y mate-desktop-environment-core mate-themes ubuntu-mate-wallpapers \
        wget sudo vim zip unzip git locales tzdata firefox zsh python3-pip openjdk-8-jdk bash-completion terminator && \
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list && \
    apt-get update -qq -y && apt-get install -qq -y google-chrome-stable && \
    apt-get clean -qq -y && \
    apt-get autoclean -qq -y && \
    apt-get autoremove -qq -y && \
    rm -f /etc/apt/sources.list.d/google.list && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*

# Install emacs26
RUN apt-get update -qq && apt-get install -qq -y software-properties-common && \
    add-apt-repository ppa:kelleyk/emacs && apt-get update -qq -y && apt-get install -qq -y emacs26 && \
    apt-get clean -qq -y && \
    apt-get autoclean -qq -y && \
    apt-get autoremove -qq -y && \
    rm -f /etc/apt/sources.list.d/google.list && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*


# Build xrdp 0.9.9
RUN apt-get update -qq && apt-get install -qq -y git autoconf libtool pkg-config gcc g++ make  libssl-dev libpam0g-dev libjpeg-dev libx11-dev libxfixes-dev libxrandr-dev flex bison libxml2-dev intltool xsltproc xutils-dev python-libxml2 g++ xutils libfuse-dev libmp3lame-dev nasm libpixman-1-dev xserver-xorg-dev xorg && \
    apt-get clean -qq -y && \
    apt-get autoclean -qq -y && \
    apt-get autoremove -qq -y && \
    rm -f /etc/apt/sources.list.d/google.list && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*

RUN BD="/tmp/xrdp-build" && mkdir -p "${BD}"/git/neutrinolabs && cd "${BD}"/git/neutrinolabs && \
    wget https://github.com/neutrinolabs/xrdp/releases/download/v0.9.9/xrdp-0.9.9.tar.gz && \
    wget https://github.com/neutrinolabs/xorgxrdp/releases/download/v0.2.9/xorgxrdp-0.2.9.tar.gz && \

    cd "${BD}"/git/neutrinolabs && tar xvfz xrdp-0.9.9.tar.gz && cd "${BD}"/git/neutrinolabs/xrdp-0.9.9 && \
    ./bootstrap && ./configure --enable-fuse --enable-mp3lame --enable-pixman && make && make install && \
    ln -s /usr/local/sbin/xrdp{,-sesman} /usr/sbin && \

    cd "${BD}"/git/neutrinolabs && tar xvfz xorgxrdp-0.2.9.tar.gz && cd "${BD}"/git/neutrinolabs/xorgxrdp-0.2.9 && \
    ./bootstrap && ./configure && make && make install && \

    rm -fr "${BD}" && \
    xrdp-keygen xrdp auto 2048

RUN systemctl enable xrdp.service && \
    systemctl enable xrdp-sesman.service

# MATE configuration
COPY conf/mate/user /tmp/
RUN mkdir -p /etc/skel/.config/dconf && \
    mv /tmp/user /etc/skel/.config/dconf/user

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

# Install Scala

RUN for scala_version in 2.10.6 2.11.8 2.12.1; do \
    wget -q -O "/tmp/scala-${scala_version}.tgz" "http://www.scala-lang.org/files/archive/scala-${scala_version}.tgz" && \
    mkdir -p /opt/scala && \
    tar -xf /tmp/scala-${scala_version}.tgz -C /opt/scala && \
    rm -f /tmp/scala-${scala_version}.tgz; \
    done

ENV MAVEN_VERSION 3.6.0
ENV GRADLE_VERSION 5.1

# Install Maven

RUN wget -q -O "/tmp/maven-${MAVEN_VERSION}.tgz" "http://www-us.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz" && \
    mkdir -p /opt/maven-${MAVEN_VERSION} && \
    tar -xf /tmp/maven-${MAVEN_VERSION}.tgz --strip-components=1 -C /opt/maven-${MAVEN_VERSION} && \
    rm -f /tmp/maven-${MAVEN_VERSION}.tgz

# Install Gradle

RUN wget -q -O "/tmp/gradle-${GRADLE_VERSION}.zip" "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" && \
    unzip /tmp/gradle-${GRADLE_VERSION}.zip -d /opt/ && \
    rm -f /tmp/gradle-${GRADLE_VERSION}.zip


# Install Eclipse

# Change to a local mirror to speed up if you want to speed up downloading
ENV ECLIPSE_RELEASE 2018-12
ENV ECLIPSE_URL http://ftp.jaist.ac.jp/pub/eclipse
# ENV ECLIPSE_URL http://download.eclipse.org
RUN wget -O /tmp/eclipse.tar.gz ${ECLIPSE_URL}/technology/epp/downloads/release/${ECLIPSE_RELEASE}/R/eclipse-jee-${ECLIPSE_RELEASE}-R-linux-gtk-x86_64.tar.gz && \
    mkdir -p /opt/eclipse && \
    tar -xf /tmp/eclipse.tar.gz --strip-components=1 -C /opt/eclipse && \
    rm -fr /tmp/*

# Create Desktop Icon for Eclipse
RUN sed -i -e "s/-startup/-vm\njava\n-startup/g" /opt/eclipse/eclipse.ini && \
    sed -i -e "s/-Xms256m/-Xms1024m/g" /opt/eclipse/eclipse.ini && \
    sed -i -e "s/-Xmx1024m/-Xmx4096m/g" /opt/eclipse/eclipse.ini && \
    mkdir -p /etc/skel/Desktop && \
    echo "[Desktop Entry]" >> /etc/skel/Desktop/eclipse.desktop && \
    echo "Type=Application" >> /etc/skel/Desktop/eclipse.desktop && \
    echo "Icon=/opt/eclipse/icon.xpm" >> /etc/skel/Desktop/eclipse.desktop && \
    echo "Terminal=false" >> /etc/skel/Desktop/eclipse.desktop && \
    echo "Exec=/opt/eclipse/eclipse" >> /etc/skel/Desktop/eclipse.desktop && \
    echo "Name=Eclipse" >> /etc/skel/Desktop/eclipse.desktop && \
    chmod +x /etc/skel/Desktop/eclipse.desktop

# Install Eclipse Plugins

# # Scala Plugin
# # Scala 2.11
# RUN /opt/eclipse/eclipse -clean -application org.eclipse.equinox.p2.director -noSplash -repository "http://download.scala-ide.org/sdk/lithium/e46/scala211/stable/site" -installIU "org.scala-ide.scala211.feature.feature.group" && \
# # Scala IDE for Eclipse
#     /opt/eclipse/eclipse -clean -application org.eclipse.equinox.p2.director -noSplash -repository "http://download.scala-ide.org/sdk/lithium/e46/scala211/stable/site" -installIU "org.scala-ide.sdt.feature.feature.group" && \
# # ScalaTest for Scala IDE
#     /opt/eclipse/eclipse -clean -application org.eclipse.equinox.p2.director -noSplash -repository "http://download.scala-ide.org/sdk/lithium/e46/scala211/stable/site" -installIU "org.scala-ide.sdt.scalatest.feature.feature.group" && \
# zinc
#    /opt/eclipse/eclipse -clean -application org.eclipse.equinox.p2.director -noSplash -repository "http://download.scala-ide.org/sdk/lithium/e46/scala211/stable/site" -installIU "org.scala-ide.zinc.feature.feature.group"

# Emacs+
RUN /opt/eclipse/eclipse -clean -application org.eclipse.equinox.p2.director -noSplash -repository "http://www.mulgasoft.com/emacsplus/e4/update-site" -installIU "com.mulgasoft.emacsplus.feature.feature.group" && \
    /opt/eclipse/eclipse -clean -application org.eclipse.equinox.p2.director -noSplash -repository "http://www.mulgasoft.com/emacsplus/e4/update-site" -installIU "com.mulgasoft.emacsplus.optional.features.feature.group"


# Install IntelliJ IDEA

ENV INTELLIJ_CONFIG_DIR .IdeaIC2018.3

RUN wget -q -O /tmp/intellij.tar.gz https://download-cf.jetbrains.com/idea/ideaIC-2018.3.3.tar.gz && \
    mkdir -p /opt/intellij && \
    tar -xf /tmp/intellij.tar.gz --strip-components=1 -C /opt/intellij && \
    rm -f /opt/intellij.tar.gz

# Install IntelliJ Plugins

RUN mkdir -p /etc/skel/${INTELLIJ_CONFIG_DIR}/config/options && \
    mkdir -p /etc/skel/${INTELLIJ_CONFIG_DIR}/config/plugins

# Scala Plugin

RUN wget -q -O /etc/skel/${INTELLIJ_CONFIG_DIR}/config/plugins/scala.zip https://plugins.jetbrains.com/files/1347/47106/scala-intellij-bin-2018.1.10.zip && \
    cd /etc/skel/${INTELLIJ_CONFIG_DIR}/config/plugins/ && \
    unzip -q scala.zip && \
    rm -f scala.zip

# Configurations
COPY conf/intellij/jdk.table.xml conf/intellij/applicationLibraries.xml /tmp/
RUN mv /tmp/jdk.table.xml /tmp/applicationLibraries.xml /etc/skel/${INTELLIJ_CONFIG_DIR}/config/options

# Create Desktop Icon for IntelliJ IDEA
RUN echo "[Desktop Entry]" >> /etc/skel/Desktop/idea.desktop && \
    echo "Type=Application" >> /etc/skel/Desktop/idea.desktop && \
    echo "Icon=/opt/intellij/bin/idea.png" >> /etc/skel/Desktop/idea.desktop && \
    echo "Terminal=false" >> /etc/skel/Desktop/idea.desktop && \
    echo "Exec=/opt/intellij/bin/idea.sh" >> /etc/skel/Desktop/idea.desktop && \
    echo "Name=IntelliJ IDEA" >> /etc/skel/Desktop/idea.desktop && \
    chmod +x /etc/skel/Desktop/idea.desktop

# Install VSCode
RUN apt-get update -qq && apt-get install -qq -y --no-install-recommends libgconf-2-4 && \
    apt-get clean -qq -y && \
    apt-get autoclean -qq -y && \
    apt-get autoremove -qq -y &&  \
    rm -rf /var/lib/apt/lists/* && \
    wget -q -O /tmp/vscode.deb https://go.microsoft.com/fwlink/?LinkID=760868 && \
    dpkg -i /tmp/vscode.deb && \
    rm -rf /tmp/*

# Add user configurations
RUN mkdir /etc/skel/workspace && \
    echo "export LANG=en_US.UTF-8" >> /etc/skel/.bashrc && \
    echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64" >> /etc/skel/.bashrc && \
    echo "export MAVEN_HOME=/opt/maven-$MAVEN_VERSION" >> /etc/skel/.bashrc && \
    echo "export GRADLE_HOME=/opt/gradle-$GRADLE_VERSION" >> /etc/skel/.bashrc && \
    echo 'export PATH=$JAVA_HOME/bin:$MAVEN_HOME/bin:$GRADLE_HOME/bin:$PATH' >> /etc/skel/.bashrc

RUN pip3 install percol
COPY conf/.percol.d /etc/skel/.percol.d

RUN sed -i 's/allowed_users=console/allowed_users=anybody/' /etc/X11/Xwrapper.config

EXPOSE 3389
ENTRYPOINT /docker-entrypoint.sh
