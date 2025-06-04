
-- Заполнение таблицы GOODS
EXECUTE BLOCK AS
DECLARE VARIABLE I INT;
BEGIN
  I = 1;
  WHILE (I <= 1000) DO BEGIN
    INSERT INTO GOODS (ID_GOODS, NOMENCLATURE, MEASURE)
    VALUES ('G' || LPAD(I, 4, '0'), 'Product_' || I, 'pcs');
    I = I + 1;
  END
END;

-- Заполнение таблицы AGENT
EXECUTE BLOCK AS
DECLARE VARIABLE I INT;
BEGIN
  I = 1;
  WHILE (I <= 100) DO BEGIN
    INSERT INTO AGENT (ID_AG, NAME_AG, TOWN, PHONE)
    VALUES ('A' || LPAD(I, 3, '0'), 'Agent_' || I, 'Town_' || MOD(I, 20) + 1, LPAD(1000000000 + I, 10, '0'));
    I = I + 1;
  END
END;

-- Заполнение таблицы WAREHOUSE
EXECUTE BLOCK AS
DECLARE VARIABLE I INT;
BEGIN
  I = 1;
  WHILE (I <= 20) DO BEGIN
    INSERT INTO WAREHOUSE (ID_WH, NAME, TOWN)
    VALUES ('W' || LPAD(I, 2, '0'), 'Warehouse_' || I, 'City_' || MOD(I, 5) + 1);
    I = I + 1;
  END
END;

-- Заполнение таблицы GOODS_WH (каждый склад с 50 товарами)
EXECUTE BLOCK AS
DECLARE VARIABLE W_ID INT;
DECLARE VARIABLE I INT;
DECLARE VARIABLE G_ID INT;
BEGIN
  W_ID = 1;
  WHILE (W_ID <= 20) DO BEGIN
    I = 1;
    WHILE (I <= 50) DO BEGIN
      G_ID = 1 + FLOOR(RAND() * 1000);
      INSERT INTO GOODS_WH (ID_WH, ID_GOODS, QUANTITY)
      VALUES ('W' || LPAD(W_ID, 2, '0'), 'G' || LPAD(G_ID, 4, '0'), RAND() * 1000);
      I = I + 1;
    END
    W_ID = W_ID + 1;
  END
END;

-- Заполнение таблицы OPERATION (5000 строк)
EXECUTE BLOCK AS
DECLARE VARIABLE I INT;
DECLARE VARIABLE GID INT;
DECLARE VARIABLE AID INT;
DECLARE VARIABLE WID INT;
DECLARE VARIABLE QTY NUMERIC(15,2);
DECLARE VARIABLE PRICE NUMERIC(15,2);
DECLARE VARIABLE DT DATE;
DECLARE VARIABLE TYPEOP CHAR(1);
BEGIN
  I = 1;
  WHILE (I <= 5000) DO BEGIN
    GID = 1 + FLOOR(RAND() * 1000);
    AID = 1 + FLOOR(RAND() * 100);
    WID = 1 + FLOOR(RAND() * 20);
    QTY = RAND() * 100;
    PRICE = 10 + RAND() * 90;
    DT = CURRENT_DATE - FLOOR(RAND() * 365);
    IF (RAND() < 0.5) THEN TYPEOP = 'P'; ELSE TYPEOP = 'R';

    INSERT INTO OPERATION (ID_GOODS, ID_AG, ID_WH, TYPEOP, QUANTITY, PRICE, OP_DATE)
    VALUES (
      'G' || LPAD(GID, 4, '0'),
      'A' || LPAD(AID, 3, '0'),
      'W' || LPAD(WID, 2, '0'),
      TYPEOP,
      QTY,
      PRICE,
      DT
    );
    I = I + 1;
  END
END;




-------------------------------------------------------------------------------------------------------------------
-- Заполнение таблицы GOODS (создадим несколько товаров, которые не будут участвовать в операциях)
EXECUTE BLOCK
AS
DECLARE i INTEGER;
BEGIN
  FOR i = 1 TO 1100 DO
  BEGIN
    INSERT INTO GOODS (ID_GOODS, NOMENCLATURE, MEASURE)
    VALUES (
      'G' || LPAD(i, 4, '0'),
      'Product_' || i,
      CASE WHEN MOD(i, 10) = 0 THEN NULL ELSE 'pcs' END
    );
  END
END;

-- Заполнение таблицы AGENT (создадим агентов без телефонов и городов)
EXECUTE BLOCK
AS
DECLARE i INTEGER;
BEGIN
  FOR i = 1 TO 120 DO
  BEGIN
    INSERT INTO AGENT (ID_AG, NAME_AG, TOWN, PHONE)
    VALUES (
      'A' || LPAD(i, 3, '0'),
      'Agent_' || i,
      CASE WHEN MOD(i, 7) = 0 THEN NULL ELSE 'Town_' || (MOD(i, 20) + 1) END,
      CASE WHEN MOD(i, 5) = 0 THEN NULL ELSE LPAD(CAST(1000000000 + i AS VARCHAR(10)), 10, '0') END
    );
  END
END;

-- Заполнение таблицы WAREHOUSE (один склад будет пустым)
EXECUTE BLOCK
AS
DECLARE i INTEGER;
BEGIN
  FOR i = 1 TO 21 DO
  BEGIN
    INSERT INTO WAREHOUSE (ID_WH, NAME, TOWN)
    VALUES (
      'W' || LPAD(i, 2, '0'),
      'Warehouse_' || i,
      'City_' || (MOD(i, 5) + 1)
    );
  END
END;

-- Заполнение таблицы GOODS_WH (основные записи)
EXECUTE BLOCK
AS
DECLARE i INTEGER;
DECLARE j INTEGER;
DECLARE wh_id VARCHAR(20);
DECLARE goods_id VARCHAR(20);
BEGIN
  FOR wh_id IN SELECT ID_WH FROM WAREHOUSE WHERE ID_WH != 'W21' DO
  BEGIN
    FOR j = 1 TO 50 DO
    BEGIN
      goods_id = 'G' || LPAD(CAST(1 + FLOOR(RAND() * 1000) AS VARCHAR(4)), 4, '0');
      
      INSERT INTO GOODS_WH (ID_WH, ID_GOODS, QUANTITY)
      VALUES (
        wh_id,
        goods_id,
        CASE WHEN RAND() < 0.1 THEN 0 ELSE ROUND(RAND() * 1000, 2) END
      );
    END
  END
END;

-- Добавляем товары с нулевым остатком на всех складах
EXECUTE BLOCK
AS
DECLARE i INTEGER;
DECLARE j INTEGER;
DECLARE wh_id VARCHAR(20);
DECLARE goods_id VARCHAR(20);
BEGIN
  FOR i = 1 TO 3 DO
  BEGIN
    FOR wh_id IN SELECT ID_WH FROM WAREHOUSE WHERE ID_WH != 'W21' ORDER BY RAND() ROWS 3 DO
    BEGIN
      goods_id = 'G' || LPAD(CAST(1001 + FLOOR(RAND() * 100) AS VARCHAR(4)), 4, '0');
      
      INSERT INTO GOODS_WH (ID_WH, ID_GOODS, QUANTITY)
      VALUES (
        wh_id,
        goods_id,
        0
      );
    END
  END
END;

-- Заполнение таблицы OPERATION (основные записи)
EXECUTE BLOCK
AS
DECLARE i INTEGER;
DECLARE goods_id VARCHAR(20);
DECLARE ag_id VARCHAR(20);
DECLARE wh_id VARCHAR(20);
BEGIN
  FOR i = 1 TO 5000 DO
  BEGIN
    goods_id = CASE 
      WHEN MOD(i, 50) = 0 THEN NULL 
      ELSE 'G' || LPAD(CAST(1 + FLOOR(RAND() * 1000) AS VARCHAR(4)), 4, '0')
    END;
    
    ag_id = CASE 
      WHEN MOD(i, 40) = 0 THEN NULL 
      ELSE 'A' || LPAD(CAST(1 + FLOOR(RAND() * 100) AS VARCHAR(3)), 3, '0')
    END;
    
    wh_id = CASE 
      WHEN MOD(i, 60) = 0 THEN NULL 
      ELSE 'W' || LPAD(CAST(1 + FLOOR(RAND() * 20) AS VARCHAR(2)), 2, '0')
    END;
    
    INSERT INTO OPERATION (ID_GOODS, ID_AG, ID_WH, TYPEOP, QUANTITY, PRICE, OP_DATE)
    VALUES (
      goods_id,
      ag_id,
      wh_id,
      CASE WHEN RAND() < 0.5 THEN 'P' ELSE 'R' END,
      ROUND(RAND() * 100, 2),
      ROUND(10 + RAND() * 90, 2),
      DATEADD(-CAST(RAND() * 365 AS INTEGER) DAY TO CURRENT_DATE
    );
  END
END;

-- Добавляем операции с нулевым количеством
EXECUTE BLOCK
AS
DECLARE i INTEGER;
BEGIN
  FOR i = 1 TO 50 DO
  BEGIN
    INSERT INTO OPERATION (ID_GOODS, ID_AG, ID_WH, TYPEOP, QUANTITY, PRICE, OP_DATE)
    VALUES (
      'G' || LPAD(CAST(1 + FLOOR(RAND() * 1000) AS VARCHAR(4)), 4, '0'),
      'A' || LPAD(CAST(1 + FLOOR(RAND() * 100) AS VARCHAR(3)), 3, '0'),
      'W' || LPAD(CAST(1 + FLOOR(RAND() * 20) AS VARCHAR(2)), 2, '0'),
      CASE WHEN RAND() < 0.5 THEN 'P' ELSE 'R' END,
      0,
      ROUND(10 + RAND() * 90, 2),
      DATEADD(-CAST(RAND() * 365 AS INTEGER) DAY TO CURRENT_DATE
    );
  END
END;