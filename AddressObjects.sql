create table fias."AddressObjects" (
  "AOGUID" uuid not null unique,--Глобальный уникальный идентификатор адресного объекта
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
  "OKATO" char(11), --ОКАТО
  "OKTMO" varchar(11),-- ОКМТО
  "UPDATEDATE" date not null, --Дата внесения записи
  "SHORTNAME" varchar(10) not null,--Краткое наименование типа объекта
  "AOLEVEL" int not null, --Уровень адресного объекта
  "PARENTGUID" uuid, --Идентификатор объекта родительского объекта
  "AOID" uuid not null, -- >Уникальный идентификатор записи. Ключевое поле.
  "PREVID" uuid, -- Идентификатор записи связывания с предыдушей исторической записью
  "NEXTID" uuid, -- Идентификатор записи связывания с последующей исторической записью
  "CODE" varchar(17), --Код адресного объекта одной строкой с признаком актуальности из КЛАДР 4.0.
  "PLAINCODE" varchar(15), -- Код адресного объекта из КЛАДР 4.0 одной строкой без признака актуальности (последних двух цифр)
  "ACTSTATUS" int not null, -- Статус исторической записи в жизненном цикле адресного объекта: 0 – не последняя 1 - последняя
  "CENTSTATUS" int not null, -- Статус центра
  "OPERSTATUS" int not null, -- Статус действия над записью – причина появления записи (см. описание таблицы OperationStatus): 01 – Инициация; 10 – Добавление; 20 – Изменение; 21 – Групповое изменение; 30 – Удаление; 31 - Удаление вследствие удаления вышестоящего объекта; 40 – Присоединение адресного объекта (слияние); 41 – Переподчинение вследствие слияния вышестоящего объекта; 42 - Прекращение существования вследствие присоединения к другому адресному объекту; 43 - Создание нового адресного объекта в результате слияния адресных объектов; 50 – Переподчинение; 51 – Переподчинение вследствие переподчинения вышестоящего объекта; 60 – Прекращение существования вследствие дробления; 61 – Создание нового адресного объекта в результате дробления
  "CURRSTATUS" int not null, -- Статус актуальности КЛАДР 4 (последние две цифры в коде)
  "STARTDATE" date not null, -- Начало действия записи
  "ENDDATE" date not null, -- Окончание действия записи
  "NORMDOC" uuid, --Внешний ключ на нормативный документ
  "LIVESTATUS" boolean not null, --Признак действующего адресного объекта
  "CADNUM" varchar(120), -- Кадастровый номер
  "DIVTYPE" smallint not null, --Тип адресации: 0 - не определено 1 - муниципальный; 2 - административно-территориальный
  