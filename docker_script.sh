mkdir app
  mkdir php &&
    printf "what is the name of your project directory?" &&
    read dir_name &&
    printf "FROM php:8.3-fpm
          \nRUN apt update   \\
            && apt install -y zlib1g-dev g++ git libicu-dev zip libzip-dev zip \\
            && docker-php-ext-install intl opcache pdo pdo_mysql \\
            && pecl install apcu \\
            && docker-php-ext-enable apcu \\
            && docker-php-ext-configure zip \\
            && docker-php-ext-install zip
WORKDIR /var/www/$dir_name
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN curl -sS https://get.symfony.com/cli/installer | bash
RUN git config --global user.email \"YourEmailAdres@gmail.com\" \\
        && git config --global user.name  \"Yourname\"  " >>php/Dockerfile

  mkdir nginx &&
    printf 'server {

    listen 80;
    index index.php;
    server_name localhost;
    root /var/www/%s/public;
    error_log /var/log/nginx/project_error.log;
    access_log /var/log/nginx/project_access.log;

    location / {
        try_files  $uri /index.php$is_args$args;
    }

    location ~ ^/index\\\\.php(/|$) {
        fastcgi_pass php:9000;
        fastcgi_split_path_info ^(.+\\\\.php)(/.*)$;
        include fastcgi_params;

        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        fastcgi_param DOCUMENT_ROOT $realpath_root;

        fastcgi_buffer_size 128k;
        fastcgi_buffers 4 256k;
        fastcgi_busy_buffers_size 256k;

        internal;
    }

    location ~ \\\\.php$ {
        return 404;
    }

}' $dir_name >>nginx/default.conf

  printf "
version: '3.3'

services:
  database:
    container_name: database-$dir_name
    image: mysql:8.0
    restart: always
    command: --default-authentication-plugin=mysql_native_password
    environment:
      MYSQL_ROOT_PASSWORD: your_password
      MYSQL_DATABASE: %s
      MYSQL_USER: your_user
      MYSQL_PASSWORD: your_password
    ports:
      - '4306:3306'
    volumes:
      - ./mysql:/var/lib/mysql

  php:
    container_name: php-$dir_name
    build:
      context: ./php
    ports:
      - '9000:9000'
    volumes:
      - ./app:/var/www/%s

    depends_on:
      - database

  nginx:
    container_name: nginx-$dir_name
    image: nginx:stable-alpine
    ports:
      - '8080:80'
    volumes:
      - ./app:/var/www/%s
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf
    depends_on:
      - php
      - database
" $dir_name $dir_name $dir_name >>./docker-compose.yml