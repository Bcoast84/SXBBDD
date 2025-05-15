FROM php:5.6-apache

# Cambia los repositorios a archive.debian.org y elimina stretch-updates y security
RUN sed -i 's|deb.debian.org|archive.debian.org|g' /etc/apt/sources.list && \
    sed -i '/security.debian.org/d' /etc/apt/sources.list && \
    sed -i '/stretch-updates/d' /etc/apt/sources.list

# Instala las dependencias necesarias para GD y otras extensiones
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libxpm-dev \
    libxml2-dev \
    zlib1g-dev \
    libicu-dev \
    libcurl4-openssl-dev \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/ --with-xpm-dir=/usr/include/ \
    && docker-php-ext-install gd mysqli mysql xmlrpc intl curl mbstring

RUN a2enmod rewrite

COPY moodle /var/www/html/moodle

RUN chown -R www-data:www-data /var/www/html/moodle

