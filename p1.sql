drop schema if exists local_schema ;
create schema local_schema ;

set search_path to local_schema;

create table atencionmedica (
    DNI char(8),
    CodMedico integer not null,
    Ciudad varchar(50) not null,
    Diagnostico varchar(50) not null,
    Peso decimal(5, 2) not null,
    Talla decimal(4, 2) not null,
    PresionArterial varchar(10) not null,
    Edad integer not null check (Edad >= 0),
    FechaAtencion date not null
) partition by list (Diagnostico) ;

create table "AtencionMedica_Diabetes" partition of atencionmedica for values in ('Diabetes') ;
create table "AtencionMedica_Obesidad" partition of atencionmedica for values in ('Obesidad') ;
create table "AtencionMedica_Cardiopatía" partition of atencionmedica for values in ('Cardiopatía') ;
create table "AtencionMedica_Hipertensión" partition of atencionmedica for values in ('Hipertensión') ;
