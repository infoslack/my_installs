#!/usr/bin/env bash

INSTALL_DIR="/opt/local"
VERSION=$2
APP_NAME="ruby"
URL="http://ftp.ruby-lang.org/pub/ruby/2.0/ruby-$VERSION.tar.bz2"
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
    apt-get install libyaml-dev libssl-dev libreadline-dev libxml2-dev libxslt1-dev libffi-dev

    mkdir -p "$SRC"
    cd "$SRC"

    [ ! -f "$TGZ" ] && wget $URL
    tar xvf $TGZ
    cd "ruby-$VERSION"

    ./configure --prefix=$PREFIX --disable-install-rdoc

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
