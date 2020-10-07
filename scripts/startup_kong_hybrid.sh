#!/bin/bash

# Install go-pluginserver
sudo chown nobody /usr/local/kong/

# Config configuration of kong
sudo mv /usr/conf/kong/kong.conf /etc/kong/kong.conf
sudo mv /usr/conf/kong/nginx-custom.conf /usr/local/nginx-custom.conf
sudo mv /usr/conf/kong/override.conf /etc/systemd/system/kong.service.d/override.conf

sudo systemctl daemon-reload
sudo systemctl enable kong
sudo systemctl restart kong
