#!/bin/bash
sudo pacman -S --noconfirm --needed cups cups-pdf bind-tools ntp
sudo systemctl enable ntpd.service
sudo systemctl start ntpd.service

