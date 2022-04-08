FROM ubuntu:20.04
MAINTAINER Wenfan Hu <wenfan.hu@infaith.com.cn>

ENV VERSION_TOOLS "8092744"

ENV ANDROID_SDK_ROOT "/opt/android-sdk"
# Keep alias for compatibility
ENV ANDROID_HOME "${ANDROID_SDK_ROOT}"
ENV PATH "$PATH:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${ANDROID_SDK_ROOT}/emulator"
ENV DEBIAN_FRONTEND noninteractive

# 换阿里源
RUN sed -i s@/archive.ubuntu.com/@/mirrors.163.com/@g /etc/apt/sources.list
RUN apt-get clean
RUN apt-get -qq update \
 && apt-get install -qqy --no-install-recommends \
     curl \
     git-core \
     openjdk-11-jdk \
     unzip \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

WORKDIR $ANDROID_SDK_ROOT
WORKDIR cmdline_download
RUN curl -k https://dl.google.com/android/repository/commandlinetools-linux-${VERSION_TOOLS}_latest.zip > cmdline-tools.zip \
 && rm -rf cmdline-tools \
 && mkdir -p cmdline-tools \
 && unzip cmdline-tools.zip -d cmdline-tools

WORKDIR $ANDROID_SDK_ROOT
RUN mkdir -p cmdline-tools \
 && mv cmdline_download/cmdline-tools/cmdline-tools cmdline-tools/latest \
 && rm -rf cmdline_download

WORKDIR licenses
RUN echo "8933bad161af4178b1185d1a37fbf41ea5269c55\nd56f5187479451eabf01fb78af6dfcb131a6481e\n24333f8a63b6825ea9c5514f83c2829b004d1fee" > android-sdk-license \
 && echo "84831b9409646a918e30573bab4c9c91346d8abd\n504667f4c0de7af1a06de9f4b1727b84351f2910" > android-sdk-preview-license \
 && yes | sdkmanager --licenses >/dev/null

WORKDIR /root/.android
RUN touch repositories.cfg \
 && sdkmanager --update

ADD packages.txt ${ANDROID_SDK_ROOT}
RUN sdkmanager --package_file=${ANDROID_SDK_ROOT}/packages.txt

# Android Enum stuff
# some addition package.
# RUN sdkmanager "emulator"
# RUN sdkmanager "system-images;android-32;google_apis;x86_64"
# RUN sdkmanager "system-images;android-32;google_apis;arm64-v8a"

# create the emulator.
# RUN avdmanager --verbose create avd --force --name "avd_arm64" --device "pixel" --package "system-images;android-32;google_apis;arm64-v8a" --tag "google_apis" --abi "arm64-v8a"
# RUN avdmanager --verbose create avd --force --name "avd_x86_64" --device "pixel" --package "system-images;android-32;google_apis;x86_64" --tag "google_apis" --abi "x86_64"


# Test can build android apk

WORKDIR /opt/src
RUN git clone https://github.com/android/sunflower

WORKDIR /opt/src/sunflower
RUN export GRADLE_USER_HOME=$(pwd)/.gradle
RUN chmod +x ./gradlew
# 我们手动进入看看日志
# RUN ./gradlew assembleDebug