
-- Заполнение таблицы GOODS
INSERT INTO GOODS (ID_GOODS, NOMENCLATURE, MEASURE)
SELECT 
  'G' || LPAD(i::text, 4, '0'),
  'Product_' || i,
  'pcs'
FROM generate_series(1, 1000) AS s(i);

-- Заполнение таблицы AGENT
INSERT INTO AGENT (ID_AG, NAME_AG, TOWN, PHONE)
SELECT 
  'A' || LPAD(i::text, 3, '0'),
  'Agent_' || i,
  'Town_' || ((i % 20) + 1),
  LPAD((1000000000 + i)::text, 10, '0')
FROM generate_series(1, 100) AS s(i);

-- Заполнение таблицы WAREHOUSE
INSERT INTO WAREHOUSE (ID_WH, NAME, TOWN)
SELECT 
  'W' || LPAD(i::text, 2, '0'),
  'Warehouse_' || i,
  'City_' || ((i % 5) + 1)
FROM generate_series(1, 20) AS s(i);

-- Заполнение таблицы GOODS_WH
INSERT INTO GOODS_WH (ID_WH, ID_GOODS, QUANTITY)
SELECT 
  w.id_wh,
  'G' || LPAD((1 + floor(random() * 1000))::int::text, 4, '0'),
  round(random() * 1000, 2)
FROM warehouse w, generate_series(1, 50);

-- Заполнение таблицы OPERATION
INSERT INTO OPERATION (ID_GOODS, ID_AG, ID_WH, TYPEOP, QUANTITY, PRICE, OP_DATE)
SELECT
  'G' || LPAD((1 + floor(random() * 1000))::int::text, 4, '0'),
  'A' || LPAD((1 + floor(random() * 100))::int::text, 3, '0'),
  'W' || LPAD((1 + floor(random() * 20))::int::text, 2, '0'),
  CASE WHEN random() < 0.5 THEN 'P' ELSE 'R' END,
  round(random() * 100, 2),
  round(10 + random() * 90, 2),
  current_date - (random() * 365)::int
FROM generate_series(1, 5000);



------------------------------------------
-- Заполнение таблицы GOODS (создадим несколько товаров, которые не будут участвовать в операциях)
INSERT INTO GOODS (ID_GOODS, NOMENCLATURE, MEASURE)
SELECT 
  'G' || LPAD(i::text, 4, '0'),
  'Product_' || i,
  CASE WHEN i % 10 = 0 THEN NULL ELSE 'pcs' END -- у каждого 10-го товара нет единицы измерения
FROM generate_series(1, 1100) AS s(i); -- создадим на 100 товаров больше, чем будет в операциях

-- Заполнение таблицы AGENT (создадим агентов без телефонов и городов)
INSERT INTO AGENT (ID_AG, NAME_AG, TOWN, PHONE)
SELECT 
  'A' || LPAD(i::text, 3, '0'),
  'Agent_' || i,
  CASE WHEN i % 7 = 0 THEN NULL ELSE 'Town_' || ((i % 20) + 1) END, -- у каждого 7-го агента нет города
  CASE WHEN i % 5 = 0 THEN NULL ELSE LPAD((1000000000 + i)::text, 10, '0') END -- у каждого 5-го агента нет телефона
FROM generate_series(1, 120) AS s(i); -- создадим на 20 агентов больше, чем будет в операциях

-- Заполнение таблицы WAREHOUSE (один склад будет пустым)
INSERT INTO WAREHOUSE (ID_WH, NAME, TOWN)
SELECT 
  'W' || LPAD(i::text, 2, '0'),
  'Warehouse_' || i,
  'City_' || ((i % 5) + 1)
FROM generate_series(1, 21) AS s(i); -- создадим 21 склад (один лишний)

-- Заполнение таблицы GOODS_WH (создадим записи с нулевым количеством и пропустим некоторые товары)
INSERT INTO GOODS_WH (ID_WH, ID_GOODS, QUANTITY)
WITH wh_goods AS (
  SELECT 
    w.id_wh,
    'G' || LPAD((1 + floor(random() * 1000))::int::text, 4, '0') as id_goods,
    round(random() * 1000, 2) as quantity
  FROM warehouse w, generate_series(1, 50)
  WHERE w.id_wh != 'W21' -- не будем добавлять товары на склад W21 (он будет пустым)
)
SELECT 
  id_wh,
  id_goods,
  CASE WHEN random() < 0.1 THEN 0 ELSE quantity END -- у 10% товаров будет нулевой остаток
FROM wh_goods;

-- Добавим несколько товаров с нулевым остатком на всех складах
INSERT INTO GOODS_WH (ID_WH, ID_GOODS, QUANTITY)
SELECT 
  w.id_wh,
  'G' || LPAD((1001 + floor(random() * 100))::int::text, 4, '0'), -- товары из диапазона 1001-1100
  0 -- нулевой остаток
FROM warehouse w, generate_series(1, 3) -- на 3 случайных складах
WHERE w.id_wh != 'W21';

-- Заполнение таблицы OPERATION (исключим некоторые товары и агентов)
INSERT INTO OPERATION (ID_GOODS, ID_AG, ID_WH, TYPEOP, QUANTITY, PRICE, OP_DATE)
SELECT
  CASE 
    WHEN i % 50 = 0 THEN NULL -- у 2% операций нет товара (для задач на JOIN)
    ELSE 'G' || LPAD((1 + floor(random() * 1000))::int::text, 4, '0') -- только товары 1-1000
  END,
  CASE 
    WHEN i % 40 = 0 THEN NULL -- у 2.5% операций нет агента
    ELSE 'A' || LPAD((1 + floor(random() * 100))::int::text, 3, '0') -- только агенты 1-100
  END,
  CASE 
    WHEN i % 60 = 0 THEN NULL -- у ~1.7% операций нет склада
    ELSE 'W' || LPAD((1 + floor(random() * 20))::int::text, 2, '0') -- только склады 1-20
  END,
  CASE WHEN random() < 0.5 THEN 'P' ELSE 'R' END,
  round(random() * 100, 2),
  round(10 + random() * 90, 2),
  current_date - (random() * 365)::int
FROM generate_series(1, 5000) AS s(i);

-- Создадим несколько операций с нулевым количеством
INSERT INTO OPERATION (ID_GOODS, ID_AG, ID_WH, TYPEOP, QUANTITY, PRICE, OP_DATE)
SELECT
  'G' || LPAD((1 + floor(random() * 1000))::int::text, 4, '0'),
  'A' || LPAD((1 + floor(random() * 100))::int::text, 3, '0'),
  'W' || LPAD((1 + floor(random() * 20))::int::text, 2, '0'),
  CASE WHEN random() < 0.5 THEN 'P' ELSE 'R' END,
  0, -- нулевое количество
  round(10 + random() * 90, 2),
  current_date - (random() * 365)::int
FROM generate_series(1, 50) AS s(i); -- 50 операций с нулевым количеством


Теперь в данных есть следующие особенности:

Товары с ID G1001-G1100 не участвуют в операциях (можно искать товары без операций)

У каждого 10-го товара нет единицы измерения (NULL в поле MEASURE)

Агенты с ID A101-A120 не участвуют в операциях

У каждого 7-го агента нет города (NULL в поле TOWN)

У каждого 5-го агента нет телефона (NULL в поле PHONE)

Склад W21 не имеет товаров (можно искать пустые склады)

Около 10% записей в GOODS_WH имеют нулевой остаток

Некоторые товары (1001-1100) имеют нулевой остаток на всех складах

Около 2% операций не имеют привязки к товару

Около 2.5% операций не имеют привязки к агенту

Около 1.7% операций не имеют привязки к складу

50 операций с нулевым количеством товара

Эти "дыры" в данных позволят отрабатывать различные сценарии запросов, включая проверки на NULL, LEFT JOIN с поиском отсутствующих связей и другие сложные условия.