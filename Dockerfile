FROM ghcr.io/linuxserver/baseimage-alpine-nginx:3.15

# set version label
ARG BUILD_DATE
ARG VERSION
ARG BOOKSTACK_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="homerr"

# package versions
ARG BOOKSTACK_RELEASE

RUN \
  echo "**** install runtime packages ****" && \
  apk add --no-cache  \
    curl \
    fontconfig \
    memcached \
    netcat-openbsd \
    php8-ctype \
    php8-curl \
    php8-dom \
    php8-gd \
    php8-ldap \
    php8-mbstring \
    php8-mysqlnd \
    php8-openssl \
    php8-pdo_mysql \
    php8-pecl-memcached \
    php8-phar \
    php8-simplexml \
    php8-tokenizer \
    qt5-qtbase \
    tar \
    ttf-freefont && \
  apk add --no-cache \
    --repository=http://dl-cdn.alpinelinux.org/alpine/v3.14/community \
    wkhtmltopdf && \
  echo "**** install composer ****" && \
  php8 -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
  php8 composer-setup.php --install-dir=/usr/local/bin --filename=composer && \
  echo "**** configure php-fpm to pass env vars ****" && \
  sed -E -i 's/^;?clear_env ?=.*$/clear_env = no/g' /etc/php8/php-fpm.d/www.conf && \
  grep -qxF 'clear_env = no' /etc/php8/php-fpm.d/www.conf || echo 'clear_env = no' >> /etc/php8/php-fpm.d/www.conf && \
  echo "env[PATH] = /usr/local/bin:/usr/bin:/bin" >> /etc/php8/php-fpm.conf && \
  echo "**** fetch bookstack ****" && \
  mkdir -p\
    /app/www && \
  if [ -z ${BOOKSTACK_RELEASE+x} ]; then \
    BOOKSTACK_RELEASE=$(curl -sX GET "https://api.github.com/repos/bookstackapp/bookstack/releases/latest" \
    | awk '/tag_name/{print $4;exit}' FS='[""]'); \
  fi && \
  curl -o \
    /tmp/bookstack.tar.gz -L \
    "https://github.com/BookStackApp/BookStack/archive/${BOOKSTACK_RELEASE}.tar.gz" && \
  tar xf \
    /tmp/bookstack.tar.gz -C \
    /app/www/ --strip-components=1 && \
  echo "**** install composer dependencies ****" && \
  composer install -d /app/www/ && \
  echo "**** overlay-fs bug workaround ****" && \
  mv /var/www /var/www-tmp && \
  echo "**** cleanup ****" && \
  rm -rf \
    /root/.composer \
    /tmp/*

COPY root/ /

VOLUME /config
EXPOSE 80
