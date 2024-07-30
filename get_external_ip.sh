#!/bin/bash

curl -s --connect-timeout 5 http://ifconfig.me > /var/log/externalip.log
