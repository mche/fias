-- foreign key (parentguid to aoguid)
-- ALTER TABLE addrobj DROP CONSTRAINT addrobj_parentguid_fkey;
ALTER TABLE fias."AddressObjects" 
  ADD CONSTRAINT AddressObjects_parentguid_fkey FOREIGN KEY ("PARENTGUID")
  REFERENCES fias."AddressObjects" ("AOGUID") MATCH SIMPLE
ON UPDATE CASCADE ON DELETE NO ACTION;


CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- CREATE UNIQUE INDEX aoid_idx ON addrobj USING btree (aoid);
CREATE INDEX parentguid_idx ON fias."AddressObjects" USING btree ("PARENTGUID");
CREATE INDEX currstatus_idx ON addrobj USING btree (currstatus);
CREATE INDEX aolevel_idx ON addrobj USING btree (aolevel);
CREATE INDEX formalname_idx ON addrobj USING btree (formalname);
CREATE INDEX offname_idx ON addrobj USING btree (offname);
CREATE INDEX shortname_idx ON addrobj USING btree (shortname);
CREATE INDEX shortname_aolevel_idx ON addrobj USING btree (shortname, aolevel);


-- trigram indexes to speed up text searches
CREATE INDEX formalname_trgm_idx on addrobj USING gin (formalname gin_trgm_ops);
CREATE INDEX offname_trgm_idx on addrobj USING gin (offname gin_trgm_ops);