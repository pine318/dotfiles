#!/bin/bash

sudo apt -y install language-pack-ja
sudo update-locale LANG=ja_JP.UTF8
sudo ln -fs /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
sudo dpkg-reconfigure --frontend noninteractive tzdata
sudo apt -y install manpages-ja manpages-ja-dev
exit