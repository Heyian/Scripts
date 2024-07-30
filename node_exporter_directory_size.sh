#!/usr/bin/env sh
#
# Expose directory usage metrics, passed as an argument.
#
# sed pattern taken from https://www.robustperception.io/monitoring-directory-sizes-with-the-textfile-collector/

echo "# HELP node_directory_size_bytes Disk space used by some directories"
echo "# TYPE node_directory_size_bytes gauge"
homedir="{your-home-dir}"
du --block-size=1 --summarize --exclude-from=$homedir/scripts/directory-size-exclusions.txt "$@" \
  | sed -ne 's/\\/\\\\/;s/"/\\"/g;s/^\([0-9]\+\)\t\(.*\)$/node_directory_size_bytes{directory="\2"} \1/p'
