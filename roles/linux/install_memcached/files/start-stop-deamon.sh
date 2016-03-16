#/bin/bash
PACK_NAME=start-stop-deamon.tar.gz
BASE_PATH=/tmp/start-stop-deamon

/bin/tar xf $PACK_NAME -C /tmp/
/bin/cd $BASE_PATH
/usr/bin/cc start-stop-daemon.c -o start-stop-daemon
/bin/cp start-stop-daemon /sbin/

