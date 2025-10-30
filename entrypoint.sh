#!/bin/sh

# Kill all processes in this process group if any one of them exits
trap 'kill 0' CHLD

# Read in config at startup
if [ -e /out/nginx/nginx.conf ]; then
  # HitlessServiceUpdate = false
  cp /out/nginx/nginx.conf /etc/nginx/nginx.conf
else
  # HitlessServiceUpdate = true
  # Pipe read blocks until config service is up. In case config service exits
  # while reading, repeat until file hashes match most recently validated config.
  if [ ! -p /out/nginx/pipe ]; then
    mkfifo /out/nginx/pipe
  fi
  tar -C / -xf /out/nginx/pipe
  until sha256sum -c /out/nginx/hash/config.sha256 &>/dev/null; do
    echo Config hash validation error. Re-reading from config service.
    tar -C / -xf /out/nginx/pipe
  done
fi
echo "entrypoint.sh: patching epro-controller upstream"
sed -i '/upstream epro-controller\.dockerappv1\.pmli\.corp {/,/}/ s/server \([0-9.]*:[0-9]*\);/server \1 fail_timeout=0s max_fails=1000;/' /etc/nginx/nginx.conf
# Start inotifyd and nginx in the background - this shell will wait
# for both of them to exit
mkdir -p /out/nginx/hash
inotifyd /watch.sh /out/nginx/hash &
if [ -z "$@" ]; then
  nginx -g "daemon off;" &
else
  "$@" &
fi
NGINX=$!

# Shut down nginx gracefully if we receive SIGTERM or SIGQUIT
trap 'kill -QUIT $NGINX && wait' TERM QUIT

# Block until all child processes exit.   If any child exits, the signal
# will be trapped and all will be killed.
wait
