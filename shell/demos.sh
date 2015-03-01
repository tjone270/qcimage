function backup_demos {
  rsync -v -e "ssh -o StrictHostKeyChecking=no -l $DEMOS_USER -i $DEMOS_KEY" $WINDOWS_DIR/Users/tourney-user/AppData/LocalLow/id\ Software/lan/home/baseq3/demos/* $DEMOS_USER@$DEMOS_SERVER:$DEMOS_PATH
}
