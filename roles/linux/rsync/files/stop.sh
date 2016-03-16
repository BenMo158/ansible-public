#!/bin/bash

stop_client(){
kill -9 $(ps -ef | egrep -v 'root|grep' |  grep rsync | awk '{print $2}')
exit 0
}

stop_client
