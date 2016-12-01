ALTER TABLE fias."AddressObjects" ADD CONSTRAINT AddressObjects_pkey PRIMARY KEY("id");
--CREATE UNIQUE INDEX ON fias."AddressObjects" USING btree ("AOID");
CREATE UNIQUE INDEX ON fias."AddressObjects" USING btree ("AOGUID");
--CREATE UNIQUE INDEX ON fias."AddressObjects" USING btree ("AOGUID", "ACTSTATUS", "CURRSTATUS");--, "LIVESTATUS"
CREATE INDEX ON fias."AddressObjects" USING btree ("PARENTGUID");


-- foreign key (parentguid to aoguid)
--ОШИБКА:  в целевой внешней таблице "AddressObjects" нет ограничения уникальности, соответствующего данным ключам
--ALTER TABLE fias."AddressObjects" 
--  ADD CONSTRAINT AddressObjects_parentguid_fkey FOREIGN KEY ("PARENTGUID")
--  REFERENCES fias."AddressObjects" ("AOGUID")
--  MATCH SIMPLE
--  ON UPDATE CASCADE ON DELETE NO ACTION;


CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX on fias."AddressObjects" USING gin (lower("FORMALNAME") gin_trgm_ops);


---CREATE INDEX currstatus_idx ON addrobj USING btree (currstatus);
--CREATE INDEX aolevel_idx ON addrobj USING btree (aolevel);
--CREATE INDEX formalname_idx ON addrobj USING btree (formalname);
--CREATE INDEX offname_idx ON addrobj USING btree (offname);
--CREATE INDEX shortname_idx ON addrobj USING btree (shortname);
--CREATE INDEX shortname_aolevel_idx ON addrobj USING btree (shortname, aolevel);



CREATE OR REPLACE FUNCTION fias.aoid_parents(uuid)
RETURNS  SETOF fias."AddressObjects"
AS $$
-- вывести полный адрес
WITH RECURSIVE child_to_parents AS (
  SELECT a.*
  FROM fias."AddressObjects" a
  WHERE a."AOID" = $1--'51f21baa-c804-4737-9d5f-9da7a3bb1598'
UNION ALL
  SELECT a.*
  FROM fias."AddressObjects" a, child_to_parents c
  WHERE a."AOGUID" = c."PARENTGUID"
        --AND a."CURRSTATUS" = 0
        AND a."ACTSTATUS" = 1
)
SELECT * FROM child_to_parents ORDER BY "AOLEVEL";
$$ LANGUAGE SQL;


CREATE OR REPLACE FUNCTION fias.search_formalname_parents(text)
RETURNS  SETOF fias."AddressObjects"
AS $$
-- вывести полный адрес
WITH RECURSIVE child_to_parents AS (
  SELECT a.*
  FROM fias."AddressObjects" a
  WHERE lower(a."FORMALNAME") ~ $1--'51f21baa-c804-4737-9d5f-9da7a3bb1598'
UNION ALL
  SELECT a.*
  FROM fias."AddressObjects" a, child_to_parents c
  WHERE a."AOGUID" = c."PARENTGUID"
        --AND a."CURRSTATUS" = 0
        AND a."ACTSTATUS" = 1
)
SELECT * FROM child_to_parents ORDER BY "AOLEVEL";
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION public.unnest_dim2(anyarray)
RETURNS SETOF anyarray AS
$function$
DECLARE
    s $1%TYPE;
BEGIN
    FOREACH s SLICE 1  IN ARRAY $1 LOOP
        RETURN NEXT s;
    END LOOP;
    RETURN;
END;
$function$
LANGUAGE plpgsql IMMUTABLE;



