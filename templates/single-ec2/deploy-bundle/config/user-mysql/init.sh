#!/bin/sh
set -eu

mysql --protocol=socket -uroot -p"${MYSQL_ROOT_PASSWORD}" <<SQL
USE \`${MYSQL_DATABASE}\`;
SOURCE /schema/user-schema.sql;
SQL
