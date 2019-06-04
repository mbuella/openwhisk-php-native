FROM openwhisk/dockerskeleton:latest as php-build

## php version
ARG PHP_VERSION=7.2.18

## install pre-build deps
RUN apk update && apk add \
    bison \
    gcc \
    re2c \
    autoconf \
    automake \
    make \
    libc-dev \
    libtool \
    libxml2-dev \
    openssl-dev \
    libpng-dev \
    jpeg-dev \
    curl-dev

## download php source code
RUN curl -sL https://github.com/php/php-src/archive/php-$PHP_VERSION.tar.gz | tar -zxv
WORKDIR ./php-src-php-$PHP_VERSION

## build php from source
RUN ./buildconf --force && ./configure \
    --enable-static=yes \
    --enable-shared=no \
    --enable-hash \
    --enable-json \
    --enable-libxml \
    --enable-mbstring \
    --enable-phar \
    --enable-soap \
    --enable-xml \
    --with-curl \
    --with-gd \
    --with-zlib \
    --with-openssl \
    --without-pear \
    --enable-ctype \
    --enable-cgi \
    --with-mysqli=mysqlnd \
    --with-pdo-mysql=mysqlnd \
    --enable-opcache \
    --enable-bcmath \
    --enable-exif \
    --enable-zip \
    --enable-opcache-file \
    --with-config-file-path=/var/task/
RUN make install


# build perl handler for php
FROM openwhisk/dockerskeleton:latest as php-perl-build

## install pre-build deps
RUN apk del perl && apk update && \
    apk add make build-base perl-dev perl-app-cpanminus
RUN cpanm Encode JSON JSON::Create IPC::Run pp

# copy handler.pl
WORKDIR /tmp/php-perl-build
COPY handler.pl .

## execute build of php handler
RUN pp -o exec handler.pl && chmod +x exec


# Build php base image
FROM openwhisk/dockerskeleton:latest

# get php executables
COPY --from=php-build /usr/local/bin/php /usr/local/bin
COPY --from=php-build /usr/local/bin/php-cgi /usr/local/bin

# get the php handler executable
COPY --from=php-perl-build  /tmp/php-perl-build/exec /action/exec

# copy php source files
COPY ./www /var/www

# Install php shared libraries
RUN apk update && apk add libpng libxml2

# Run openwhisk action proxy
CMD ["/bin/bash", "-c", "cd actionProxy && python -u actionproxy.py"]
