LFS_TGT="x86_64-lfs-linux-gnu"
cat > lfs_profile <<EOF
export LFS=/mnt/lfs
export LC_ALL=POSIX
export LFS_TGT=${LFS_TGT}
export PATH=/tools/bin:\$PATH
# End of profile
EOF