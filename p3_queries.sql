select diagnostico, count(*)
from local_schema.atencionmedica
group by diagnostico;

select *
from local_schema.atencionmedica
order by fechaatencion desc;

explain analyze
select diagnostico, count(*)
from local_schema.atencionmedica
group by diagnostico;

explain analyze
select *
from local_schema.atencionmedica
order by fechaatencion desc;
