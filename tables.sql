create schema if not exists fias; 

create table if not exists fias.config (
  key text not null unique,
  value text not null
);

create table if not exists fias."AddressObjects2" (
  id serial not null, -- primary key
  "AOGUID" uuid not null, -- unique,--Глобальный уникальный идентификатор адресного объекта
  "FORMALNAME" text not null, --Формализованное наименование
  "REGIONCODE" char(2) not null, --Код региона
  "AUTOCODE" char(1) not null, --Код автономии
  "AREACODE" char(3) not null, -- Код района
  "CITYCODE" char(3) not null, --Код города
  "CTARCODE" char(3) not null, --Код внутригородского района
  "PLACECODE" char(3) not null, --Код населенного пункта
  "STREETCODE" char(4), -- Код улицы
  "EXTRCODE" char(4) not null, --Код дополнительного адресообразующего элемента
  "SEXTCODE" char(3) not null, --Код подчиненного дополнительного адресообразующего элемента
  "OFFNAME" text, --Официальное наименование
  "POSTALCODE" char(6), --Почтовый индекс
  "IFNSFL" char(4), -- Код ИФНС ФЛ
  "TERRIFNSFL" char(4), --Код территориального участка ИФНС ФЛ
  "IFNSUL" char(4), --Код ИФНС ЮЛ
  "TERRIFNSUL" char(4), --Код территориального участка ИФНС ЮЛ
  "OKATO" varchar(11), --ОКАТО
  "OKTMO" varchar(11),-- ОКМТО
  "UPDATEDATE" date not null, --Дата внесения записи
  "SHORTNAME" varchar(10) not null,--Краткое наименование типа объекта
  "AOLEVEL" int2 not null, --Уровень адресного объекта
  "PARENTGUID" uuid, --Идентификатор объекта родительского объекта
  "AOID" uuid not null, -- >Уникальный идентификатор записи. Ключевое поле.
  "PREVID" uuid, -- Идентификатор записи связывания с предыдушей исторической записью
  "NEXTID" uuid, -- Идентификатор записи связывания с последующей исторической записью
  "CODE" varchar(17), --Код адресного объекта одной строкой с признаком актуальности из КЛАДР 4.0.
  "PLAINCODE" varchar(15), -- Код адресного объекта из КЛАДР 4.0 одной строкой без признака актуальности (последних двух цифр)
  "ACTSTATUS" int2 not null, -- Статус исторической записи в жизненном цикле адресного объекта: 0 – не последняя 1 - последняя
  "CENTSTATUS" int2 not null, -- Статус центра
  "OPERSTATUS" int2 not null, -- Статус действия над записью – причина появления записи (см. описание таблицы OperationStatus): 01 – Инициация; 10 – Добавление; 20 – Изменение; 21 – Групповое изменение; 30 – Удаление; 31 - Удаление вследствие удаления вышестоящего объекта; 40 – Присоединение адресного объекта (слияние); 41 – Переподчинение вследствие слияния вышестоящего объекта; 42 - Прекращение существования вследствие присоединения к другому адресному объекту; 43 - Создание нового адресного объекта в результате слияния адресных объектов; 50 – Переподчинение; 51 – Переподчинение вследствие переподчинения вышестоящего объекта; 60 – Прекращение существования вследствие дробления; 61 – Создание нового адресного объекта в результате дробления
  "CURRSTATUS" int2 not null, -- Статус актуальности КЛАДР 4 (последние две цифры в коде)
  "STARTDATE" date not null, -- Начало действия записи
  "ENDDATE" date not null, -- Окончание действия записи
  "NORMDOC" uuid, --Внешний ключ на нормативный документ
  "LIVESTATUS" boolean not null, --Признак действующего адресного объекта
  "CADNUM" varchar(120), -- Кадастровый номер
  "DIVTYPE" smallint --not null Тип адресации: 0 - не определено 1 - муниципальный; 2 - административно-территориальный
);


/*
                                      Таблица "fias.AddressObjects"
  Столбец   |          Тип           |                            Модификаторы                            
------------+------------------------+--------------------------------------------------------------------
 id         | integer                | NOT NULL DEFAULT nextval('fias."AddressObjects_id_seq"'::regclass)
 AOGUID     | uuid                   | NOT NULL
 FORMALNAME | text                   | NOT NULL
 REGIONCODE | character(2)           | NOT NULL
 AUTOCODE   | character(1)           | NOT NULL
 AREACODE   | character(3)           | NOT NULL
 CITYCODE   | character(3)           | NOT NULL
 CTARCODE   | character(3)           | NOT NULL
 PLACECODE  | character(3)           | NOT NULL
 STREETCODE | character(4)           | 
 EXTRCODE   | character(4)           | NOT NULL
 SEXTCODE   | character(3)           | NOT NULL
 OFFNAME    | text                   | 
 POSTALCODE | character(6)           | 
 IFNSFL     | character(4)           | 
 TERRIFNSFL | character(4)           | 
 IFNSUL     | character(4)           | 
 TERRIFNSUL | character(4)           | 
 OKATO      | character varying(11)  | 
 OKTMO      | character varying(11)  | 
 UPDATEDATE | date                   | NOT NULL
 SHORTNAME  | character varying(10)  | NOT NULL
 AOLEVEL    | smallint               | NOT NULL
 PARENTGUID | uuid                   | 
 AOID       | uuid                   | NOT NULL
 PREVID     | uuid                   | 
 NEXTID     | uuid                   | 
 CODE       | character varying(17)  | 
 PLAINCODE  | character varying(15)  | 
 ACTSTATUS  | smallint               | NOT NULL
 CENTSTATUS | smallint               | NOT NULL
 OPERSTATUS | smallint               | NOT NULL
 CURRSTATUS | smallint               | NOT NULL
 STARTDATE  | date                   | NOT NULL
 ENDDATE    | date                   | NOT NULL
 NORMDOC    | uuid                   | 
 LIVESTATUS | boolean                | NOT NULL
 CADNUM     | character varying(120) | 
 DIVTYPE    | smallint               | 
Индексы:
    "addressobjects_pkey" PRIMARY KEY, btree (id)
    "AddressObjects_AOID_idx" UNIQUE, btree ("AOID")
    "AddressObjects_AOGUID_idx" btree ("AOGUID")
    "AddressObjects_PARENTGUID_idx" btree ("PARENTGUID")
    "AddressObjects_lower_idx" gin (lower("FORMALNAME") gin_trgm_ops)


*/