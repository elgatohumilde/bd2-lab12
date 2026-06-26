drop table if exists AtencionMedica;

create table AtencionMedica (
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

create table "AtencionMedica_Diabetes" partition of AtencionMedica for values in ('Diabetes') ;
create table "AtencionMedica_Obesidad" partition of AtencionMedica for values in ('Obesidad') ;
create table "AtencionMedica_Cardiopatía" partition of AtencionMedica for values in ('Cardiopatía') ;
create table "AtencionMedica_Hipertensión" partition of AtencionMedica for values in ('Hipertensión') ;
