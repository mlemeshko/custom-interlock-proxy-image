#!/bin/sh

event="$1"
directory="$2"
file="$3"

echo $(date +%s) - $event - $directory - $file

case "$event" in
#u|o|x) # Inotify problems - kill nginx and let swarm respawn us
#   kill -9 1
#   ;;
w) # Any other change
   # may not want to have this copy
   # we need to exclude read and access because the copy triggers those
   # however with just W we weren't getting anything
   # an update being written into the volume seems to look
   # like c or w, or possibly dnrc.   Our copying the file looks like ra0
   echo Updating /run/secrets/ and /etc/nginx/nginx.conf
   # Pipe read blocks until config service is up. In case config service exits
   # while reading, repeat until file hashes match most recently validated config.
   # [TODO] additional improvements
   # - read into a temp dir and validate hashes there (config service early
   #   exit case)
   # - mv files out of that temp into /run/secrets (posix atomicity)
   # - remove stale cert files after nginx reload
   tar -C / -xf /out/nginx/pipe
   until sha256sum -c /out/nginx/hash/config.sha256 &>/dev/null; do
     echo Config hash validation error. Re-reading from config service.
     tar -C / -xf /out/nginx/pipe
   done
   echo "watch.sh: patching epro-controller upstream"
   sed -i '/upstream epro-controller\.dockerappv1\.pmli\.corp {/,/}/ s/server \([0-9.]*:[0-9]*\);/server \1 fail_timeout=0s max_fails=1000;/' /etc/nginx/nginx.conf
   nginx -s reload
   ;;
esac
