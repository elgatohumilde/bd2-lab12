set search_path to local_schema;

drop table if exists pacientes;

create table pacientes (
    dni char(8),
    nombre varchar(50) not null,
    apellidos varchar(100) not null,
    fechanacimiento date not null,
    sexo char(1) not null check (sexo in ('M', 'F')),
    ciudadorigen varchar(50) not null
) partition by range (ciudadorigen);

create table pacientes_1 partition of pacientes for values from (minvalue) to ('h');
create table pacientes_2 partition of pacientes for values from ('h') to ('p');
create table pacientes_3 partition of pacientes for values from ('p') to (maxvalue);

truncate table atencionmedica;
\copy atencionmedica from 'atencionmedica.csv' delimiter ',' csv header;

\copy pacientes from 'pacientes.csv' delimiter ',' csv header;

-- select * from pacientes order by fechanacimiento

-- TODO: select aproppriate partition values
create table pacientes_1p as select * from pacientes where fechanacimiento < '2020-01-01';
create table pacientes_2p as select * from pacientes where fechanacimiento >= '2020-01-01' and fechanacimiento < '2021-01-01';
create table pacientes_3p as select * from pacientes where fechanacimiento > '2021-01-01';

create table pacientes_1o as select * from pacientes_1p order by fechanacimiento;
create table pacientes_2o as select * from pacientes_2p order by fechanacimiento;
create table pacientes_3o as select * from pacientes_3p order by fechanacimiento;

-- select * from pacientes_1o
-- union all
-- select * from pacientes_2o
-- union all
-- select * from pacientes_3o;

drop table pacientes_1o;
drop table pacientes_2o;
drop table pacientes_3o;

drop table pacientes_1p;
drop table pacientes_2p;
drop table pacientes_3p;

-- select distinct ciudadorigen from pacientes
create table pacientes_1p as select distinct ciudadorigen from pacientes_1;
create table pacientes_2p as select distinct ciudadorigen from pacientes_2;
create table pacientes_3p as select distinct ciudadorigen from pacientes_3;

-- select * from pacientes_1p
-- union all
-- select * from pacientes_2p
-- union all
-- select * from pacientes_3p;

drop table pacientes_1p;
drop table pacientes_2p;
drop table pacientes_3p;

-- select diagnostico, avg(edad) as promedad from atencionmedica group by diagnostico

-- select * from pacientes natural join atencionmedica
-- TODO: choose proper values of k
create table pacientes_1p as select * from pacientes where dni < '3';
create table pacientes_2p as select * from pacientes where dni >= '3' and dni < '6';
create table pacientes_3p as select * from pacientes where dni >= '6';

create table atencionmedica_1p as select * from atencionmedica where dni < '3';
create table atencionmedica_2p as select * from atencionmedica where dni >= '3' and dni < '6';
create table atencionmedica_3p as select * from atencionmedica where dni >= '6';

create table pacientes_1j as select * from pacientes_1p natural join atencionmedica_1p;
create table pacientes_2j as select * from pacientes_2p natural join atencionmedica_2p;
create table pacientes_3j as select * from pacientes_3p natural join atencionmedica_3p;

select * from pacientes_1j
union all
select * from pacientes_2j
union all
select * from pacientes_3j;


drop table pacientes_1p;
drop table pacientes_2p;
drop table pacientes_3p;

