cat > config.mk <<EOF
INSTALL_DIR = /usr/local/bin
EOF

cat config.mk

sed -i 's@/usr/local/bin@/tools/bin@g' config.mk

cat config.mk