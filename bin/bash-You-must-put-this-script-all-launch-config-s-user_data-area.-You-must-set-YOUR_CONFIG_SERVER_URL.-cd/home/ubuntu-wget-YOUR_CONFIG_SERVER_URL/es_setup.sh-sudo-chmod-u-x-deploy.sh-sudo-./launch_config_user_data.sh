#!/bin/bash
# You must put this script all launch config's user_data area.
# You must set YOUR_CONFIG_SERVER_URL.

cd /home/ubuntu
wget YOUR_CONFIG_SERVER_URL/es_setup.sh
sudo chmod u+x deploy.sh
sudo ./deploy.sh
