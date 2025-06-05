#!/bin/bash

NODES=("us" "ca" "tky")
PLIST_DIR="$HOME/Library/LaunchAgents"

mkdir -p "$PLIST_DIR"

for node in "${NODES[@]}"; do
  cat > "$PLIST_DIR/com.xstream.xray-node-${node}.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.xstream.xray-node-${node}</string>
  <key>ProgramArguments</key>
  <array>
    <string>/opt/homebrew/bin/xray</string>
    <string>run</string>
    <string>-c</string>
    <string>/opt/xray/etc/xray-vpn-${node}-node.json</string>
  </array>
  <key>StandardOutPath</key>
  <string>/tmp/xray-vpn-${node}-node.log</string>
  <key>StandardErrorPath</key>
  <string>/tmp/xray-vpn-${node}-node.err</string>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
</dict>
</plist>
EOF
done

echo "✅ 所有 .plist 文件已生成到 $PLIST_DIR"

