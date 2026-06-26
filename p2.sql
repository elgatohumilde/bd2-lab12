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

select insert_into_atencionmedica_with_partition_creation (
'61105385',
1,
'Lima',
'Yoyu',
70.50,
70.00,
'something',
19,
'01-01-2000'
) ;
