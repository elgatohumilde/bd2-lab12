create role remote_user login superuser password '123' ;

create database remote_db ;
\c remote_db

create schema remote_schema ;
grant all privileges on database remote_db to remote_user ;

create table remote_schema."persona" (
  id int not null,
  fecha_nac date not null,
  cod_pais char(2) not null,
  nombre varchar(30)
);

create extension if not exists postgres_fdw;
