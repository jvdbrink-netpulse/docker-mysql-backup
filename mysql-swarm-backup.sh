#!/bin/bash

#general settings:
label_prefix="netpulse.mysql-dump"
backup_path="/swarm/backups/mysql"


enabled_label_filter="$label_prefix.enable=true"
databases_label="$label_prefix.databases"
time_label="$label_prefix.schedule"

# get all running docker container names
containers=$(docker ps --filter="label=$enabled_label_filter" | awk '{if(NR>1) print $NF}')
host=$(hostname)

export_database_for_container () {
  time_match=$(docker inspect \
                        --format '{{ index .Config.Labels "'"$databases_label"'"}}' \
                        $1)

    if [ -z "$time_match" ]
    then
          echo "Exporting all databases for container: '$container'"
          docker exec $1 sh -c 'exec mysqldump --all-databases -uroot -p"$MYSQL_ROOT_PASSWORD"' > "$backup_path/$1.sql"
    else
          echo "Exporting database(s): '$time_match' for container: '$container'"
          docker exec $1 sh -c 'exec mysqldump --databases '"$time_match"' -uroot -p"$MYSQL_ROOT_PASSWORD"' > "$backup_path/$1.sql"
    fi
}

matches_cron () {

  echo "gg $2"

  MONTH=$(echo "$2" | awk '{ print $4 }')
  DAY=$(echo "$2" | awk '{ print $3 }')
  HOUR=$(echo "$2" | awk '{ print $2 }')
  MIN=$(echo "$2" | awk '{ print $1 }')

  CRONJOB_MIN=$(echo "$1" | awk '{ print $1 }')
  CRONJOB_HOUR=$(echo "$1" | awk '{ print $2 }')
  CRONJOB_DAY=$(echo "$1" | awk '{ print $3 }')
  CRONJOB_MONTH=$(echo "$1" | awk '{ print $4 }')

  if [ "$CRONJOB_MONTH" != "$MONTH" ] && [ "$CRONJOB_MONTH" != "*" ]
  then
    echo "month"
    return 1
  fi

  if [ "$CRONJOB_DAY" != "$DAY" ] && [ "$CRONJOB_DAY" != "*" ]
  then
    echo "day"
    return 1
  fi

  if [ "$CRONJOB_HOUR" != "$HOUR" ] && [ "$CRONJOB_HOUR" != "*" ]
  then
        echo "hour"
   return 1
  fi

  if [ "$CRONJOB_MIN" != "$MIN" ] && [ "$CRONJOB_MIN" != "*" ]
  then
    echo "min '$MIN' '$CRONJOB_MIN'"
    return 1
  fi

  return 0
}

#min hour day month

#NOW="$(date +'%-M') $(date +'%-H') $(date +'%-d') $(date +'%-m')"
NOW="0 2 $(date +'%-d') $(date +'%-m')"

echo $NOW

if matches_cron '0 * * 12 *' "$NOW"; then echo "is a match"; else echo "not a match"; fi
exit


# loop through all containers
for container in $containers
do
    echo '{{ index .Config.Labels "'"$time_label"'"}}'
    time_match=$(docker inspect \
                          --format '{{ index .Config.Labels "'"$time_label"'"}}' \
                          $container)

      if [ -z "$time_match" ]
      then
            echo "time_match: '$time_match'"
            # export_database_for_container $container
      else
            echo "not scheduled now"
      fi

done
