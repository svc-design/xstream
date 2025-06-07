#!/bin/bash

set -e

launchctl remove com.xstream.xray-node-jp || true
launchctl remove com.xstream.xray-node-ca || true
launchctl remove com.xstream.xray-node-us || true

rm -f /opt/homebrew/bin/xray
rm -rf /opt/homebrew/etc/xray-vpn-node*

rm -rf ~/Library/LaunchAgents/com.xstream.*
rm -rf ~/Library/LaunchAgents/xstream*
rm -rf ~/Library/Application\ Support/xstream.svc.plus/*
