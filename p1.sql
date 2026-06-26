drop schema if exists local_schema cascade;
create schema local_schema ;

set search_path to local_schema;

create table atencionmedica (
    dni char(8),
    codmedico integer not null,
    ciudad varchar(50) not null,
    diagnostico varchar(50) not null,
    peso decimal(5, 2) not null,
    talla decimal(4, 2) not null,
    presionarterial varchar(10) not null,
    edad integer not null check (Edad >= 0),
    fechaatencion date not null
);

create table "AtencionMedica_Diabetes" partition of atencionmedica for values in ('Diabetes') ;
create table "AtencionMedica_Obesidad" partition of atencionmedica for values in ('Obesidad') ;
create table "AtencionMedica_Cardiopatía" partition of atencionmedica for values in ('Cardiopatía') ;
create table "AtencionMedica_Hipertensión" partition of atencionmedica for values in ('Hipertensión') ;
