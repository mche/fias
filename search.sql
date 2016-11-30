--explain
select count(*)
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
  
  l7.*
FROM (SELECT
  id AS l7id,
  "FORMALNAME" AS "l7FORMALNAME",
  "SHORTNAME" AS "l7SHORTNAME",
  "AOGUID" AS "l7AOGUID",
  "PARENTGUID" AS "l7PARENTGUID",
  "AOLEVEL" AS "l7AOLEVEL",
  --CENTSTATUS AS l7CENTSTATUS,
  "AOID" AS "l7AOID"
        FROM
          fias."AddressObjects"
        WHERE 
        lower("FORMALNAME") ~ 'мас'
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
) a
;