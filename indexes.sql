ALTER TABLE fias."AddressObjects" ADD CONSTRAINT AddressObjects_pkey PRIMARY KEY("id");
--CREATE UNIQUE INDEX ON fias."AddressObjects" USING btree ("AOID");
CREATE UNIQUE INDEX ON fias."AddressObjects" USING btree ("AOGUID");
--CREATE UNIQUE INDEX ON fias."AddressObjects" USING btree ("AOGUID", "ACTSTATUS", "CURRSTATUS");--, "LIVESTATUS"
CREATE INDEX ON fias."AddressObjects" USING btree ("PARENTGUID");


-- foreign key (parentguid to aoguid)
--ОШИБКА:  в целевой внешней таблице "AddressObjects" нет ограничения уникальности, соответствующего данным ключам
ALTER TABLE fias."AddressObjects" 
  ADD CONSTRAINT AddressObjects_parentguid_fkey FOREIGN KEY ("PARENTGUID")
  REFERENCES fias."AddressObjects" ("AOGUID");


CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX on fias."AddressObjects" USING gin (lower("FORMALNAME") gin_trgm_ops);


---CREATE INDEX currstatus_idx ON addrobj USING btree (currstatus);
--CREATE INDEX aolevel_idx ON addrobj USING btree (aolevel);
--CREATE INDEX formalname_idx ON addrobj USING btree (formalname);
--CREATE INDEX offname_idx ON addrobj USING btree (offname);
--CREATE INDEX shortname_idx ON addrobj USING btree (shortname);
--CREATE INDEX shortname_aolevel_idx ON addrobj USING btree (shortname, aolevel);






