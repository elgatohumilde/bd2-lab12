create role remote_user login superuser password '123' ;

create database remote_db ;
\c remote_db

create schema remote_schema ;
grant all privileges on database remote_db to remote_user ;

create extension if not exists postgres_fdw;

create table atencionmedica_example (
    dni char(8),
    codmedico integer not null,
    ciudad varchar(50) not null,
    diagnostico varchar(50) not null,
    peso decimal(5, 2) not null,
    talla decimal(4, 2) not null,
    presionarterial varchar(10) not null,
    edad integer not null check (edad >= 0),
    fechaatencion date not null
);
