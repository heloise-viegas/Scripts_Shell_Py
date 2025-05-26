#!/bin/bash
   # Clean system cache
   sudo sync && echo 3 | sudo tee /proc/sys/vm/drop_caches

   # Clean temporary files
   sudo rm -rf /tmp/*

   echo "Cleanup completed at $(date)"

   LOG_DIR="/var/log"
DAYS=7

sudo find $LOG_DIR -type f -name "*.log" -mtime +$DAYS -exec rm -f {} \;
echo "Old log files deleted from $LOG_DIR at $(date)"