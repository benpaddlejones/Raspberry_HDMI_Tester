#!/bin/bash -e
# Install packages for HDMI testing
apt-get update
apt-get install -y --no-install-recommends $(cat /tmp/00-packages)
apt-get clean
rm -rf /var/lib/apt/lists/*
