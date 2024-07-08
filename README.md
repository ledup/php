# php-fpm container

Docker image for php-fpm made to use with led.

## Available versions

### CentOS 7

| Tag     | Description |
|---------|-------------|
| **5.6** | PHP 5.6.40  |
| **7.0** | PHP 7.0.33  |
| **7.1** | PHP 7.1.33  |
| **7.2** | PHP 7.2.34  |
| **7.3** | PHP 7.3.33  |
| **7.4** | PHP 7.4.33  |
| **8.0** | PHP 8.0.30  |
| **8.1** | PHP 8.1.29  |
| **8.2** | PHP 8.2.21  |
| **8.3** | PHP 8.3.9   |

### RockyLinux

| Tag         | Description |
|-------------|-------------|
| **8.1-rl9** | PHP 8.1.29  |
| **8.2-rl9** | PHP 8.2.21  |
| **8.3-rl9** | PHP 8.3.9   |

## Includes

- Composer 2.x
- Git
- Make 3.82
- Wkhtmltopdf 0.12.6

### PECL

```
AMQP
AST
APCu
Imagick
pecl_HTTP
lz4
mailparse
memcached
mongodb
maxminddb
pcov
redis
ssh2
XDebug
```

(+ `sqlsrv` with some tags)


- XDebug is disabled by default. Set an environment variable `PHP_XDEBUG` setted to 1
- PCOV is disabled by default. Set an environment variable `PHP_PCOV` setted to 1

The container will exit if Xdebug and PCOV are enabled together

## Usage

**By default, the image launch PHP-FPM in foreground**

```
docker run -it --rm ledup/php:*tag*
```

**To override command**

```
docker run -it --rm ledup/php:*tag* bash
```

**To override PHP memory limit**

```
docker run -it -e PHP_MEMORY_LIMIT=1024M --rm ledup/php:*tag* php -i | grep memory_limit
```

## Logs

Daemon output is redirected to stderr to be readable from container's log with `docker logs [container_name]`

## Misc

In this images, `composer` is wrapped to a shell function which disable XDebug on-the-fly if enabled
