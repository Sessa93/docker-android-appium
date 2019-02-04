FROM codetroopers/jenkins-slave-jdk8-android:22-22.0.1-x86
MAINTAINER Andrea Sessa <andrea.sessa@cleafy.com>

WORKDIR /home/jenkins

RUN apt update
RUN apt -yq install curl build-essential usbutils

# INSTALL MAVEN
RUN apt install -yq maven

# INSTALL NODE 10.x and NPM
RUN apt-get update -yq \
    && apt-get install curl gnupg -yq \
    && curl -sL https://deb.nodesource.com/setup_10.x | bash \
    && apt-get install nodejs -yq
RUN curl -O https://npmjs.com/install.sh | sh

RUN dpkg --add-architecture i386 && apt-get update && apt-get install -y --force-yes expect git wget libc6-i386 lib32stdc++6 lib32gcc1 lib32ncurses5 lib32z1 unzip && apt-get clean

# INSTALL APPIUM
ENV appium_args "-p 4723"
ENV appium_version 1.10.1
RUN npm install -g appium@${appium_version} --unsafe-perm=true --allow-root

ADD files/insecure_shared_adbkey /home/jenkins/.android/adbkey
ADD files/insecure_shared_adbkey.pub /home/jenkins/.android/adbkey.pub

RUN apt-get -y install supervisor
RUN mkdir -p /var/log/supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN adb kill-server
RUN adb start-server
RUN adb devices

EXPOSE 22
CMD ["/usr/bin/supervisord"]
