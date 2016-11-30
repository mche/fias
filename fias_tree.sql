/*************************************************************************/
/* https://habrahabr.ru/post/316314/ */
/* Возвращает дерево (список взаимосвязанных строк) с характеристиками   */
/* адресообразующего элемента */
/*************************************************************************/
CREATE OR REPLACE FUNCTION fias.f_AddressObjectTree(
  a_AOGUID uuid, /* Глобальный уникальный идентификатор */
                                                    /* адресообразующего элемента*/
 a_CurrStatus INTEGER default NULL /* Статус актуальности КЛАДР 4:	 */
                                                   /*	0 - актуальный,  */
                                                    /* 1-50 - исторический, т.е. */
                                                    /*  элемент был переименован, */
                                                   /* в данной записи приведено одно */
                                                   /* из прежних его наименований, */
                                                   /* 51 - переподчиненный */
)
RETURNS TABLE (rtf_AOGUID uuid, rtf_CurrStatus INTEGER, rtf_ActStatus INTEGER, 
                                rtf_AOLevel INTEGER,rtf_ShortTypeName VARCHAR(10),
                                rtf_AddressObjectName VARCHAR(100)) AS
$BODY$
DECLARE
 c_ActualStatusCode CONSTANT INTEGER :=1; /* Признак актуальной записи  */
                                    /* адресообразующего элемента */
 c_NotActualStatusCode CONSTANT INTEGER :=0;	/* Значение кода актуальной записи */
 v_AOGUID     uuid;	 /* ИД адресообразующего элемента */
 v_ParentGUID uuid; /* Идентификатор родительского элемента */
 v_CurrStatus    INTEGER; /* Статус актуальности КЛАДР 4*/
 v_ActStatus     INTEGER; /* Статус актуальности */
                                    /* адресообразующего элемента ФИАС. */
 v_AOLevel      INTEGER; /*Уровень адресообразующего элемента  */
 v_ShortName  VARCHAR(10); /* Краткое наименование типа элемента */
 v_FormalName VARCHAR(120); /* Формализованное наименование элемента */
 v_Return_Error INTEGER;  /* Код возврата */
/***********************************************************************/
 BEGIN
 IF a_CurrStatus IS NOT NULL THEN
    SELECT INTO 
    v_AOGUID,v_ParentGUID,v_CurrStatus,v_ActStatus,v_AOLevel, v_ShortName, v_FormalName
    ao."AOGUID",ao."PARENTGUID",ao."CURRSTATUS",ao."ACTSTATUS",ao."AOLEVEL", ao."SHORTNAME", ao."FORMALNAME"
    FROM fias.AddressObjects ao
    WHERE ao."AOGUID"=a_AOGUID AND ao."CURRSTATUS"=a_CurrStatus;
 ELSE
    SELECT INTO
    v_AOGUID,v_ParentGUID,v_CurrStatus,v_ActStatus,v_AOLevel, v_ShortName, v_FormalName
    ao."AOGUID",ao."PARENTGUID",ao."CURRSTATUS",ao."ACTSTATUS",ao."AOLEVEL", ao."SHORTNAME", ao."FORMALNAME"
    FROM fias.AddressObjects ao
    WHERE ao."AOGUID"=a_AOGUID AND ao."ACTSTATUS"=c_ActualStatusCode;
  ---------------------------------------------------------------
   IF NOT FOUND THEN
      SELECT INTO
      v_AOGUID,v_ParentGUID,v_CurrStatus,v_ActStatus,v_AOLevel, v_ShortName, v_FormalName
      ao."AOGUID",ao."PARENTGUID",ao."CURRSTATUS",ao."ACTSTATUS",ao."AOLEVEL", ao."SHORTNAME", ao."FORMALNAME"
      FROM fias.AddressObjects ao
      WHERE ao."AOGUID"=a_AOGUID 
         AND ao."ACTSTATUS"=c_NotActualStatusCode
         AND ao."CURRSTATUS" = (SELECT MAX(iao."CURRSTATUS") 
                                          FROM fias.AddressObjects iao 
                                          WHERE ao."AOGUID" = iao."AOGUID");
    END IF;
 END IF;
 RETURN QUERY
 SELECT v_AOGUID,v_CurrStatus,v_ActStatus,v_AOLevel, v_ShortName,v_FormalName;
 ----------------------------------------------------------------
 WHILE  v_ParentGUID IS NOT NULL LOOP
     SELECT INTO
     v_AOGUID,v_ParentGUID,v_CurrStatus,v_ActStatus,v_AOLevel, v_ShortName, v_FormalName
     ao."AOGUID",ao."PARENTGUID",ao."CURRSTATUS",ao."ACTSTATUS",ao."AOLEVEL", ao."SHORTNAME",ao."FORMALNAME"
     FROM fias.AddressObjects ao
     WHERE ao."AOGUID"=v_ParentGUID AND ao."ACTSTATUS"=c_ActualStatusCode;
     ---------------------------------------------------
      IF NOT FOUND THEN   
         SELECT INTO
         v_AOGUID,v_ParentGUID,v_CurrStatus,v_ActStatus,v_AOLevel, v_ShortName,v_FormalName
         ao."AOGUID",ao."PARENTGUID",ao."CURRSTATUS",ao."ACTSTATUS",ao."AOLEVEL", ao."SHORTNAME",ao."FORMALNAME"
             FROM fias.AddressObjects ao
             WHERE ao."AOGUID"=v_ParentGUID 
                  AND ao."ACTSTATUS"=c_NotActualStatusCode
                  AND ao."CURRSTATUS" = (SELECT MAX(iao."CURRSTATUS") 
                                                   FROM fias.AddressObjects iao 
                                                   WHERE ao."AOGUID" = iao."AOGUID");
      END IF;	
      RETURN QUERY
      SELECT v_AOGUID,v_CurrStatus,v_ActStatus,v_AOLevel,v_ShortName, v_FormalName;
 END LOOP;
END;
$BODY$
  LANGUAGE plpgsql;

COMMENT ON FUNCTION fias.f_AddressObjectTree(a_AOGUID uuid, 
             a_CurrStatus INTEGER)
IS 'Возвращает дерево (список взаимосвязанных строк) 
     с характеристиками адресообразующего элемента
     
     SELECT * FROM fias.f_AddressObjectTree(''719b789d-2476-430a-89cd-3fedc643d821'',51) ORDER BY rtf_AOLevel;
     SELECT * FROM fias.f_AddressObjectTree(''719b789d-2476-430a-89cd-3fedc643d821'') ORDER BY rtf_AOLevel;
     ';
