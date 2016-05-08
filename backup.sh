#!/bin/bash

set -e

MYSQL_HOST=${MYSQL_HOST:-localhost}
MYSQL_USER=${MYSQL_USER:-backup}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-backup}
BACKUP_DIR=${BACKUP_DIR:-./backup}

CONFIG_PATH=/tmp/.backup-mysql.cnf

cat > ${CONFIG_PATH} <<EOF
[client]
    user=${MYSQL_USER}
    password=${MYSQL_PASSWORD}
    host=${MYSQL_HOST}
EOF

chmod 400 ${CONFIG_PATH}
unset MYSQL_PASSWORD

databases=`mysql --defaults-file=${CONFIG_PATH} -e "SHOW DATABASES;" | tr -d "| " | grep -v Database`

for db in $databases; do
    if [[ "$db" != "information_schema" ]] && [[ "$db" != "performance_schema" ]] && [[ "$db" != _* ]] ; then
        echo "Dumping database: $db"
        mysqldump --defaults-file=${CONFIG_PATH} --events --force --opt --databases ${db} > ${BACKUP_DIR}/${db}.sql
        rm -f ${BACKUP_DIR}/${db}.sql.gz
        gzip ${BACKUP_DIR}/${db}.sql
        chmod 600 ${BACKUP_DIR}/${db}.sql.gz
    fi
done

rm ${CONFIG_PATH}

exit 0
