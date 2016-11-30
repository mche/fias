delimiter $$

CREATE DEFINER=`root`@`192.168.1.8` PROCEDURE `explode`(IN `mylist` VARCHAR(255))
body:
BEGIN
  IF mylist = '' THEN LEAVE body; END IF;
 
  SET @saTail = mylist;
 
  WHILE @saTail != '' DO
    SET @sHead = SUBSTRING_INDEX(@saTail, ',', 1);
    SET @saTail = SUBSTRING( @saTail, LENGTH(@sHead) + 2 );
    ## Тут любой Ваш код
    ## Для примера добавление новых ID пользователей в таблицу users
    INSERT INTO users (id) VALUES (@sHead);
  END WHILE;
 
END$$

