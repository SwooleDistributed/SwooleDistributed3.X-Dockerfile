FROM centos:centos7

MAINTAINER gaowenfei

ENV SRC_DIR /usr/local
ENV PHP_VERSION 7.1.14
ENV SWOOLE_VERSION 4.0.3
ENV PHP_DIR /usr/local/php/${PHP_VERSION}
ENV PHP_INI_DIR /etc/php/${PHP_VERSION}/cli
ENV INIT_FILE ${PHP_INI_DIR}/conf.d
ENV HIREDIS_VERSION 0.13.3
ENV PHPREDIS_VERSION 3.1.6
ENV PHPDS_VERSION 1.2.4
ENV PHPINOTIFY_VERSION 2.0.0

#set ldconf
RUN echo "include /etc/ld.so.conf.d/*.conf" > /etc/ld.so.conf \
    && cd /etc/ld.so.conf.d \
    && echo "/usr/local/lib" > /etc/ld.so.conf.d/libc.conf
# tools
RUN yum -y install \
        wget \
        gcc \
        make \
        autoconf \
        libxml2 \
        libxml2-devel \
        openssl \
        openssl-devel \
        curl \
        curl-devel \
        pcre \
        pcre-devel \
        libxslt \
        libxslt-devel \
        bzip2 \
        bzip2-devel \
        libedit \
        libedit-devel \
        glibc-headers \
        gcc-c++ \
    && rm -rf /var/cache/{yum,ldconfig}/* \
    && rm -rf /etc/ld.so.cache \
    && yum clean all

# php
ADD install/php-${PHP_VERSION}.tar.gz ${SRC_DIR}/
RUN cd ${SRC_DIR}/php-${PHP_VERSION} \
    && ln -s /usr/lib64/libssl.so /usr/lib \
    && ./configure --prefix=${PHP_DIR} \
        --with-config-file-path=${PHP_INI_DIR} \
       	--with-config-file-scan-dir="${PHP_INI_DIR}/conf.d" \
       --disable-cgi \
       --enable-bcmath \
       --enable-mbstring \
       --enable-mysqlnd \
       --enable-opcache \
       --enable-pcntl \
       --enable-xml \
       --enable-zip \
       --with-curl \
       --with-libedit \
       --with-openssl \
       --with-zlib \
       --with-curl \
       --with-mysqli \
       --with-pdo-mysql \
       --with-pear \
       --with-zlib \
    && make clean > /dev/null \
    && make \
    && make install \
    && ln -s ${PHP_DIR}/bin/php /usr/local/bin/ \
    && ln -s ${PHP_DIR}/bin/phpize /usr/local/bin/ \
    && ln -s ${PHP_DIR}/bin/pecl /usr/local/bin/ \
    && ln -s ${PHP_DIR}/bin/php-config /usr/local/bin/ \
    && mkdir -p ${PHP_INI_DIR}/conf.d \
    && cp ${SRC_DIR}/php-${PHP_VERSION}/php.ini-production ${PHP_INI_DIR}/php.ini \
    && echo -e "opcache.enable=1\nopcache.enable_cli=1\nzend_extension=opcache.so" > ${PHP_INI_DIR}/conf.d/10-opcache.ini \
    && rm -f ${SRC_DIR}/php-${PHP_VERSION}.tar.gz \
    && rm -rf ${SRC_DIR}/php-${PHP_VERSION}

#  hiredis
ADD install/hiredis-${HIREDIS_VERSION}.tar.gz ${SRC_DIR}/
RUN cd ${SRC_DIR}/hiredis-${HIREDIS_VERSION} \
    && make clean > /dev/null \
    && make \
    && make install \
    && ldconfig \
    && rm -f ${SRC_DIR}/hiredis-${HIREDIS_VERSION}.tar.gz \
    && rm -rf ${SRC_DIR}/hiredis-${HIREDIS_VERSION}


#  swoole
ADD install/swoole-${SWOOLE_VERSION}.tar.gz ${SRC_DIR}/
RUN cd ${SRC_DIR}/swoole-src-${SWOOLE_VERSION} \
    && phpize \
    && ./configure --enable-async-redis --enable-openssl --enable-mysqlnd --enable-coroutine \
    && make clean > /dev/null \
    && make \
    && make install \
    && echo "extension=swoole.so" > ${INIT_FILE}/swoole.ini \
    && rm -f ${SRC_DIR}/swoole-${SWOOLE_VERSION}.tar.gz \
    && rm -rf ${SRC_DIR}/swoole-src-${SWOOLE_VERSION}

#  redis
ADD install/redis-${PHPREDIS_VERSION}.tar.gz ${SRC_DIR}/
RUN cd ${SRC_DIR}/phpredis-${PHPREDIS_VERSION} \
    && phpize \
    && ./configure \
    && make clean > /dev/null \
    && make \
    && make install \
    && echo "extension=redis.so" > ${INIT_FILE}/redis.ini \
    && rm -f ${SRC_DIR}/redis-${PHPREDIS_VERSION}.tar.gz \
    && rm -rf ${SRC_DIR}/phpredis-${PHPREDIS_VERSION}


#  ds
ADD install/ds-${PHPDS_VERSION}.tar.gz ${SRC_DIR}/
RUN cd ${SRC_DIR}/extension-${PHPDS_VERSION} \
    && phpize \
    && ./configure \
    && make clean > /dev/null \
    && make \
    && make install \
    && echo "extension=ds.so" > ${INIT_FILE}/ds.ini \
    && rm -f ${SRC_DIR}/ds-${PHPDS_VERSION}.tar.gz \
    && rm -rf ${SRC_DIR}/extension-${PHPDS_VERSION}


#  inotify
ADD install/inotify-${PHPINOTIFY_VERSION}.tar.gz ${SRC_DIR}/
RUN cd ${SRC_DIR}/php-inotify-${PHPINOTIFY_VERSION} \
    && phpize \
    && ./configure \
    && make clean > /dev/null \
    && make \
    && make install \
    && echo "extension=inotify.so" > ${INIT_FILE}/inotify.ini \
    && rm -f ${SRC_DIR}/inotify-${PHPINOTIFY_VERSION}.tar.gz \
    && rm -rf ${SRC_DIR}/php-inotify-${PHPINOTIFY_VERSION}


COPY ./config/* ${INIT_FILE}/
