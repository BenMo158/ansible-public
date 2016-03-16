#!/bin/bash
rsync_user={{ auth_users }}
peer_ip={{ peer_ip }}
rsync_module={{ module_name }}
log_file={{ client_log }}
secrets_file={{ client_secrets_file }}
dirs_to_sync=$1

#---------- main part of scprits ----------------#

module_path={{ module_path }}
rsync_daemon_opts="-pthr --log-file=$log_file --password-file=$secrets_file "

rsync_by_daemon(){
    dir=$1
    username=$2
    des=`echo "$1" |sed -e "s#$module_path##g"`
    host=$3
    module=$4
    file=$5
    is_dir=`echo $event | grep 'ISDIR'`
    [ $event = CREATE ]||rsync $rsync_daemon_opts $dir$file $username@$host::$module/$des
}
do_watch(){
    dirs_to_sync=$1
    #events="create,attrib,modify,move,close_write"
    events="create,attrib,move,close_write"
    exclude_pattern="/.+\.tmp$|/.+\.lock$|/\.[^/]+"
    timefmt="--timefmt '%Y-%m-%dT%H:%M'"
    /usr/bin/inotifywait -mrq $timefmt --format '%T %e %w %f' -e $events  --excludei "$exclude_pattern"  --fromfile $dirs_to_sync | while read datetime event dir file
    do
    #[ -s $file ]&&rsync_by_daemon  $dir $rsync_user $peer_ip $rsync_module $file
    #lsof |grep ${file}||
    rsync_by_daemon  $dir $rsync_user $peer_ip $rsync_module $file
    done
}

# sync all
while read line
do
    # display $line or do somthing with $line
    relative_path="`echo $line | sed "s#${module_path}##"`"
    relative_path=`dirname $relative_path`
    rsync $rsync_daemon_opts $line $rsync_user@$peer_ip::$rsync_module$relative_path
done <"$dirs_to_sync"
do_watch $dirs_to_sync
