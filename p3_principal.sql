create extension if not exists postgres_fdw ;

create server remote_server foreign data wrapper postgres_fdw
options (host 'db2', dbname 'remote_db', port '5432') ;

create user mapping for current_user server remote_server
options (user 'remote_user', password '123') ;

create schema local_schema ;

import foreign schema remote_schema from server remote_server into local_schema ;
