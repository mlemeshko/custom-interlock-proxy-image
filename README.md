# custom-interlock-proxy-image for specific upstream app

That custome image contains one modification in entrypoint.sh and watch.sh

## What have been done?

In short for every line in **/etc/nginx/nginx.conf** that contains the word server under upstream up-epro-controller.dockerappv1.pmli.corp block,
replace every ";" in that line with **"fail_timeout=0s max_fails=1000;"**,
and edit the file directly in place.”

###Details
Basically both entrypoint.sh and watch.sh have been taken from original ucp-interlock-proxy image and following lines were injected in each:
```
echo "entrypoint.sh: patching epro-controller upstream - adding fail_timeout and max_fails"
sed -i '/upstream \(up-\)\?epro-controller\.dockerappv1\.pmli\.corp {/,/}/ s/server \([0-9.]*:[0-9]*\);/server \1 fail_timeout=0s max_fails=1000;/' /etc/nginx/nginx.conf
```
combintaion of **fail_timeout=0s** and **max_fails=1000** means that Nginx does not mark **server** record under **upstream up-epro-controller.dockerappv1.pmli.corp** as down at all. The fail counter never “expires”. 
Having that - whenever nginx config is being updated right before nginx daemon does reload sed reccrod adjusts up-epro-controller.dockerappv1.pmli.corp upstream
