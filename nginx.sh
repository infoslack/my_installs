#!/usr/bin/env bash

INSTALL_DIR="/opt/local"
VERSION=$2
APP_NAME="nginx"
URL="http://nginx.org/download/nginx-$VERSION.tar.gz"
PREFIX="$INSTALL_DIR/$APP_NAME/$VERSION"
CURRENT="$INSTALL_DIR/$APP_NAME/current"
SRC="$INSTALL_DIR/src"
TGZ="$SRC/$(basename $URL)"
COMMAND=$1

if [ $UID != 0 ]; then
  echo "Sorry, you are not root."
  exit 1
elif [[ -z "$COMMAND" ]]; then
  ${0} help
  exit 1
elif [[ -z "$VERSION" && "$COMMAND" != "help" && "$COMMAND" != "deactivate" ]]; then
  ${0} help
fi

case "$COMMAND" in
  install)
    mkdir -p "$SRC"
    cd "$SRC"

    apt-get install libpcre3-dev libssl-dev

    [ ! -f "$TGZ" ] && wget $URL
    tar xvf $TGZ
    cd nginx-$VERSION

    ./configure --prefix=$PREFIX \
      --with-http_ssl_module --with-http_realip_module \
      --with-http_gzip_static_module --conf-path=/etc/nginx/nginx.conf \
      --error-log-path=/var/log/nginx/error.log --pid-path=/var/run/nginx.pid \
      --lock-path=/var/lock/nginx.lock --http-log-path=/var/log/nginx/access.log \
      --http-client-body-temp-path=/var/lib/nginx/body \
      --http-proxy-temp-path=/var/lib/nginx/proxy \
      --http-fastcgi-temp-path=/var/lib/nginx/fastcgi --with-debug --with-ipv6

    make
    make install
  ;;

  activate)
    if [[ ! -d $PREFIX ]]; then
      ${0} install $VERSION
    fi

    ${0} deactivate

    ln -s "$PREFIX" "$CURRENT"

    for dir in bin sbin
    do
      [ ! -d "$CURRENT/$dir" ] && continue
      mkdir -p "$INSTALL_DIR/$dir"

      for file in `ls $CURRENT/$dir`
      do
        bin=$(basename $file)
        ln -s "$CURRENT/$dir/$bin" "$INSTALL_DIR/$dir/$bin"
      done
    done
  ;;

  deactivate)
    if [[ ! -L "$CURRENT" ]]; then
      exit
    fi

    for dir in bin sbin
    do
      [ ! -d "$CURRENT/$dir" ] && continue

      for file in `ls $CURRENT/$dir`
      do
        bin=$(basename $file)
        [ -L "$INSTALL_DIR/$dir/$bin" ] && rm "$INSTALL_DIR/$dir/$bin"
      done
    done

    rm "$CURRENT"
  ;;

  *)
    echo "Usage: ${0} {install|uninstall|activate|deactivate|help} {version}" >&2
    exit 3
  ;;
esac

:
