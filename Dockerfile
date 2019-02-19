FROM ubuntu:16.04 as builder

LABEL maintainer="Alan <ssisoo@live.cn>"

ARG PHP_URL=https://php.net/get/php-7.2.15.tar.gz/from/a/mirror
ARG PHP_VERSION=php-7.2.15
ARG PHP_PACKAGE=mirror
ARG LIB_LIST="libxml2-dev libssl-dev libbz2-dev libpng-dev libxslt1-dev libcurl4-openssl-dev libzip-dev libzip4"

RUN apt-get update -y
RUN apt-get install -y gcc g++ autoconf make file bison curl git zip unzip ${LIB_LIST}
RUN ln -s /usr/lib/x86_64-linux-gnu/libssl.so /usr/lib

# 以下下载链接失效可以到 https://github.com/maeteno/php-software-package 获取备份
# re2c php 编译需要
ADD https://nchc.dl.sourceforge.net/project/re2c/0.16/re2c-0.16.tar.gz /home/
ADD ${PHP_URL} /home/
ADD https://pecl.php.net/get/redis-4.2.0.tgz /home/
ADD https://pecl.php.net/get/mongodb-1.5.3.tgz /home/
ADD https://pecl.php.net/get/swoole-4.2.13.tgz /home/
ADD http://apache.01link.hk/zookeeper/zookeeper-3.4.13/zookeeper-3.4.13.tar.gz /home/
ADD https://pecl.php.net/get/zookeeper-0.6.3.tgz /home/

WORKDIR /home/

RUN cd /home/ \
    && tar -zxf /home/re2c-0.16.tar.gz -C /home/ \
    && tar -zxf /home/${PHP_PACKAGE} -C /home/ \
    && tar -zxf /home/redis-4.2.0.tgz -C /home/ \
    && tar -zxf /home/mongodb-1.5.3.tgz -C /home/ \
    && tar -zxf /home/swoole-4.2.13.tgz -C /home/ \
    && tar -zxf /home/zookeeper-3.4.13.tar.gz -C /home/ \
    && tar -zxf /home/zookeeper-0.6.3.tgz -C /home/ \
    && ls -al /home/

RUN cd /home/re2c-0.16/ \
    && ./configure \
    && make \
    && make install 

RUN cd /home/${PHP_VERSION}/ &&\
    ./configure \
    --prefix=/usr/local/php \
    --with-config-file-path=/usr/local/php/etc \
    --enable-zip \
    --enable-bcmath \
    --enable-exif \
    --enable-cli \
    --enable-intl \
    --enable-mbstring \
    --enable-pcntl \
    --enable-soap \
    --enable-sysvmsg \
    --enable-sysvsem \
    --enable-sysvshm \
    --enable-mysqlnd \
    --enable-sockets \
    --enable-opcache \
    --disable-cgi \
    --with-openssl \
    --with-zlib \
    --with-curl \
    --with-bz2 \
    --with-openssl \
    --with-gd \
    --with-mysqli \
    --with-xsl \
    --with-pdo-mysql \
    && make \
    && make install \
    && cp php.ini-production /usr/local/php/etc/php.ini 

ENV PATH=$PATH:/usr/local/php/bin

RUN cd /home/redis-4.2.0/ \
    && phpize && ./configure && make && make install \
    && echo "extension=redis.so" >> /usr/local/php/etc/php.ini

RUN cd /home/mongodb-1.5.3/ \
    && phpize && ./configure && make && make install \
    && echo "extension=mongodb.so" >> /usr/local/php/etc/php.ini

RUN cd /home/swoole-4.2.13/ \
    && phpize && ./configure --enable-sockets --enable-openssl --enable-mysqlnd \
    && make && make install \
    && echo "extension=swoole.so" >> /usr/local/php/etc/php.ini

RUN cd /home/zookeeper-3.4.13/src/c \
    && ./configure --prefix=/usr/local/zookeeper \
    && make && make install 

RUN cd /home/zookeeper-0.6.3/ \
    && phpize && ./configure --with-libzookeeper-dir=/usr/local/zookeeper \
    && make && make install \
    && echo "extension=zookeeper.so" >> /usr/local/php/etc/php.ini

# 运行阶段
FROM ubuntu:16.04

LABEL maintainer="Alan <ssisoo@live.cn>"

ARG LIB_LIST="libxml2-dev libssl-dev libbz2-dev libpng-dev libxslt1-dev libcurl4-openssl-dev libzip-dev"

RUN apt-get update -y \
    && ${LIB_LIST} \
    && ln -s /usr/lib/x86_64-linux-gnu/libssl.so /usr/lib

# 从编译阶段的中拷贝编译结果到当前镜像中
COPY --from=builder /usr/local/php /usr/local/php 
COPY --from=builder /usr/local/zookeeper /usr/local/zookeeper 

ENV PATH=$PATH:/usr/local/php/bin 

CMD ["/bin/sh"]
