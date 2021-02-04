FROM docker.io/library/php:7.4-fpm-alpine

WORKDIR /var/www/html

# Install dependencies
RUN apk update && apk add --no-cache \
    mysql-client \
    freetype libpng libjpeg-turbo freetype-dev libpng-dev libjpeg-turbo-dev \
    icu-libs \
    jpegoptim optipng pngquant gifsicle \
    oniguruma-dev \
    composer \
    supervisor \
    apache2 \
    apache2-ctl \
    apache2-proxy

# Installing extensions
RUN docker-php-ext-install mysqli pdo_mysql mbstring exif pcntl pdo bcmath
RUN docker-php-ext-configure gd --with-jpeg=/usr/include/
RUN docker-php-ext-install gd

COPY . .
RUN apk update && apk add nodejs npm && \
    npm install && \
    COMPOSER_ALLOW_SUPERUSER=1 composer install && \
    ./node_modules/grunt/bin/grunt Build-All && \
    apk del nodejs npm composer

RUN chown www-data -R .

COPY ./docker/start.sh /start.sh
RUN chmod +x /start.sh

COPY docker/custom.ini /usr/local/etc/php/conf.d/custom.ini

# Configure supervisord
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY docker/app.conf  /etc/apache2/conf.d/app.conf

RUN sed -i '/LoadModule rewrite_module/s/^#//g' /etc/apache2/httpd.conf && \
    sed -i 's#AllowOverride [Nn]one#AllowOverride All#' /etc/apache2/httpd.conf && \
    sed -i '$iLoadModule proxy_module modules/mod_proxy.so' /etc/apache2/httpd.conf

RUN mkdir -p "/sessions" && chown www-data:www-data /sessions && chmod 0777 /sessions
VOLUME [ "/sessions" ]

# Expose port 9000 and start php-fpm server
ENTRYPOINT ["/start.sh"]
EXPOSE 80
