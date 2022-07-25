ARG ALPINE_VERSION=3.14
FROM alpine:${ALPINE_VERSION}
LABEL Description="Lightweight container with Nginx 1.20 & PHP 8.0 based on Alpine Linux."
# Setup document root
WORKDIR /srv

# Install packages and remove default server definition   
RUN apk add --no-cache \
  php7 \
  php7-cli \
  php7-pdo \ 
  php7-pdo_mysql \
  php7-posix \
  php7-fileinfo \ 
  php7-opcache \
  php7-common \
  php7-ctype \
  php7-curl \
  php7-dom \
  php7-fpm \
  php7-gd \
  php7-intl \
  php7-json \
  php7-mbstring \
  php7-mysqli \
  php7-opcache \
  php7-openssl \
  php7-redis \
  php7-zip \
  php7-phar \
  php-bcmath \
  php7-session \
  php7-xml \
  php7-xmlwriter \
  php7-xmlreader \
  php7-zlib \
  php7-tokenizer \
  curl \
  nginx \
  supervisor \
  tzdata


RUN  apk add --no-cache \
	 mysql-client\
	 php7-iconv \ 
	 php7-simplexml

# Create symlink so programs depending on `php` still function
#RUN ln -s /usr/bin/php7 /usr/bin/php

# Install composer from the official image
COPY --from=composer /usr/bin/composer /usr/bin/composer

# Run composer install to install the dependencies
#RUN composer install --optimize-autoloader --no-interaction --no-progress

# set timezone America/Santiago
RUN apk add tzdata
RUN cp /usr/share/zoneinfo/America/Santiago /etc/localtime

# Configure nginx
COPY deploy/nginx/nginx.conf /etc/nginx/nginx.conf
COPY deploy/nginx/default /etc/nginx/conf.d/default.conf

# Configure PHP-FPM
COPY deploy/php/fpm.conf /etc/php7/php-fpm.d/www.conf
COPY deploy/php/php.ini /etc/php7/conf.d/custom.ini
RUN mkdir -p /var/log/fpm && touch /var/log/fpm/fpm.log 

# Configure supervisord
COPY deploy/supervisord/init.ini /etc/supervisor/conf.d/init.ini
COPY deploy/supervisord/supervisord.conf /etc/supervisord.conf
RUN mkdir -p /var/log/supervisord && touch /var/log/supervisord/supervisord.log 

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody:nobody  /run/ /var/lib/nginx /var/log/nginx /var/log/php7  /var/log/supervisord
RUN chmod -R 775 /var/log/nginx /var/log/supervisord 
# Switch to use a non-root user from here on
USER nobody


# Expose the port nginx is reachable on
EXPOSE 8080

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]

