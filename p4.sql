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
create or replace function query_1()
returns setof pacientes as $$
declare
    retval pacientes%rowtype;
begin
    -- TODO: choose appropriate partition values
    create temporary table pacientes_1p as select * from pacientes where fechanacimiento < '2020-01-01';
    create temporary table pacientes_2p as select * from pacientes where fechanacimiento >= '2020-01-01' and fechanacimiento < '2021-01-01';
    create temporary table pacientes_3p as select * from pacientes where fechanacimiento > '2021-01-01';

    create temporary table pacientes_1o as select * from pacientes_1p order by fechanacimiento;
    create temporary table pacientes_2o as select * from pacientes_2p order by fechanacimiento;
    create temporary table pacientes_3o as select * from pacientes_3p order by fechanacimiento;

    for retval in
        select * from pacientes_1o
        union all
        select * from pacientes_2o
        union all
        select * from pacientes_3o
    loop
        return next retval;
    end loop;

    drop table pacientes_1o, pacientes_2o, pacientes_3o;
    drop table pacientes_1p, pacientes_2p, pacientes_3p;
    return;
end;
$$ language plpgsql;

-- select distinct ciudadorigen from pacientes
create or replace function query_2()
returns setof varchar(50) as $$
declare
    retval varchar(50);
begin
    create temporary table pacientes_1p as select distinct ciudadorigen from pacientes_1;
    create temporary table pacientes_2p as select distinct ciudadorigen from pacientes_2;
    create temporary table pacientes_3p as select distinct ciudadorigen from pacientes_3;

    for retval in
        select * from pacientes_1p
        union all
        select * from pacientes_2p
        union all
        select * from pacientes_3p
    loop
        return next retval;
    end loop;

    drop table pacientes_1p, pacientes_2p, pacientes_3p;
    return;
end;
$$ language plpgsql;

drop type if exists diagnostico_proms;
create type diagnostico_proms as (
    diagnostico varchar(50),
    promedad integer
);

-- select diagnostico, avg(edad) as promedad from atencionmedica group by diagnostico
create or replace function query_3()
returns setof diagnostico_proms as $$
declare
    retval diagnostico_proms;
begin
    -- TODO: choose appropriate partition values

    -- Partición por rango según diagnostico
    create temporary table atencionmedica_1p as select * from atencionmedica where diagnostico < 'H';
    create temporary table atencionmedica_2p as select * from atencionmedica where diagnostico >= 'H' and diagnostico < 'P';
    create temporary table atencionmedica_3p as select * from atencionmedica where diagnostico >= 'P';

    -- Agrupamientos locales por rango de diagnóstico
    create temporary table atencionmedica_1g as select diagnostico, avg(edad) as promedad from atencionmedica_1p group by diagnostico;
    create temporary table atencionmedica_2g as select diagnostico, avg(edad) as promedad from atencionmedica_2p group by diagnostico;
    create temporary table atencionmedica_3g as select diagnostico, avg(edad) as promedad from atencionmedica_3p group by diagnostico;

    -- Como no hay diagnóstico presente en más de una partición a la vez,
    -- basta con concatenar los agrupamientos locales.
    for retval in
        select * from atencionmedica_1g
        union all
        select * from atencionmedica_2g
        union all
        select * from atencionmedica_3g
    loop
        return next retval;
    end loop;


    drop table atencionmedica_1g, atencionmedica_2g, atencionmedica_3g;
    drop table atencionmedica_1p, atencionmedica_2p, atencionmedica_3p;
    return;
end;
$$ language plpgsql;

drop type if exists paciente_atencion;
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
declare
    retval paciente_atencion;
begin
    -- TODO: choose appropriate partition values
    create temporary table pacientes_1p as select * from pacientes where dni < '3';
    create temporary table pacientes_2p as select * from pacientes where dni >= '3' and dni < '6';
    create temporary table pacientes_3p as select * from pacientes where dni >= '6';

    create temporary table atencionmedica_1p as select * from atencionmedica where dni < '3';
    create temporary table atencionmedica_2p as select * from atencionmedica where dni >= '3' and dni < '6';
    create temporary table atencionmedica_3p as select * from atencionmedica where dni >= '6';

    create temporary table pacientes_1j as select * from pacientes_1p natural join atencionmedica_1p;
    create temporary table pacientes_2j as select * from pacientes_2p natural join atencionmedica_2p;
    create temporary table pacientes_3j as select * from pacientes_3p natural join atencionmedica_3p;

    for retval in
        select * from pacientes_1j
        union all
        select * from pacientes_2j
        union all
        select * from pacientes_3j
    loop
        return next retval;
    end loop;

    drop table pacientes_1j, pacientes_2j, pacientes_3j;
    drop table pacientes_1p, pacientes_2p, pacientes_3p;
    return;
end;
$$ language plpgsql;

select * from query_1();
select * from query_2();
select * from query_3();
select * from query_4();
