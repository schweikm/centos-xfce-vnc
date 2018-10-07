# This Dockerfile is used to build an headles vnc image based on Centos

## Connection ports for controlling the UI:
# VNC port:5901
# noVNC webport, connect via http://IP:6901/?password=vncpassword

FROM centos:7.5.1804

MAINTAINER Marc Schweikert "schweikertm@udev.local"

ENV DISPLAY=:1 \
    VNC_PORT=5901

EXPOSE $VNC_PORT

### Envrionment config
ENV HOME=/headless \
    TERM=xterm \
    STARTUPDIR=/dockerstartup \
    DATADIR=/data \
    VNC_COL_DEPTH=24 \
    VNC_RESOLUTION=1280x1024 \
    VNC_PW=vncpassword \
    VNC_VIEW_ONLY=false
WORKDIR $HOME

### setup repositories
COPY src/repos/*.repo /etc/yum.repos.d/
COPY src/repos/RPM-GPG-KEY* /etc/pki/rpm-gpg/
RUN  rpm --import /etc/pki/rpm-gpg/*

### update OS
RUN yum makecache fast && \
    yum -y upgrade && \
    yum clean all && \
    rm -fr /var/cache/yum

### Install core tools to make the rest easier
RUN yum makecache fast && \
    yum -y install man-db info deltarpm && \
    yum clean all && \
    rm -fr /var/cache/yum

### Install some common tools
RUN yum makecache fast && \
    yum -y install vim sudo wget which net-tools bzip2 unzip mlocate screen rsync && \
    yum clean all && \
    rm -fr /var/cache/yum

### Install git
RUN yum makecache fast && \
    yum -y install git2u-gitk git2u-gui tig && \
    yum clean all && \
    rm -fr /var/cache/yum

ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

### Install xvnc-server & noVNC - HTML5 based VNC viewer
RUN yum makecache fast && \
    yum -y install tigervnc-server && \
    yum clean all && \
    rm -fr /var/cache/yum

### Install firefox and chrome browser
RUN yum makecache fast && \
    yum -y install firefox && \
    yum clean all && \
    rm -fr /var/cache/yum

### Install xfce UI
RUN yum makecache fast && \
    yum -y -x gnome-keyring --skip-broken groups install "Xfce" && \
    yum -y groups install "Fonts" && \
    yum -y erase *power* *screensaver* && \
    yum clean all && \
    rm -fr /var/cache/yum && \
    rm /etc/xdg/autostart/xfce-polkit* && \
    /bin/dbus-uuidgen > /etc/machine-id

COPY ./src/common/xfce/ $HOME/

### configure startup
RUN yum makecache fast && \
    yum -y install nss_wrapper gettext && \
    yum clean all && \
    rm -fr /var/cache/yum && \
    echo 'source $STARTUPDIR/generate_container_user' >> $HOME/.bashrc

COPY ./src/common/scripts $STARTUPDIR

### perstent files
RUN mkdir $DATADIR
VOLUME $DATADIR

### restore permissions
RUN for var in $STARTUPDIR $HOME $DATADIR; do \
    find "$var"/ -name '*.sh' -exec chmod $verbose a+x {} +; \
    find "$var"/ -name '*.desktop' -exec chmod $verbose a+x {} +; \
    chgrp -R 0 "$var" && chmod -R $verbose a+rw "$var" && find "$var" -type d -exec chmod $verbose a+x {} +; \
    done

USER 1000

ENTRYPOINT ["/dockerstartup/vnc_startup.sh"]
CMD ["/bin/bash"]
