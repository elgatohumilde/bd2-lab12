set search_path to local_schema;

drop table if exists pacientes cascade;

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

create temporary table atencionmedica_import (like atencionmedica);
\copy atencionmedica_import from 'atencionmedica.csv' delimiter ',' csv header;

select insert_into_atencionmedica_with_partition_creation
    (dni, codmedico, ciudad, diagnostico, peso, talla, presionarterial, edad, fechaatencion)
from atencionmedica_import;

\copy pacientes from 'pacientes.csv' delimiter ',' csv header;

-- select * from pacientes order by fechanacimiento
create or replace function query_1()
returns setof pacientes as $$
begin
    -- Particionamiento temporal por rango sobre fechanacimiento
    -- '1958-12-24' y '1992-03-25' son los percentiles 33 y 66 del CSV de pacientes
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
    -- 'Covid' y 'Gripe' son los percentiles 33 y 66 de los datos del CSV
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
    -- '32863544' y '65823251' son los percentiles 33 y 66 del CSV de pacientes
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
