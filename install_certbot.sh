#!/bin/bash

snap install --classic certbot
snap set certbot trust-plugin-with-root=ok
# snap install certbot-dns-cloudflare
snap install certbot-dns-digitalocean

mkdir /root/.secrets
cp ../letsencrypt/dns_tokens.ini /root/.secrets/dns_tokens.ini
chmod 700 /root/.secrets/dns_tokens.ini

ln -s /snap/bin/certbot /usr/local/bin/certbot
