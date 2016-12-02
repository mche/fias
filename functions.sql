CREATE or REPLACE FUNCTION fias.match_weight(text[], text[])
RETURNS int2 AS $$
-- посчитать общую сумму совпадений (вес) в матрице [тексты X образцы]
DECLARE
  --s boolean[] := array[]::boolean[];
  len int := array_length($1, 1);
  --s int2[] := ('{' || repeat('0,', len-1) || '0}')::int2[];
  s int2 := 0;
  x text;
BEGIN
  FOR i IN 1..len LOOP
    FOREACH x IN ARRAY $2 LOOP
      IF lower($1[i]) ~ lower(x) THEN
        --RAISE NOTICE '% ~ %', $1, x;
        --RETURN true;
        --s[i] := s[i] + 1;
        s := s + 1;
      END IF;
      --s[i] := $1 ~ $2[i];
      --PERFORM array_append(s, );
    END LOOP;
  END LOOP;
  RETURN s;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fias.search_formalname(text)
RETURNS  TABLE("AOGUID" uuid[], "PARENTGUID" uuid[], "AOLEVEL" int2[], "FORMALNAME" text[], "SHORTNAME" varchar(10)[],  id int[])--, "CENTSTATUS" int2[],
AS $func$
--explain
select
--distinct
  Array["l3AOGUID", "l4AOGUID", "l5AOGUID", "l6AOGUID", "l7AOGUID"],
  array["l3PARENTGUID", "l4PARENTGUID", "l5PARENTGUID", "l6PARENTGUID", "l7PARENTGUID"],
  array["l3AOLEVEL", "l4AOLEVEL", "l5AOLEVEL", "l6AOLEVEL", "l7AOLEVEL"],
  Array["l3FORMALNAME", "l4FORMALNAME", "l5FORMALNAME", "l6FORMALNAME", "l7FORMALNAME"],
  Array["l3SHORTNAME", "l4SHORTNAME", "l5SHORTNAME", "l6SHORTNAME", "l7SHORTNAME"],
  --Array["l3CENTSTATUS", "l4CENTSTATUS", "l5CENTSTATUS", "l6CENTSTATUS", "l7CENTSTATUS"],
  array[l3id, l4id, l5id, l6id, l7id]
  
from (
SELECT 
  l3.id as l3id,
  l3."FORMALNAME" AS "l3FORMALNAME",
  l3."SHORTNAME" AS "l3SHORTNAME",
  l3."AOLEVEL" AS "l3AOLEVEL",
  --l3."CENTSTATUS" AS "l3CENTSTATUS",
  --l3."AOID" AS "l3AOID",
  l3."AOGUID" AS "l3AOGUID",
  l3."PARENTGUID" AS "l3PARENTGUID",
  
  l4.*
FROM (SELECT
  l4.id AS l4id,
  l4."FORMALNAME" AS "l4FORMALNAME",
  -- l4.OFFNAME as l4OFFNAME,
  l4."SHORTNAME" AS "l4SHORTNAME",
  l4."AOGUID" AS "l4AOGUID",
  l4."PARENTGUID" AS "l4PARENTGUID",
  l4."AOLEVEL" AS "l4AOLEVEL",
  --l4."CENTSTATUS" AS "l4CENTSTATUS",
  --l4."AOID" AS "l4AOID",
  --fias.match_weight(l4."FORMALNAME", $1) as "l4PARENT_MATCH",
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
  --l5."CENTSTATUS" AS "l5CENTSTATUS",
  --l5."AOID" AS "l5AOID",
  --fias.match_weight(l5."FORMALNAME", $1) as "l5PARENT_MATCH",
  
  l6.*
FROM (SELECT
  l6.id AS l6id,
  l6."FORMALNAME" AS "l6FORMALNAME",
  -- l6.OFFNAME as l6OFFNAME,
  l6."SHORTNAME" AS "l6SHORTNAME",
  l6."AOGUID" AS "l6AOGUID",
  l6."PARENTGUID" AS "l6PARENTGUID",
  l6."AOLEVEL" AS "l6AOLEVEL",
  --l6."CENTSTATUS" AS "l6CENTSTATUS",
  --l6."AOID" AS "l6AOID",
  --fias.match_weight(l6."FORMALNAME", $1) as "l6PARENT_MATCH",
  
  l7.*
FROM (SELECT
  id AS l7id,
  "FORMALNAME" AS "l7FORMALNAME",
  "SHORTNAME" AS "l7SHORTNAME",
  "AOGUID" AS "l7AOGUID",
  "PARENTGUID" AS "l7PARENTGUID",
  "AOLEVEL" AS "l7AOLEVEL"
  --"CENTSTATUS" AS "l7CENTSTATUS",
  --"AOID" AS "l7AOID"
        FROM
          fias."AddressObjects"
        WHERE 
        lower("FORMALNAME") ~ lower($1)-- or lower("FORMALNAME") ~ lower($2) --[1] or (array_length($1, 1) > 1 and lower("FORMALNAME") ~ $1[array_length($1, 1)])
        --and "ACTSTATUS" = 1
) l7
LEFT JOIN fias."AddressObjects" l6 	ON
          --l6."ACTSTATUS" = 1 AND 
          l7."l7PARENTGUID" = l6."AOGUID" --AND l6.id<>l7.l7id -- AND (a.AOGUID<>@ParentGUID)
) l6
LEFT JOIN fias."AddressObjects" l5 	ON
          --l5."ACTSTATUS" = 1 AND
          l6."l6PARENTGUID" = l5."AOGUID" --AND l5.id<>l6.l6id 
) l5
LEFT JOIN fias."AddressObjects" l4 	ON
          --l4."ACTSTATUS" = 1 AND 
          l5."l5PARENTGUID" = l4."AOGUID" --AND l4.id<>l5.l5id
) l4
LEFT JOIN fias."AddressObjects" l3 	ON
          --l3."ACTSTATUS" = 1 AND 
          l4."l4PARENTGUID" = l3."AOGUID" --AND l3.id<>l4.l4id --  AND l3.REGIONCODE = regcode 
) a;
$func$ LANGUAGE SQL;


-- финальная функция
CREATE OR REPLACE FUNCTION fias.search_formalname(text[])
RETURNS  TABLE(weight int2, "AOGUID" uuid[], "PARENTGUID" uuid[], "AOLEVEL" int2[], "FORMALNAME" text[], "SHORTNAME" varchar(10)[],  id int[])--,"CENTSTATUS" int2[],
AS $func$
DECLARE
  len int := array_length($1, 1);
  a text := $1[1];
  b text := $1[len];
  aa text[];
  bb text[];
BEGIN

IF len > 1 THEN
  aa := $1[2:len];-- со второго до последнего 
  bb := $1[1:len-1]; -- с первого до предпоследнего
  RETURN QUERY
  select --fias.match_weight(u."FORMALNAME"[1:4], aa) + fias.match_weight(u."FORMALNAME"[1:4], bb), 
  *
  from (
    select fias.match_weight(s."FORMALNAME"[1:4], aa) as weight, *
    from fias.search_formalname(a) s
    --where  fias.match_weight(s."FORMALNAME"[1:4], aa) > 0
    
    --union
    
    --select *
    --from fias.search_formalname(b) s
    --where  fias.match_weight(s."FORMALNAME"[1:4], bb) > 0
  ) u
  where  u.weight > 0
  ;
ELSE
  RETURN QUERY
  select null::int2, *
  from fias.search_formalname(a) s;
END IF;

END;

$func$ LANGUAGE plpgsql;

---select * from fias.search_formalname('{моск, корол}'::text[]) order by weight desc, array_to_string("AOLEVEL", '')::int;
--select * from fias.search_formalname('{моск, корол}'::text[]) order by weight desc, array_to_string("AOLEVEL", '')::int, array_to_string("FORMALNAME", '');
--select * from fias.search_formalname('{\\mревол.*, \\mновг.*}'::text[]) order by weight desc, array_to_string("AOLEVEL", '')::int, array_to_string("FORMALNAME", '');



CREATE OR REPLACE FUNCTION fias.aoguid_parents(uuid)
RETURNS  SETOF fias."AddressObjects"
AS $$
-- вывести полный адрес
WITH RECURSIVE child_to_parents AS (
  SELECT a.*
  FROM fias."AddressObjects" a
  WHERE a."AOGUID" = $1--'51f21baa-c804-4737-9d5f-9da7a3bb1598'
UNION ALL
  SELECT a.*
  FROM fias."AddressObjects" a, child_to_parents c
  WHERE a."AOGUID" = c."PARENTGUID"
        --AND a."CURRSTATUS" = 0
        --AND a."ACTSTATUS" = 1
)
SELECT * FROM child_to_parents ORDER BY "AOLEVEL";
$$ LANGUAGE SQL;