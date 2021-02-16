#!/bin/sh
TARGET=$1
while true; do
wget -O - -q http://${TARGET}
sleep 0.01; done
