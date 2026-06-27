create extension if not exists postgres_fdw;
create extension if not exists dblink;

create server if not exists worker_1 foreign data wrapper postgres_fdw
options (host 'worker_1', dbname 'remote_db', port '5432');

create server if not exists worker_2 foreign data wrapper postgres_fdw
options (host 'worker_2', dbname 'remote_db', port '5432');

create server if not exists worker_3 foreign data wrapper postgres_fdw
options (host 'worker_3', dbname 'remote_db', port '5432');

create user mapping if not exists for current_user server worker_1
options (user 'remote_user', password '123');

create user mapping if not exists for current_user server worker_2
options (user 'remote_user', password '123');

create user mapping if not exists for current_user server worker_3
options (user 'remote_user', password '123');

import foreign schema remote_schema from server worker_1 into local_schema;
import foreign schema remote_schema from server worker_2 into local_schema;
import foreign schema remote_schema from server worker_3 into local_schema;

select dblink_connect('worker_1', 'host=worker_1 port=5432 dbname=remote_db user=postgres password=123');
select dblink_connect('worker_2', 'host=worker_2 port=5432 dbname=remote_db user=postgres password=123');
select dblink_connect('worker_3', 'host=worker_3 port=5432 dbname=remote_db user=postgres password=123');

create or replace function create_atencionmedica_partition_if_not_exists (Diagnostico varchar (50))
returns void as $$
declare
    partition_name text;
begin
    partition_name := 'AtencionMedica_' || Diagnostico;

    if not exists (
        select 1
        from pg_class c
        join pg_namespace  n on c.relnamespace = n.oid
        where relname = partition_name and n.nspname = 'local_schema'
    ) then
        perform dblink_exec('worker_1', format('create table remote_schema.%I (like remote_schema.atencionmedica_example)', partition_name));
        execute format('create foreign table local_schema.%I partition of local_schema.atencionmedica for values in (%L) server worker_1 options (schema_name ''remote_schema'', table_name %L)', partition_name, Diagnostico, partition_name);
        raise notice 'Partición % creada para el diagnóstico %', partition_name, Diagnostico;
    else 
        raise notice 'Partición % ya existe', partition_name;
    end if;
end;
$$ language plpgsql;

create or replace function insert_into_atencionmedica_with_partition_creation (
    DNI char (8),
    CodMedico integer,
    Ciudad varchar (50),
    Diagnostico varchar (50),
    Peso decimal (5, 2),
    Talla decimal (4, 2),
    PresionArterial varchar (10),
    Edad integer,
    FechaAtencion date
) returns void as $$
begin
    perform create_atencionmedica_partition_if_not_exists(Diagnostico);

    insert into local_schema.atencionmedica
        (dni, codmedico, ciudad, diagnostico, peso, talla, presionarterial, edad, fechaatencion)
        values (dni, codmedico, ciudad, diagnostico, peso, talla, presionarterial, edad, fechaatencion);
end;
$$ language plpgsql;

select insert_into_atencionmedica_with_partition_creation
    ('45781236', 101, 'Lima',   'Diabetes',      70.00, 1.65, '130/85', 45, '2025-01-15');
select insert_into_atencionmedica_with_partition_creation
    ('08569321', 102, 'Lima',   'Hipertensión',  85.00, 1.72, '150/95', 60, '2025-01-16');
select insert_into_atencionmedica_with_partition_creation
    ('72103654', 101, 'Callao', 'Obesidad',      90.00, 1.60, '140/90', 35, '2025-01-17');
select insert_into_atencionmedica_with_partition_creation
    ('25963147', 103, 'Callao', 'Cardiopatía',   78.00, 1.75, '145/92', 50, '2025-01-18');
select insert_into_atencionmedica_with_partition_creation
    ('15478962', 101, 'Lima',   'Diabetes',      65.00, 1.58, '125/82', 42, '2025-01-19');
select insert_into_atencionmedica_with_partition_creation
    ('36987412', 102, 'Lima',   'Obesidad',      95.00, 1.68, '138/88', 38, '2025-01-20');
select insert_into_atencionmedica_with_partition_creation
    ('65412398', 103, 'Lima',   'Hipertensión',  72.00, 1.62, '155/98', 55, '2025-01-21');
select insert_into_atencionmedica_with_partition_creation
    ('89632147', 101, 'Callao', 'Cardiopatía',   82.00, 1.70, '142/90', 48, '2025-01-22');
