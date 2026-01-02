#!/bin/bash

sh ./install_certbot.sh
sh ./install_nginx.sh

certbot certonly --dns-cloudflare --dns-cloudflare-credentials /.secrets/cloudflare.ini --dns-cloudflare-propagation-seconds 60 -d '<this_should_be_replaced_by_root_domain>,*.<this_should_be_replaced_by_root_domain>' --key-type ecdsa --elliptic-curve secp256r1 -i nginx --auto-hsts
# certbot certonly --dns-digitalocean --dns-digitalocean-credentials /.secrets/digitalocean.ini --dns-digitalocean-propagation-seconds 60 -d '<this_should_be_replaced_by_root_domain>,*.<this_should_be_replaced_by_root_domain>' --key-type ecdsa --elliptic-curve secp256r1 -i nginx --auto-hsts

rm /etc/nginx/nginx.conf && ln -s ./nginx/nginx.conf /etc/nginx/nginx.conf
ln -s ./nginx/conf.d/ /etc/nginx/conf.d/

nginx -t

bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

cp ./xray/config.json /usr/local/etc/xray/config.json

systemctl restart nginx
systemctl restart xray
