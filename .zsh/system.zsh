# GNU time
alias time='/usr/bin/time -f "CPU:%P Memory:%M KB Time:%E"'

# LANG setting
case $TERM in
  linux) LANG=C;;
  *)     LANG=ja_JP.UTF-8;;
esac

# directory background color
LS_COLORS="${LS_COLORS}:ow=01;34"; export LS_COLORS
