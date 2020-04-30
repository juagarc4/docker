FROM debian:stretch
ARG PHPVERSION=7.3
MAINTAINER Raul Garcia

#Set timezone
RUN set -xe; \
  cp /usr/share/zoneinfo/Europe/Berlin /etc/localtime \
  && echo "Europe/Berlin" > /etc/timezone

ENV TZ /etc/localtime
RUN apt-get update && apt-get install -yq \
    software-properties-common \
    git \
    curl \
    wget \
    unzip \
    zip \
    gnupg \
    screen \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libxml2-dev \
    default-mysql-client \
    apt-transport-https \
    lsb-release \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*


RUN wget -q https://packages.sury.org/php/apt.gpg -O- | apt-key add -
RUN echo "deb https://packages.sury.org/php/ stretch main" | tee /etc/apt/sources.list.d/php.list
RUN apt-get update && apt-get install -y \
    $PHPIZE_DEPS \
    "php$PHPVERSION" \
    "php$PHPVERSION-common" \
    "php$PHPVERSION-cli" \
    "php$PHPVERSION-xml" \
    "php$PHPVERSION-gd" \
    "php$PHPVERSION-dom" \
    "php$PHPVERSION-json" \
    "php$PHPVERSION-pdo" \
    "php$PHPVERSION-mysql" \
    "php$PHPVERSION-curl" \
    "php$PHPVERSION-mbstring" \
    "php$PHPVERSION-zip" \
    sqlite3 \
    "php$PHPVERSION-sqlite" \
    openssl \
    libxi6 \
    libgconf-2-4 \
    libzip-dev \
    && docker-php-source extract \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd zip \
    && docker-php-ext-enable gd zip \
    && docker-php-source delete \
    && apt-get autoclean -y; \
    apt-get autoremove -y; \
    rm -rf /var/lib/apt/lists/*; \
    rm -rf /var/log/*; \
    rm -rf /var/cache/*; \
    rm -rf /tmp/*

COPY ./php_custom.ini "/usr/local/etc/php/conf.d/php_custom.ini"

RUN set -xe; \
  cd /tmp && curl -sSL https://getcomposer.org/installer > composer-setup.php \
  && echo "c5043a2d448546b322cfad449e8936348d3ef1700ba44d1eb7b683943224ddd505649b54872c7d82b3e562f98b90dd8fcb5c1c61414fbd206659727c83a198ec  composer-setup.php" | sha512sum -c - \
  && php composer-setup.php --check \
  && php composer-setup.php --install-dir=/usr/local/bin/ --filename=composer \
  && chmod +x /usr/local/bin/composer \
  && set +x \
  && printf "$(composer --ansi --version)\n\n"\
  && composer --ansi diagnose \
  && rm -rf /tmp/composer-setup.php

# Install presitissimo
RUN composer global require hirak/prestissimo \
    && composer clear-cache

# Install PHPUnit
RUN composer global require phpunit/phpunit:^6 mikey179/vfsstream:~1.2 \
    && composer clear-cache

RUN mkdir project
RUN mkdir project/docroot
