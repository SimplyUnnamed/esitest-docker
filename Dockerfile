FROM php:7.4-apache

LABEL maintainer="Lars Gullstrup" \
	  name="esitest-docker" \
	  version="1.1.3"

RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        wget zip unzip mariadb-client redis-tools git \
        libgmp-dev libzip-dev libpq-dev libbz2-dev libicu-dev libfreetype6-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


RUN pecl install redis && \
        docker-php-ext-configure gd \
        --with-freetype && \
    docker-php-ext-install zip pdo pdo_mysql gd bz2 gmp pcntl opcache && \
    docker-php-ext-enable redis

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin \
    --filename=composer && hash -r

ENV COMPSER_MEMORY_LIMIT -1

RUN cd /var/www && \
	composer create-project simplyunnamed/esitest=^1.1 --no-scripts --stability dev --no-ansi --no-progress && \
    composer clear-cache --no-ansi && \
    chown -R www-data:www-data /var/www/esitest && \
    cd /var/www/esitest && \
    php -r "file_exists('.env') || copy('.env.example', '.env');" && \
    php artisan key:generate
	
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

RUN wget http://curl.haxx.se/ca/cacert.pem --directory-prefix=/usr/local/etc && \
	wget https://www.websecurity.digicert.com/content/dam/websitesecurity/digitalassets/desktop/pdfs/roots/Class-3-Public-Primary-Certification-Authority.pem --directory-prefix=/usr/local/etc/ && \
    cat /usr/local/etc/Class-3-Public-Primary-Certification-Authority.pem >> /usr/local/etc/php/cacert.pem && \
    rm /usr/local/etc/Class-3-Public-Primary-Certification-Authority.pem && \
	sed -i 's/^.*curl.cainfo.*$/curl.cainfo =\/usr\/local\/etc\/cacert.pem/' /usr/local/etc/php/php.ini

RUN rmdir /var/www/html && \
    ln -s /var/www/esitest/public /var/www/html

RUN a2enmod rewrite
EXPOSE 80
WORKDIR /var/www/esitest

COPY startup.sh /startup.sh
COPY version /var/www/esitest/storage/version
RUN chmod +x /startup.sh


ENTRYPOINT ["/startup.sh"]
