#!/bin/sh
set -e

### BEGIN INIT INFO
# Provides:   postgresql
# Required-Start: $local_fs $remote_fs $network $time
# Required-Stop:  $local_fs $remote_fs $network $time
# Should-Start:   $syslog
# Should-Stop:    $syslog
# Default-Start:  2 3 4 5
# Default-Stop:   0 1 6
# Short-Description:  PostgreSQL RDBMS server
### END INIT INFO

# Setting environment variables for the postmaster here does not work; please
# set them in /etc/postgresql/<version>/<cluster>/environment instead.

[ -r /usr/share/postgresql-common/init.d-functions ] || exit 0

. /usr/share/postgresql-common/init.d-functions

# versions can be specified explicitly
if [ -n "$2" ]; then
    versions="$2 $3 $4 $5 $6 $7 $8 $9"
else
    get_versions
fi

case "$1" in
    start|stop|restart|reload)
  if [ -z "`pg_lsclusters -h`" ]; then
      log_warning_msg 'No PostgreSQL clusters exist; see "man pg_createcluster"'
      exit 0
  fi
  for v in $versions; do
      $1 $v || EXIT=$?
  done
  exit ${EXIT:-0}
        ;;
    status)
  LS=`pg_lsclusters -h`
  # no clusters -> unknown status
  [ -n "$LS" ] || exit 4
  echo "$LS" | awk 'BEGIN {rc=0} {if (match($4, "down")) rc=3; printf ("%s/%s (port %s): %s\n", $1, $2, $3, $4)}; END {exit rc}'
  ;;
    force-reload)
  for v in $versions; do
      reload $v
  done
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|reload|force-reload|status} [version ..]"
        exit 1
        ;;
esac

exit 0

