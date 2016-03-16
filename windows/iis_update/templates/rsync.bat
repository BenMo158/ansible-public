@echo off

   set RSYNC_HOME=C:\Program Files (x86)\cwRsync\bin
   cd %RSYNC_HOME%
   
rsync.exe -arPO --force --bwlimit=40000 --exclude "*.log" --exclude ".svn" --password-file=/cygdrive/D/script_temp/password.txt --port 873  {{ rsync.user }}@{{ rsync.ip }}::update_temp/{{ site_path }}/ /cygdrive/d/iisroot/{{ site_path }}
icacls {{ physicalpath }} /t /c /inheritance:e /grant:r SYSTEM:(oi)(ci)f administrators:(oi)(ci)f IIS_IUSRS:(oi)(ci)f Users:(oi)(ci)(RD,RC,W)
