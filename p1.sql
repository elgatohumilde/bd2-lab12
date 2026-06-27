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
    edad integer not null check (edad >= 0),
    fechaatencion date not null
) partition by list (diagnostico);

create table "AtencionMedica_Diabetes" partition of atencionmedica for values in ('Diabetes');
create table "AtencionMedica_Obesidad" partition of atencionmedica for values in ('Obesidad');
create table "AtencionMedica_Cardiopatía" partition of atencionmedica for values in ('Cardiopatía');
create table "AtencionMedica_Hipertensión" partition of atencionmedica for values in ('Hipertensión');

insert into atencionmedica
    (dni, codmedico, ciudad, diagnostico, peso, talla, presionarterial, edad, fechaatencion)
values
    ('12345678', 101, 'Lima', 'Diabetes', 72.50, 1.68, '120/80', 45, '2026-01-10'),
    ('23456789', 102, 'Arequipa', 'Diabetes', 81.20, 1.75, '130/85', 53, '2026-01-12'),
    ('34567890', 103, 'Cusco', 'Obesidad', 98.40, 1.70, '135/90', 39, '2026-01-15'),
    ('45678901', 104, 'Trujillo', 'Obesidad', 110.75, 1.82, '140/95', 48, '2026-01-18'),
    ('56789012', 105, 'Piura', 'Cardiopatía', 76.80, 1.73, '125/80', 61, '2026-01-20'),
    ('67890123', 106, 'Chiclayo', 'Cardiopatía', 69.30, 1.65, '118/78', 57, '2026-01-22'),
    ('78901234', 107, 'Iquitos', 'Hipertensión', 83.60, 1.69, '150/95', 64, '2026-01-25'),
    ('89012345', 108, 'Tacna', 'Hipertensión', 79.90, 1.72, '145/92', 59, '2026-01-27');
