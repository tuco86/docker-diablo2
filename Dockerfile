# syntax=docker/dockerfile:experimental
FROM i386/ubuntu:19.10

ENV \
    DEBIAN_FRONTEND="noninteractive"

WORKDIR /build

ARG WINE_BRANCH="stable"

RUN \
    --mount=type=cache,id=apt-lists,target=/var/lib/apt/lists/ \
    --mount=type=cache,id=apt-archives,target=/var/cache/apt/archives/ \
    sed -i '/deb-src/s/^# //' /etc/apt/sources.list \
    && rm /etc/apt/apt.conf.d/docker-clean \
    && apt-get update \
    && apt-get install -y \
        apt-transport-https \
        software-properties-common \
        ca-certificates \
        sudo \
        gpg-agent \
        curl \
    # && curl -O https://dl.winehq.org/wine-builds/winehq.key \
    # && apt-key add winehq.key \
    # && apt-add-repository "deb https://dl.winehq.org/wine-builds/ubuntu/ eoan main" \
    # && dpkg --add-architecture i386 \
    # && apt-get update \
    # && apt-get upgrade -y \
    && apt-get install -y \
        cabextract \
        p7zip \
        pulseaudio-utils \
        python3-dev \
        python3-pip \
        python3-setuptools \
        python3-distutils \
        python3-wheel \
        vim \
        unzip \
        ffmpeg \
        xvfb \
        winbind \
        zenity \
        wine \
        winetricks \
    && apt-get build-dep -y nginx \
    && apt-get source nginx \
    && curl -sL https://github.com/arut/nginx-ts-module/archive/v0.1.1.tar.gz | tar xz

RUN \
    cd nginx-1.16.1 \
    && ./configure \
        --with-cc-opt='-g -O2 -fdebug-prefix-map=/build/nginx-9NvCQA/nginx-1.16.1=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2' \
        --with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now -fPIC' \
        # --prefix=/usr/share/nginx \
        --prefix=/usr \
        --conf-path=/etc/nginx/nginx.conf \
        --http-log-path=/var/log/nginx/access.log \
        --error-log-path=/var/log/nginx/error.log \
        --lock-path=/var/lock/nginx.lock \
        --pid-path=/run/nginx.pid \
        --modules-path=/usr/lib/nginx/modules \
        --http-client-body-temp-path=/var/lib/nginx/body \
        --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
        --http-proxy-temp-path=/var/lib/nginx/proxy \
        --http-scgi-temp-path=/var/lib/nginx/scgi \
        --http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
        --with-debug \
        --with-compat \
        --with-pcre-jit \
        --with-http_ssl_module \
        --with-http_stub_status_module \
        --with-http_realip_module \
        --with-http_auth_request_module \
        --with-http_v2_module \
        --with-http_dav_module \
        --with-http_slice_module \
        --with-threads \
        --with-http_addition_module \
        --with-http_geoip_module=dynamic \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_image_filter_module=dynamic \
        --with-http_sub_module \
        --with-http_xslt_module=dynamic \
        --with-stream=dynamic \
        --with-stream_ssl_module \
        --with-mail=dynamic \
        --with-mail_ssl_module \
        --add-dynamic-module=/build/nginx-ts-module-0.1.1 \
    && make -j 5 \
    && make install \
    && mkdir -p /var/lib/nginx/body /var/lib/nginx/fastcgi


# Download mono and gecko
RUN \
    export MONO_VER="4.9.4" ; \
    export GECKO_VER="2.47" ; \
    mkdir -p /usr/share/wine/mono /usr/share/wine/gecko \
    && curl -sL https://dl.winehq.org/wine/wine-mono/${MONO_VER}/wine-mono-${MONO_VER}.msi \
        -o /usr/share/wine/mono/wine-mono-${MONO_VER}.msi \
    && curl -sL https://dl.winehq.org/wine/wine-gecko/${GECKO_VER}/wine_gecko-${GECKO_VER}-x86.msi \
        -o /usr/share/wine/gecko/wine_gecko-${GECKO_VER}-x86.msi \
    && curl -sL https://dl.winehq.org/wine/wine-gecko/${GECKO_VER}/wine_gecko-${GECKO_VER}-x86_64.msi \
        -o /usr/share/wine/gecko/wine_gecko-${GECKO_VER}-x86_64.msi

# # install angr
# ENV \
#     PIP_NO_CACHE=true

# RUN \
#     pip3 install z3-solver!=4.8.7.0 angr

# Create user and take ownership of files
RUN groupadd -g 1010 wineuser \
    && useradd --shell /bin/bash --uid 1010 --gid 1010 --create-home --home-dir /home/wineuser wineuser \
    && chown -R wineuser:wineuser /home/wineuser

WORKDIR /home/wineuser

# COPY --chown=wineuser:wineuser Downloader_Diablo2_enUS.exe /home/wineuser/Downloader_Diablo2_enUS.exe
# COPY --chown=wineuser:wineuser Downloader_Diablo2_Lord_of_Destruction_enUS.exe /home/wineuser/Downloader_Diablo2_Lord_of_Destruction_enUS.exe
COPY --chown=wineuser:wineuser D2-1.14b-Installer-enUS/ /home/wineuser/D2-1.14b-Installer-enUS
COPY --chown=wineuser:wineuser D2LOD-1.14b-Installer-enUS/ /home/wineuser/D2LOD-1.14b-Installer-enUS
COPY pulse-client.conf /etc/pulse/client.conf
COPY winetricks/diabloii.verb /home/wineuser/diabloii.verb

ARG REG_NAME
ARG D2_KEY
ARG D2LOD_KEY

# ENV DISPLAY=":99"

# use this over :99 for connecting to XQuartz
ENV DISPLAY="host.docker.internal:0"

RUN \
    Xvfb :99 -screen 0 800x600x16 -nocursor & XVFB_PID=$! ; \
    sudo -u wineuser wineboot -i \
    && sudo -u wineuser REG_NAME=${REG_NAME} D2_KEY=${D2_KEY} D2LOD_KEY=${D2LOD_KEY} winetricks -q diabloii.verb \
    && sleep 1 \
    && kill $XVFB_PID

ARG S6_OVERLAY_VERSION=1.22.1.0

RUN \
  curl -sLo /tmp/s6-overlay-amd64.tar.gz https://github.com/just-containers/s6-overlay/releases/download/v$S6_OVERLAY_VERSION/s6-overlay-amd64.tar.gz \
  && tar xzf /tmp/s6-overlay-amd64.tar.gz -C / --exclude="./bin" \
  && tar xzf /tmp/s6-overlay-amd64.tar.gz -C /usr ./bin

COPY xvfb.run /etc/services.d/xvfb/run
COPY ffmpeg.run /etc/services.d/ffmpeg/run
COPY nginx.run /etc/services.d/nginx/run
COPY nginx.conf /etc/nginx/nginx.conf
COPY index.html /usr/html/index.html
COPY entrypoint.sh /usr/bin/entrypoint

RUN mkdir -p /var/lib/ts

ENTRYPOINT [ "/init" ]

CMD [ "bash" ]
