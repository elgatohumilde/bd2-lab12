create extension if not exists postgres_fdw;
create extension if not exists dblink;

drop schema if exists local_schema cascade;
create schema local_schema;

create table local_schema.atencionmedica (
    dni char(8),
    codmedico integer not null,
    ciudad varchar(50) not null,
    diagnostico varchar(50) not null,
    peso decimal(5, 2) not null,
    talla decimal(4, 2) not null,
    presionarterial varchar(10) not null,
    edad integer not null check (edad >= 0),
    fechaatencion date not null
) partition by list (diagnostico);

create table local_schema.pacientes (
    dni char(8),
    nombre varchar(50) not null,
    apellidos varchar(100) not null,
    fechanacimiento date not null,
    sexo char(1) not null check (sexo in ('M', 'F')),
    ciudadorigen varchar(50) not null
) partition by range (ciudadorigen);

create server if not exists worker_0 foreign data wrapper postgres_fdw
options (host 'worker_1', dbname 'remote_db', port '5432');

create server if not exists worker_1 foreign data wrapper postgres_fdw
options (host 'worker_2', dbname 'remote_db', port '5432');

create server if not exists worker_2 foreign data wrapper postgres_fdw
options (host 'worker_3', dbname 'remote_db', port '5432');

create user mapping if not exists for current_user server worker_0
options (user 'remote_user', password '123');

create user mapping if not exists for current_user server worker_1
options (user 'remote_user', password '123');

create user mapping if not exists for current_user server worker_2
options (user 'remote_user', password '123');

import foreign schema remote_schema from server worker_0 into local_schema;
import foreign schema remote_schema from server worker_1 into local_schema;
import foreign schema remote_schema from server worker_2 into local_schema;

select dblink_connect('worker_0', 'host=worker_1 port=5432 dbname=remote_db user=postgres password=123');
select dblink_connect('worker_1', 'host=worker_2 port=5432 dbname=remote_db user=postgres password=123');
select dblink_connect('worker_2', 'host=worker_3 port=5432 dbname=remote_db user=postgres password=123');

create or replace function create_atencionmedica_partition_if_not_exists (Diagnostico varchar (50))
returns void as $$
declare
    partition_name text;
    worker_num int;
    worker_name text;
begin
    partition_name := 'AtencionMedica_' || Diagnostico;

    -- por alguna razón, postgres no tiene unsigned integers y por ende
    -- hashtext retorna un entero con signo
    worker_num := (hashtext(Diagnostico) & 2147483647) % 3;

    raise notice 'Usando worker %', worker_num;
    worker_name := 'worker_' || worker_num;

    if not exists (
        select 1
        from pg_class c
        join pg_namespace  n on c.relnamespace = n.oid
        where relname = partition_name and n.nspname = 'local_schema'
    ) then
        perform dblink_exec(worker_name, format('create table remote_schema.%I (like atencionmedica_example)', partition_name));
        execute format('create foreign table local_schema.%I partition of local_schema.atencionmedica for values in (%L) server %I options (schema_name ''remote_schema'', table_name %L)', partition_name, Diagnostico, worker_name, partition_name);
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

select dblink_exec('worker_0', $$
  create table if not exists remote_schema.pacientes_1 (like pacientes_example)
$$);
create foreign table if not exists local_schema.pacientes_1
partition of local_schema.pacientes for values from (minvalue) to ('h')
server worker_0 options (schema_name 'remote_schema', table_name 'pacientes_1');

select dblink_exec('worker_1', $$
  create table if not exists remote_schema.pacientes_2 (like pacientes_example)
$$);
create foreign table if not exists local_schema.pacientes_2
partition of local_schema.pacientes for values from ('h') to ('p')
server worker_1 options (schema_name 'remote_schema', table_name 'pacientes_2');

select dblink_exec('worker_2', $$
  create table if not exists remote_schema.pacientes_3 (like pacientes_example)
$$);
create foreign table if not exists local_schema.pacientes_3
partition of local_schema.pacientes for values from ('p') to (maxvalue)
server worker_2 options (schema_name 'remote_schema', table_name 'pacientes_3');

create temp table atencionmedica_import (like local_schema.atencionmedica);
\copy atencionmedica_import from 'atencionmedica.csv' delimiter ',' csv header;

select insert_into_atencionmedica_with_partition_creation
    (dni, codmedico, ciudad, diagnostico, peso, talla, presionarterial, edad, fechaatencion)
from atencionmedica_import;

\copy local_schema.pacientes from 'pacientes.csv' delimiter ',' csv header;

set search_path to local_schema;

-- select * from pacientes order by fechanacimiento
create or replace function query_1()
returns setof pacientes as $$
begin
    -- Particionamiento temporal por rango sobre fechanacimiento
    create temporary table pacientes_1p on commit drop as select * from pacientes where fechanacimiento < '1958-12-24';
    create temporary table pacientes_2p on commit drop as select * from pacientes where fechanacimiento >= '1958-12-24' and fechanacimiento < '1992-03-25';
    create temporary table pacientes_3p on commit drop as select * from pacientes where fechanacimiento >= '1992-03-25';

    -- Ordenamientos locales por fechanacimiento
    create temporary table pacientes_1o on commit drop as select * from pacientes_1p order by fechanacimiento;
    create temporary table pacientes_2o on commit drop as select * from pacientes_2p order by fechanacimiento;
    create temporary table pacientes_3o on commit drop as select * from pacientes_3p order by fechanacimiento;

    -- Ya que las 3 particiones tienen data ordenada y cubren rangos disjuntos,
    -- los podemos concatenar
    return query
        select * from pacientes_1o
        union all
        select * from pacientes_2o
        union all
        select * from pacientes_3o;
end;
$$ language plpgsql;

-- select distinct ciudadorigen from pacientes
create or replace function query_2()
returns setof varchar(50) as $$
begin
    -- La tabla ya está particionada por ciudadorigen!

    -- Distincts locales en cada partición
    create temporary table pacientes_1p on commit drop as select distinct ciudadorigen from pacientes_1;
    create temporary table pacientes_2p on commit drop as select distinct ciudadorigen from pacientes_2;
    create temporary table pacientes_3p on commit drop as select distinct ciudadorigen from pacientes_3;

    -- Como cada partición tiene data disjunta distinta,
    -- la concatenación también tendrá data distinta.
    return query
        select * from pacientes_1p
        union all
        select * from pacientes_2p
        union all
        select * from pacientes_3p;
end;
$$ language plpgsql;

drop type if exists diagnostico_proms cascade;
create type diagnostico_proms as (
    diagnostico varchar(50),
    promedad decimal
);

-- select diagnostico, avg(edad) as promedad from atencionmedica group by diagnostico
create or replace function query_3()
returns setof diagnostico_proms as $$
begin
    -- Partición por rango según diagnostico
    create temporary table atencionmedica_1p on commit drop as select * from atencionmedica where diagnostico < 'Covid';
    create temporary table atencionmedica_2p on commit drop as select * from atencionmedica where diagnostico >= 'Covid' and diagnostico < 'Gripe';
    create temporary table atencionmedica_3p on commit drop as select * from atencionmedica where diagnostico >= 'Gripe';

    -- Agrupamientos locales por rango de diagnóstico
    create temporary table atencionmedica_1g on commit drop as select diagnostico, avg(edad) as promedad from atencionmedica_1p group by diagnostico;
    create temporary table atencionmedica_2g on commit drop as select diagnostico, avg(edad) as promedad from atencionmedica_2p group by diagnostico;
    create temporary table atencionmedica_3g on commit drop as select diagnostico, avg(edad) as promedad from atencionmedica_3p group by diagnostico;

    -- Como no hay diagnóstico presente en más de una partición a la vez,
    -- basta con concatenar los agrupamientos locales.
    return query
        select * from atencionmedica_1g
        union all
        select * from atencionmedica_2g
        union all
        select * from atencionmedica_3g;
end;
$$ language plpgsql;

drop type if exists paciente_atencion cascade;
create type paciente_atencion as (
    dni char(8),
    nombre varchar(50),
    apellidos varchar(100),
    fechanacimiento date,
    sexo char(1),
    ciudadorigen varchar(50),
    codmedico integer,
    ciudad varchar(50),
    diagnostico varchar(50),
    peso decimal(5, 2),
    talla decimal(4, 2),
    presionarterial varchar(10),
    edad integer,
    fechaatencion date
);

-- select * from pacientes natural join atencionmedica
create or replace function query_4()
returns setof paciente_atencion as $$
begin
    -- Particionamiento local de pacientes por dni
    create temporary table pacientes_1p on commit drop as (select * from pacientes where dni < '32863544');
    create temporary table pacientes_2p on commit drop as select * from pacientes where dni >= '32863544' and dni < '65823251';
    create temporary table pacientes_3p on commit drop as select * from pacientes where dni >= '65823251';

    -- Particionamiento local de atencionmedica por dni
    create temporary table atencionmedica_1p on commit drop as select * from atencionmedica where dni < '32863544';
    create temporary table atencionmedica_2p on commit drop as select * from atencionmedica where dni >= '32863544' and dni < '65823251';
    create temporary table atencionmedica_3p on commit drop as select * from atencionmedica where dni >= '65823251';

    -- Natural joins locales emparejando rangos de pacientes y atencionmedica
    create temporary table pacientes_1j on commit drop as select * from pacientes_1p natural join atencionmedica_1p;
    create temporary table pacientes_2j on commit drop as select * from pacientes_2p natural join atencionmedica_2p;
    create temporary table pacientes_3j on commit drop as select * from pacientes_3p natural join atencionmedica_3p;

    -- No nos hacen falta más joins, podemos concatenar todo.
    return query
        select * from pacientes_1j
        union all
        select * from pacientes_2j
        union all
        select * from pacientes_3j;
end;
$$ language plpgsql;

select * from query_1();
select * from query_2();
select * from query_3();
select * from query_4();
