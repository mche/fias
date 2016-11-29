--http://stackoverflow.com/questions/7491479/xml-data-to-postgresql-database/7628453#7628453
--Auxiliary parsing function

CREATE OR REPLACE FUNCTION f_xml_extract_val(text, xml)
  RETURNS text AS
$func$
SELECT CASE
        WHEN $1 ~ '@[[:alnum:]_]+$' THEN
           (xpath($1, $2))[1]
        WHEN $1 ~* '/text()$' THEN
           (xpath($1, $2))[1]
        WHEN $1 LIKE '%/' THEN
           (xpath($1 || 'text()', $2))[1]
        ELSE
           (xpath($1 || '/text()', $2))[1]
       END;
$func$  LANGUAGE sql IMMUTABLE STRICT;


--Handle multiple values

--The above implementation doesn't handle multiple attributes at one xpath. Here is an overloaded version of f_xml_extract_val() for that. With the 3rd parameter you can pick one (the first), all or dist (distinct) values. Multiple values are aggregated to a comma-separated string.

CREATE OR REPLACE FUNCTION f_xml_extract_val(_path text, _node xml, _mode text)
  RETURNS text AS
$func$
DECLARE
   _xpath text := CASE
                   WHEN $1 ~~ '%/'              THEN $1 || 'text()'
                   WHEN lower($1) ~~ '%/text()' THEN $1
                   WHEN $1 ~ '@\w+$'            THEN $1
                   ELSE                              $1 || '/text()'
                  END;
BEGIN

-- fetch one, all or distinct values
CASE $3
    WHEN 'one'  THEN RETURN (xpath(_xpath, $2))[1]::text;
    WHEN 'all'  THEN RETURN array_to_string(xpath(_xpath, $2), ', ');
    WHEN 'dist' THEN RETURN array_to_string(ARRAY(
         SELECT DISTINCT unnest(xpath(_xpath, $2))::text ORDER BY 1), ', ');
    ELSE RAISE EXCEPTION
       'Invalid $3: >>%<<', $3;
END CASE;

END
$func$ LANGUAGE plpgsql IMMUTABLE STRICT;

COMMENT ON FUNCTION f_xml_extract_val(text, xml, text) IS '
# extract element of an xpath from XML document
# Overloaded function to f_xml_extract_val(..)
$3 .. mode is one of: one | all | dist
Example:
SELECT f_xml_extract_val(''//city'', x, ''dist'');
';

--Main part

--Name of target table: tbl; prim. key: id:

CREATE OR REPLACE FUNCTION f_sync_from_xml(file_path text)
  RETURNS boolean AS
$func$
DECLARE
   datafile text := $1;--'path/to/my_file.xml';  -- only relative path in db dir
   myxml    xml := pg_read_file(datafile, 0, 100000000);  -- arbitrary 100 MB max.
BEGIN

-- demonstrating 4 variants of how to fetch values for educational purposes
CREATE TEMP TABLE tmp ON COMMIT DROP AS
SELECT (xpath('//some_id/text()', x))[1]::text AS id    -- id is unique  
      ,f_xml_extract_val('//col1', x)          AS col1  -- one value
      ,f_xml_extract_val('//col2/', x, 'all')  AS col2  -- all values incl. dupes
      ,f_xml_extract_val('//col3/', x, 'dist') AS col3  -- distinct values
FROM   unnest(xpath('/xml/path/to/datum', myxml)) x;

-- 1.) DELETE?

-- 2.) UPDATE
UPDATE tbl t
SET   (  col_1,   col2,   col3) =
      (i.col_1, i.col2, i.col3)
FROM   tmp i
WHERE  t.id = i.id
AND   (t.col_1, t.col2, t.col3) IS DISTINCT FROM
      (i.col_1, i.col2, i.col3);

-- 3.) INSERT NEW
INSERT INTO tbl
SELECT i.*
FROM   tmp i
WHERE  NOT EXISTS (SELECT 1 FROM tbl WHERE id = i.id);

END
$func$  LANGUAGE plpgsql VOLATILE;

