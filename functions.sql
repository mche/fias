CREATE or REPLACE FUNCTION fias.match_weight(text, text[])
RETURNS TABLE("weight" int) AS $$
-- посчитать общую сумму совпадений (вес) текста(1 парам) в векторе [регулярки] (2 парам)
select sum((lower($1) ~ x.elem)::int)::int -- не надо lower() для регулярки
from  unnest($2) WITH ORDINALITY AS x(elem, pos);
$$ LANGUAGE SQL;


CREATE OR REPLACE FUNCTION fias.search_formalname(text[])
RETURNS  TABLE("AOGUID" uuid[], "PARENTGUID" uuid[], "AOLEVEL" int2[], "FORMALNAME" text[], "SHORTNAME" varchar(10)[],  id int[], "weight" int)--, "CENTSTATUS" int2[],
AS $func$
-- на входе массив регулярок (сам приводи к нижнему регистру)
select
--distinct
  Array["l7AOGUID", "l6AOGUID", "l5AOGUID", "l4AOGUID", "l3AOGUID"],
  array["l7PARENTGUID", "l6PARENTGUID", "l5PARENTGUID", "l4PARENTGUID", "l3PARENTGUID"],
  array["l7AOLEVEL", "l6AOLEVEL", "l5AOLEVEL", "l4AOLEVEL", "l3AOLEVEL"],
  Array["l7FORMALNAME", "l6FORMALNAME", "l5FORMALNAME", "l4FORMALNAME", "l3FORMALNAME"],
  Array["l7SHORTNAME", "l6SHORTNAME", "l5SHORTNAME", "l4SHORTNAME", "l3SHORTNAME"],
  --Array["l7CENTSTATUS", "l6CENTSTATUS", "l5CENTSTATUS", "l4CENTSTATUS", "l3CENTSTATUS"],
  array[l7id, l6id, l5id, l4id, l3id],
  coalesce("l6weight", 0)+coalesce("l5weight",0) + coalesce("l4weight",0) + coalesce("l3weight", 0)
  
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
  w.weight as "l3weight",

  l4.*
FROM (SELECT
  l4.id AS l4id,
  l4."FORMALNAME" AS "l4FORMALNAME",
  -- l4.OFFNAME as l4OFFNAME,
  l4."SHORTNAME" AS "l4SHORTNAME",
  l4."AOGUID" AS "l4AOGUID",
  l4."PARENTGUID" AS "l4PARENTGUID",
  l4."AOLEVEL" AS "l4AOLEVEL",
  w.weight as "l4weight",
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
  w.weight as "l5weight",
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
  w.weight as "l6weight",
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
        WHERE -- не надо lower($1[1]) для регулярки!
        lower("FORMALNAME") ~ $1[1]-- or lower("FORMALNAME") ~ lower($2) --[1] or (array_length($1, 1) > 1 and lower("FORMALNAME") ~ $1[array_length($1, 1)])
        --and "ACTSTATUS" = 1
) l7
LEFT JOIN fias."AddressObjects" l6 	ON l7."l7PARENTGUID" = l6."AOGUID" --AND l6.id<>l7.l7id -- AND (a.AOGUID<>@ParentGUID)
left join fias.match_weight(l6."FORMALNAME", $1[2 : array_length($1, 1)]) as w on true --
) l6
LEFT JOIN fias."AddressObjects" l5 	ON l6."l6PARENTGUID" = l5."AOGUID" --AND l5.id<>l6.l6id 
left join fias.match_weight(l5."FORMALNAME", $1[2 : array_length($1, 1)]) as w on true
) l5
LEFT JOIN fias."AddressObjects" l4 	ON l5."l5PARENTGUID" = l4."AOGUID" --AND l4.id<>l5.l5id
left join fias.match_weight(l4."FORMALNAME", $1[2 : array_length($1, 1)]) as w on true
) l4
LEFT JOIN fias."AddressObjects" l3 	ON l4."l4PARENTGUID" = l3."AOGUID" --AND l3.id<>l4.l4id --  AND l3.REGIONCODE = regcode 
left join fias.match_weight(l3."FORMALNAME", $1[2 : array_length($1, 1)]) as w on true
) a;
$func$ LANGUAGE SQL;


CREATE OR REPLACE FUNCTION fias.search_address(text[])
RETURNS  TABLE(weight int, "AOGUID" uuid[], "PARENTGUID" uuid[], "AOLEVEL" int2[], "FORMALNAME" text[], "SHORTNAME" varchar(10)[],  id int[], weight_formalname int)--,"CENTSTATUS" int2[],
AS $func$
-- финальная функция
-- на входе массив образцов (регулярки) поиска типа '{\\mревол, \\mподол, \\mмоск}'::text[]
-- регулярки сам приводи к нижнему регистру!
-- select * from fias.search_address('{\\mперм, \\mамур}'::text[]) order by weight desc, array_to_string("AOLEVEL", '')::int, array_to_string("FORMALNAME", '');
select 
  (s."SHORTNAME"[1] = any(array['ул', 'ул.', 'пл', 'пер', 'пр-кт', 'проезд', 'б-р']))::int
    + (coalesce((lower(array_to_string(s."FORMALNAME", ' ')) ~ array_to_string($1[2 : array_length($1, 1)], '.*'))::int, 0)*100)::int
    + s.weight,
  *

from fias.search_formalname($1) as s
where s.weight >= (array_length($1, 1) - 1);

$func$ LANGUAGE SQL;

-- финальная функция
-- на входе массив образцов (регулярки) поиска типа '{\\mревол, \\mподол, \\mмоск}'::text[]
--~CREATE OR REPLACE FUNCTION fias.search_address0000(text[])
--~RETURNS  TABLE(weight int2, "AOGUID" uuid[], "PARENTGUID" uuid[], "AOLEVEL" int2[], "FORMALNAME" text[], "SHORTNAME" varchar(10)[],  id int[], _weight int2)--,"CENTSTATUS" int2[],
--~AS $func$
--~DECLARE
--~  len int := array_length($1, 1);
--~  a text := $1[1];
--~  b text := $1[len];
--~  aa text[];
--~  bb text[];
--~  best_match text;
--~  best_shortname text[] := array['ул', 'ул.', 'пл', 'пер', 'пр-кт', 'проезд', 'б-р'];
--~BEGIN
--~
--~IF len > 1 THEN
--~  aa := $1[2:len];-- со второго до последнего 
--~  best_match := array_to_string(aa, '.*');
--~  bb := $1[1:len-1]; -- с первого до предпоследнего
--~  
--~  RETURN QUERY
--~  select --fias.match_weight(u."FORMALNAME"[1:4], aa) + fias.match_weight(u."FORMALNAME"[1:4], bb),
--~    ((s."SHORTNAME"[1] = any(best_shortname))::int+1)::int2
--~    + (((lower(array_to_string(s."FORMALNAME", ' ')) ~ best_match)::int + 1)*100)::int2
--~    + s._weight as weight,
--~    *
--~  from (
--~    select
--~      *,
--~      fias.match_weight(s."FORMALNAME"[2:5], aa) as _weight
--~    from fias.search_formalname(a) s
--~  ) s
--~  where  s._weight > 0
--~  ;
--~ELSE
--~  RETURN QUERY
--~  select null::int2, *, null::int2
--~  from fias.search_formalname(a) s;
--~END IF;
--~
--~END;
--~
--~$func$ LANGUAGE plpgsql;

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
SELECT *
FROM child_to_parents
-- ORDER BY "AOLEVEL" desc
;
$$ LANGUAGE SQL;

--select uuid, array_agg("FORMALNAME") as "FORMALNAME", array_agg("SHORTNAME") as "SHORTNAME" from (select 'fdb16823-586f-43d2-a1b4-b1c7c7f00bcd'::uuid as uuid, * from fias.aoguid_parents('fdb16823-586f-43d2-a1b4-b1c7c7f00bcd') order by "AOLEVEL" desc) a group by uuid;

CREATE OR REPLACE FUNCTION fias.aoguid_parents_array(uuid)
RETURNS TABLE(uuid uuid, "FORMALNAME" text[], "SHORTNAME" varchar(10)[], "AOGUID" uuid[], "PARENTGUID" uuid[], "AOLEVEL" int2[], id int[])
AS $$
select uuid, array_agg("FORMALNAME") as "FORMALNAME", array_agg("SHORTNAME") as "SHORTNAME" , array_agg("AOGUID") as "AOGUID", array_agg("PARENTGUID") as "PARENTGUID", array_agg("AOLEVEL") as "AOLEVEL", array_agg(id) as id
from (
  select $1 as uuid, *
  from fias.aoguid_parents($1)
  order by "AOLEVEL" desc
) a group by uuid
;
$$ LANGUAGE SQL;

--select * from fias.aoguid_parents_array('fdb16823-586f-43d2-a1b4-b1c7c7f00bcd');

CREATE or REPLACE FUNCTION fias."ТЗ субъектов"()
RETURNS TABLE("AOGUID" uuid, "UTC hour" int) AS $func$
---select "AOGUID", "FORMALNAME", "SHORTNAME" from fias."AddressObjects" where "AOLEVEL"=1 order by 2;
SELECT "AOGUID"::uuid, "UTC hour"::int
FROM (VALUES 
('d8327a56-80de-4df2-815c-4f6ab1224c50','Адыгея','Респ',3),
('5c48611f-5de6-4771-9695-7e36a4e7529d','Алтай','Респ',7),
('8276c6a1-1a86-4f0d-8920-aba34d4cc34a','Алтайский','край',7),
('844a80d6-5e31-4017-b422-4d9c01e9942c','Амурская','обл',9),
('294277aa-e25d-428c-95ad-46719c4ddb44','Архангельская','обл',3),
('83009239-25cb-4561-af8e-7ee111b1cb73','Астраханская','обл',4),
('63ed1a35-4be6-4564-a1ec-0c51f7383314','Байконур','г',5),
('6f2cbfd8-692a-4ee4-9b16-067210bde3fc','Башкортостан','Респ',5),
('639efe9d-3fc8-4438-8e70-ec4f2321f2a7','Белгородская','обл',3),
('f5807226-8be0-4ea8-91fc-39d053aec1e2','Брянская','обл',3),
('a84ebed3-153d-4ba9-8532-8bdf879e1f5a','Бурятия','Респ',8),
('b8837188-39ee-4ff9-bc91-fcc9ed451bb3','Владимирская','обл',3),
('da051ec8-da2e-4a66-b542-473b8d221ab4','Волгоградская','обл',3),
('ed36085a-b2f5-454f-b9a9-1c9a678ee618','Вологодская','обл',3),
('b756fe6b-bbd3-44d5-9302-5bfcc740f46e','Воронежская','обл',3),
('0bb7fa19-736d-49cf-ad0e-9774c4dae09b','Дагестан','Респ',3),
('1b507b09-48c9-434f-bf6f-65066211c73e','Еврейская','Аобл',10),
('b6ba5716-eb48-401b-8443-b197c9578734','Забайкальский','край',9),
('53ec9705-ec3e-4cbf-921f-229968e10aeb','Забайкальский край Агинский Бурятский','округ',9),
('0824434f-4098-4467-af72-d4f702fed335','Ивановская','обл',3),
('b2d8cd20-cabc-4deb-afad-f3c4b4d55821','Ингушетия','Респ',3),
('6466c988-7ce3-45e5-8b97-90ae16cb1249','Иркутская','обл',8),
('c2f0810a-d71e-4af6-85f1-e0bbd81b3e4d','Иркутская обл Усть-Ордынский Бурятский','округ',8),
('1781f74e-be4a-4697-9c6b-493057c94818','Кабардино-Балкарская','Респ',3),
('90c7181e-724f-41b3-b6c6-bd3ec7ae3f30','Калининградская','обл',2),
('491cde9d-9d76-4591-ab46-ea93c079e686','Калмыкия','Респ',3),
('18133adf-90c2-438e-88c4-62c41656de70','Калужская','обл',3),
('d02f30fc-83bf-4c0f-ac2b-5729a866a207','Камчатский','край',12),
('61b95807-388a-4cb1-9bee-889f7cf811c8','Карачаево-Черкесская','Респ',3),
('248d8071-06e1-425e-a1cf-d1ff4c4a14a8','Карелия','Респ',3),
('393aeccb-89ef-4a7e-ae42-08d5cebc2e30','Кемеровская','обл',7),
('0b940b96-103f-4248-850c-26b6c7296728','Кировская','обл',3),
('c20180d9-ad9c-46d1-9eff-d60bc424592a','Коми','Респ',3),
('e3d95b95-cc2d-440d-95c6-65577fae076e','Коми-Пермяцкий','АО',5),
('1e97910c-34fb-428a-a113-13a0024684ae','Корякский','АО',12),
('15784a67-8cea-425b-834a-6afe0e3ed61c','Костромская','обл',3),
('d00e1013-16bd-4c09-b3d5-3cb09fc54bd8','Краснодарский','край',3),
('db9c4f8b-b706-40e2-b2b4-d31b98dcd3d1','Красноярский','край',7),
('bd8e6511-e4b9-4841-90de-6bbc231a789e','Крым','Респ',3),
('4a3d970f-520e-46b9-b16c-50d4ca7535a8','Курганская','обл',5),
('ee594d5e-30a9-40dc-b9f2-0add1be44ba1','Курская','обл',3),
('6d1ebb35-70c6-4129-bd55-da3969658f5d','Ленинградская','обл',3),
('1490490e-49c5-421c-9572-5673ba5d80c8','Липецкая','обл',3),
('9c05e812-8679-4710-b8cb-5e8bd43cdf48','Магаданская','обл',11),
('de2cbfdf-9662-44a4-a4a4-8ad237ae4a3e','Марий Эл','Респ',3),
('37a0c60a-9240-48b5-a87f-0d8c86cdb6e1','Мордовия','Респ',3),
('0c5b2444-70a0-4932-980c-b4dc0d3f02b5','Москва','г',3),
('29251dcf-00a1-4e34-98d4-5c47484a36d4','Московская','обл',3),
('1c727518-c96a-4f34-9ae6-fd510da3be03','Мурманская','обл',3),
('89db3198-6803-4106-9463-cbf781eff0b8','Ненецкий','АО',5),
('88cd27e2-6a8a-4421-9718-719a28a0a088','Нижегородская','обл',3),
('e5a84b81-8ea1-49e3-b3c4-0528651be129','Новгородская','обл',3),
('1ac46b49-3209-4814-b7bf-a509ea1aecd9','Новосибирская','обл',7),
('05426864-466d-41a3-82c4-11e61cdc98ce','Омская','обл',6),
('8bcec9d6-05bc-4e53-b45c-ba0c6f3a5c44','Оренбургская','обл',5),
('5e465691-de23-4c4e-9f46-f35a125b5970','Орловская','обл',3),
('c99e7924-0428-4107-a302-4fd7c0cca3ff','Пензенская','обл',3),
('4f8b1a21-e4bb-422f-9087-d3cbf4bebc14','Пермский','край',5),
('43909681-d6e1-432d-b61f-ddac393cb5da','Приморский','край',10),
('f6e148a1-c9d0-4141-a608-93e3bd95e6c4','Псковская','обл',3),
('f10763dc-63e3-48db-83e1-9c566fe3092b','Ростовская','обл',3),
('963073ee-4dfc-48bd-9a70-d2dfc6bd1f31','Рязанская','обл',3),
('df3d7359-afa9-4aaa-8ff9-197e73906b1c','Самарская','обл',4),
('c2deb16a-0330-4f05-821f-1d09c93331e6','Санкт-Петербург','г',3),
('df594e0e-a935-4664-9d26-0bae13f904fe','Саратовская','обл',3),
('aea6280f-4648-460f-b8be-c2bc18923191','Сахалинская','обл',11),
('c225d3db-1db6-4063-ace0-b3fe9ea3805f','Саха /Якутия/','Респ',11),
('92b30014-4d52-4e2e-892d-928142b924bf','Свердловская','обл',5),
('6fdecb78-893a-4e3f-a5ba-aa062459463b','Севастополь','г',3),
('de459e9c-2933-4923-83d1-9c64cfd7a817','Северная Осетия - Алания','Респ',3),
('e8502180-6d08-431b-83ea-c7038f0df905','Смоленская','обл',3),
('327a060b-878c-4fb4-8dc4-d5595871a3d8','Ставропольский','край',3),
('29a47e2d-7606-481d-98d5-444e755dec34','Таймырский (Долгано-Ненецкий)','АО',7),
('a9a71961-9363-44ba-91b5-ddf0463aebc2','Тамбовская','обл',3),
('0c089b04-099e-4e0e-955a-6bf1ce525f1a','Татарстан','Респ',3),
('61723327-1c20-42fe-8dfa-402638d9b396','Тверская','обл',3),
('889b1f3a-98aa-40fc-9d3d-0f41192758ab','Томская','обл',7),
('d028ec4f-f6da-4843-ada6-b68b3e0efa3d','Тульская','обл',3),
('026bc56f-3731-48e9-8245-655331f596c0','Тыва','Респ',7),
('54049357-326d-4b8f-b224-3c6dc25d6dd3','Тюменская','обл',5),
('52618b9c-bcbb-47e7-8957-95c63f0b17cc','Удмуртская','Респ',4),
('fee76045-fe22-43a4-ad58-ad99e903bd58','Ульяновская','обл',4),
('7d468b39-1afa-41ec-8c4f-97a8603cb3d4','Хабаровский','край',10),
('8d3f1d35-f0f4-41b5-b5b7-e7cadf3e7bd7','Хакасия','Респ',7),
('d66e5325-3a25-4d29-ba86-4ca351d9704b','Ханты-Мансийский Автономный округ - Югра','АО',5),
('27eb7c10-a234-44da-a59c-8b1f864966de','Челябинская','обл',5),
('de67dc49-b9ba-48a3-a4cc-c2ebfeca6c5e','Чеченская','Респ',3),
('878fc621-3708-46c7-a97f-5a13a4176b3e','Чувашская Республика -','Чувашия',3),
('f136159b-404a-4f1f-8d8d-d169e1374d5c','Чукотский','АО',12),
('2d7468f0-bec1-4571-85f3-bdefd62b3d50','Эвенкийский','АО',7),
('826fa834-3ee8-404f-bdbc-13a5221cfb6e','Ямало-Ненецкий','АО',5),
('a84b2ef4-db03-474b-b552-6229e801ae9b','Ярославская','обл',3)
) AS tz ("AOGUID", "FORMALNAME", "SHORTNAME", "UTC hour");
$func$ LANGUAGE SQL;