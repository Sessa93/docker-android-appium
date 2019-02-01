FROM phusion/baseimage
MAINTAINER Andrea Sessa <andrea.sessa@cleafy.com>

RUN apt update
RUN apt -yq install curl build-essential usbutils

# INSTALL JAVA8
RUN add-apt-repository ppa:webupd8team/java && \
    apt -yq update && \
    echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
    echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections && \
    apt -yq install oracle-java8-installer && \
    apt -yq install oracle-java8-set-default

RUN useradd -ms /bin/bash cleafy

# INSTALL MAVEN
RUN apt install -yq maven

# INSTALL PYTHON 2.7
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y \
    build-essential \
    ca-certificates \
    gcc \
    git \
    libpq-dev \
    make \
    python-pip \
    python2.7 \
    python2.7-dev \
    ssh \
    && apt-get autoremove \
    && apt-get clean

RUN pip install -U "setuptools==3.4.1"
RUN pip install -U "pip==1.5.4"
RUN pip install -U "virtualenv==1.11.4"

# INSTALL NODE 10.x and NPM
RUN apt-get update -yq \
    && apt-get install curl gnupg -yq \
    && curl -sL https://deb.nodesource.com/setup_10.x | bash \
    && apt-get install nodejs -yq
RUN curl -O https://npmjs.com/install.sh | sh

RUN dpkg --add-architecture i386 && apt-get update && apt-get install -y --force-yes expect git wget libc6-i386 lib32stdc++6 lib32gcc1 lib32ncurses5 lib32z1 unzip && apt-get clean

# INSTALL Android tools
COPY scripts /opt/scripts

ENV SDK_VERSION "r25.2.5"
RUN mkdir /opt/android-sdk-linux && cd /opt/android-sdk-linux && wget --output-document=tools-sdk.zip --quiet https://dl.google.com/android/repository/tools_${SDK_VERSION}-linux.zip && unzip tools-sdk.zip && rm -f tools-sdk.zip && chmod +x /opt/scripts/android-accept-licenses.sh && chown -R cleafy.cleafy /opt

# Setup environment
ENV ANDROID_HOME /opt/android-sdk-linux
ENV PATH ${PATH}:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools

USER cleafy

ENV BUILD_TOOLS_VERSION 25.0.3
ENV ANDROID_VERSION 25
RUN /opt/scripts/android-accept-licenses.sh "sdkmanager platform-tools \"build-tools;${BUILD_TOOLS_VERSION}\" \"platforms;android-${ANDROID_VERSION}\" \"add-ons;addon-google_apis-google-24\" \"extras;m2repository;com;android;support;constraint;constraint-layout;1.0.2\" \"extras;m2repository;com;android;support;constraint;constraint-layout-solver;1.0.2\" \"system-images;android-${ANDROID_VERSION};google_apis;armeabi-v7a\" ndk-bundle"

RUN which adb
RUN which android

USER root

RUN echo ANDROID_HOME="$ANDROID_HOME" >> /etc/environment

# INSTALL APPIUM
ENV appium_args "-p 4723"
ENV appium_version 1.10.1
RUN npm install -g appium@${appium_version} --unsafe-perm=true --allow-root

ADD files/insecure_shared_adbkey /home/cleafy/.android/adbkey
ADD files/insecure_shared_adbkey.pub /home/cleafy/.android/adbkey.pub

RUN apt-get -y install supervisor
RUN mkdir -p /var/log/supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN adb kill-server
RUN adb start-server
RUN adb devices

EXPOSE 22
CMD ["/usr/bin/supervisord"]
