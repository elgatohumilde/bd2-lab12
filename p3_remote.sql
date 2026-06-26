create role remote_user login superuser password '123' ;

create database remote_db ;
\c remote_db

create schema remote_schema ;
grant all privileges on database remote_db to remote_user ;

create extension if not exists postgres_fdw;

create table remote_schema.atencionmedica_resto (
    DNI char(8),
    CodMedico integer not null,
    Ciudad varchar(50) not null,
    Diagnostico varchar(50) not null,
    Peso decimal(5, 2) not null,
    Talla decimal(4, 2) not null,
    PresionArterial varchar(10) not null,
    Edad integer not null check (Edad >= 0),
    FechaAtencion date not null
);
