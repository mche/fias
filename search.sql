CREATE or REPLACE FUNCTION fias.match_array(text, text[])
RETURNS int2 AS $$
--select fias.match_array('фокиэ пермэ'::text, '{фоки1,пер,3}'::text[]);
DECLARE
  --s boolean[] := array[]::boolean[];
  s int2 := 0;
  x text;
BEGIN
  --FOR i IN 1..array_upper($2, 1) LOOP
  FOREACH x IN ARRAY $2 LOOP
    IF $1 ~ x THEN
      --RAISE NOTICE '% ~ %', $1, x;
      --RETURN true;
      s := s + 1;
    END IF;
    --s[i] := $1 ~ $2[i];
    --PERFORM array_append(s, );
  END LOOP;
  RETURN s;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fias.search_formalname(text[])
RETURNS  TABLE("AOGUID" uuid[], "PARENTGUID" uuid[], "AOLEVEL" int2[], "FORMALNAME" text[], "PARENT_MATCH" int2[])
--TABLE("AOGUID" uuid, "PARENTGUID" uuid, "AOLEVEL" int2)
AS $func$
--explain
select
--distinct
  Array["l3AOGUID", "l4AOGUID", "l5AOGUID", "l6AOGUID", "l7AOGUID"],
  array["l3PARENTGUID", "l4PARENTGUID", "l5PARENTGUID", "l6PARENTGUID", "l7PARENTGUID"],
  array["l3AOLEVEL", "l4AOLEVEL", "l5AOLEVEL", "l6AOLEVEL", "l7AOLEVEL"],
  Array["l3FORMALNAME", "l4FORMALNAME", "l5FORMALNAME", "l6FORMALNAME", "l7FORMALNAME"],
  array["l3PARENT_MATCH", "l4PARENT_MATCH", "l5PARENT_MATCH", "l6PARENT_MATCH"]
  
from (
SELECT 
  --l4.l7AOID AS aoid,
  l3.id as l3id,
  l3."FORMALNAME" AS "l3FORMALNAME",
  -- l3.OFFNAME as l3OFFNAME,
  l3."SHORTNAME" AS "l3SHORTNAME",
  l3."AOLEVEL" AS "l3AOLEVEL",
  --l3.CENTSTATUS AS l3CENTSTATUS,
  l3."AOID" AS "l3AOID",
  l3."AOGUID" AS "l3AOGUID",
  l3."PARENTGUID" AS "l3PARENTGUID",
  fias.match_array(l3."FORMALNAME", $1) as "l3PARENT_MATCH",
  
  l4.*
FROM (SELECT
  l4.id AS l4id,
  l4."FORMALNAME" AS "l4FORMALNAME",
  -- l4.OFFNAME as l4OFFNAME,
  l4."SHORTNAME" AS "l4SHORTNAME",
  l4."AOGUID" AS "l4AOGUID",
  l4."PARENTGUID" AS "l4PARENTGUID",
  l4."AOLEVEL" AS "l4AOLEVEL",
  --l4.CENTSTATUS AS l4CENTSTATUS,
  l4."AOID" AS "l4AOID",
  fias.match_array(l4."FORMALNAME", $1) as "l4PARENT_MATCH",
  -- 
  
  l5.*
FROM (SELECT
  l5.id AS l5id,
  l5."FORMALNAME" AS "l5FORMALNAME",
  -- l5.OFFNAME as l5OFFNAME,
  l5."SHORTNAME" AS "l5SHORTNAME",
  l5."AOGUID" AS "l5AOGUID",
  l5."PARENTGUID" AS "l5PARENTGUID",
  l5."AOLEVEL" AS "l5AOLEVEL",
  --l5.CENTSTATUS AS l5CENTSTATUS,
  l5."AOID" AS "l5AOID",
  fias.match_array(l5."FORMALNAME", $1) as "l5PARENT_MATCH",
  
  l6.*
FROM (SELECT
  l6.id AS l6id,
  l6."FORMALNAME" AS "l6FORMALNAME",
  -- l6.OFFNAME as l6OFFNAME,
  l6."SHORTNAME" AS "l6SHORTNAME",
  l6."AOGUID" AS "l6AOGUID",
  l6."PARENTGUID" AS "l6PARENTGUID",
  l6."AOLEVEL" AS "l6AOLEVEL",
  --l6."CENTSTATUS" AS l6CENTSTATUS,
  l6."AOID" AS "l6AOID",
  fias.match_array(l6."FORMALNAME", $1) as "l6PARENT_MATCH",
  
  l7.*
FROM (SELECT
  id AS l7id,
  "FORMALNAME" AS "l7FORMALNAME",
  "SHORTNAME" AS "l7SHORTNAME",
  "AOGUID" AS "l7AOGUID",
  "PARENTGUID" AS "l7PARENTGUID",
  "AOLEVEL" AS "l7AOLEVEL",
  --"CENTSTATUS" AS "l7CENTSTATUS",
  "AOID" AS "l7AOID"
        FROM
          fias."AddressObjects"
        WHERE 
        lower("FORMALNAME") ~ $1[1] or (array_length($1, 1) > 1 and lower("FORMALNAME") ~ $1[array_length($1, 1)])
        and "ACTSTATUS" = 1
) l7
LEFT JOIN fias."AddressObjects" l6 	ON
          l6."ACTSTATUS" = 1 AND l7."l7PARENTGUID" = l6."AOGUID" --AND l6.id<>l7.l7id -- AND (a.AOGUID<>@ParentGUID)
) l6
LEFT JOIN fias."AddressObjects" l5 	ON
          l5."ACTSTATUS" = 1 AND l6."l6PARENTGUID" = l5."AOGUID" --AND l5.id<>l6.l6id 
) l5
LEFT JOIN fias."AddressObjects" l4 	ON
          l4."ACTSTATUS" = 1 AND l5."l5PARENTGUID" = l4."AOGUID" --AND l4.id<>l5.l5id
) l4
LEFT JOIN fias."AddressObjects" l3 	ON
          l3."ACTSTATUS" = 1 AND l4."l4PARENTGUID" = l3."AOGUID" --AND l3.id<>l4.l4id --  AND l3.REGIONCODE = regcode 
) a;
$func$ LANGUAGE SQL;
