set search_path to local_schema;

create or replace function create_atencionmedica_partition_if_not_exists (Diagnostico varchar (50))
returns void as $$
declare
    partition_name text;
begin
    partition_name := 'AtencionMedica_' || Diagnostico;

    if not exists (
        select 1 from pg_class where relname = partition_name
    ) then
        execute format('create table %I partition of AtencionMedica for values in (%L)', partition_name, Diagnostico);
        raise notice 'Partición % creada para el diagnóstico %', partition_name, Diagnostico;
    end if;
end;
$$ language plpgsql ;

create or replace function insert_into_atencionmedica_with_partition_creation (
DNI char (8),
CodMedico integer,
Ciudad varchar (50),
Diagnostico varchar (50),
Peso decimal (5, 2),
Talla decimal (4, 2),
PresionArterial varchar (10),
Edad integer,
FechaAtencion date
) returns void as $$
begin
  perform create_atencionmedica_partition_if_not_exists(Diagnostico);

  insert into AtencionMedica (
      DNI,
      CodMedico,
      Ciudad,
      Diagnostico,
      Peso,
      Talla,
      PresionArterial,
      Edad,
      FechaAtencion
  ) values (
      DNI,
      CodMedico,
      Ciudad,
      Diagnostico,
      Peso,
      Talla,
      PresionArterial,
      Edad,
      FechaAtencion
  );
end;
$$ language plpgsql ;

select insert_into_atencionmedica_with_partition_creation
    ('45781236', 101, 'Lima',   'Diabetes',      70.00, 1.65, '130/85', 45, '2025-01-15');
select insert_into_atencionmedica_with_partition_creation
    ('08569321', 102, 'Lima',   'Hipertensión',  85.00, 1.72, '150/95', 60, '2025-01-16');
select insert_into_atencionmedica_with_partition_creation
    ('72103654', 101, 'Callao', 'Obesidad',      90.00, 1.60, '140/90', 35, '2025-01-17');
select insert_into_atencionmedica_with_partition_creation
    ('25963147', 103, 'Callao', 'Cardiopatía',   78.00, 1.75, '145/92', 50, '2025-01-18');
select insert_into_atencionmedica_with_partition_creation
    ('15478962', 101, 'Lima',   'Diabetes',      65.00, 1.58, '125/82', 42, '2025-01-19');
select insert_into_atencionmedica_with_partition_creation
    ('36987412', 102, 'Lima',   'Obesidad',      95.00, 1.68, '138/88', 38, '2025-01-20');
select insert_into_atencionmedica_with_partition_creation
    ('65412398', 103, 'Lima',   'Hipertensión',  72.00, 1.62, '155/98', 55, '2025-01-21');
select insert_into_atencionmedica_with_partition_creation
    ('89632147', 101, 'Callao', 'Cardiopatía',   82.00, 1.70, '142/90', 48, '2025-01-22');
