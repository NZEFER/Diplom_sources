--Задание №1. Найти товары, с которыми не было выполнено ни одной операции


-- Вариант 1: LEFT JOIN
SELECT g.ID_GOODS, g.NOMENCLATURE
FROM GOODS g
LEFT JOIN OPERATION o ON g.ID_GOODS = o.ID_GOODS
WHERE o.ID_GOODS IS NULL;

-- Вариант 2: NOT EXISTS
SELECT g.ID_GOODS, g.NOMENCLATURE
FROM GOODS g
WHERE NOT EXISTS (SELECT 1 FROM OPERATION o WHERE o.ID_GOODS = g.ID_GOODS);

-- Вариант 3: NOT IN
SELECT g.ID_GOODS, g.NOMENCLATURE
FROM GOODS g
WHERE g.ID_GOODS NOT IN (SELECT o.ID_GOODS FROM OPERATION o WHERE o.ID_GOODS IS NOT NULL);



--------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Задание №2. Найти агентов, у которых нет телефона, но которые совершали операции на склады в своем городе

-- Вариант 1: С JOIN
SELECT a.ID_AG, a.NAME_AG
FROM AGENT a
JOIN OPERATION o ON a.ID_AG = o.ID_AG
JOIN WAREHOUSE w ON o.ID_WH = w.ID_WH AND a.TOWN = w.TOWN
WHERE a.PHONE IS NULL;

-- Вариант 2: С EXISTS
SELECT a.ID_AG, a.NAME_AG
FROM AGENT a
WHERE a.PHONE IS NULL
AND EXISTS (
    SELECT 1 FROM OPERATION o 
    JOIN WAREHOUSE w ON o.ID_WH = w.ID_WH
    WHERE o.ID_AG = a.ID_AG AND w.TOWN = a.TOWN
);

	


--------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Задание №3. Найти склады, где есть товары с нулевым остатком, но не было операций в последний месяц


-- Вариант 1: С EXISTS
SELECT w.ID_WH, w.NAME
FROM WAREHOUSE w
WHERE EXISTS (
    SELECT 1 FROM GOODS_WH gw 
    WHERE gw.ID_WH = w.ID_WH AND gw.QUANTITY = 0
)
AND NOT EXISTS (
    SELECT 1 FROM OPERATION o 
    WHERE o.ID_WH = w.ID_WH 
    AND o.OP_DATE >= DATEADD(-1 MONTH TO CURRENT_DATE)
);

-- Вариант 2: С JOIN
SELECT DISTINCT w.ID_WH, w.NAME
FROM WAREHOUSE w
JOIN GOODS_WH gw ON w.ID_WH = gw.ID_WH AND gw.QUANTITY = 0
LEFT JOIN (
    SELECT DISTINCT ID_WH 
    FROM OPERATION 
    WHERE OP_DATE >= DATEADD(-1 MONTH TO CURRENT_DATE)
) recent_ops ON w.ID_WH = recent_ops.ID_WH
WHERE recent_ops.ID_WH IS NULL;


--Вариант 3: С использованием агрегации
SELECT w.ID_WH, w.NAME
FROM WAREHOUSE w
WHERE w.ID_WH IN (
    SELECT ID_WH FROM GOODS_WH WHERE QUANTITY = 0
)
AND w.ID_WH NOT IN (
    SELECT ID_WH FROM OPERATION 
    WHERE OP_DATE >= DATEADD(-1 MONTH TO CURRENT_DATE)
);


--------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Задание №4. Найти товары, которые чаще всего продавались (операции типа 'P'), но ни разу не возвращались (операции типа 'R')

SELECT g.ID_GOODS, g.NOMENCLATURE, COUNT(*) AS sales_count
FROM GOODS g
JOIN OPERATION o ON g.ID_GOODS = o.ID_GOODS AND o.TYPEOP = 'P'
WHERE NOT EXISTS (
    SELECT 1 FROM OPERATION o2 
    WHERE o2.ID_GOODS = g.ID_GOODS AND o2.TYPEOP = 'R'
)
GROUP BY g.ID_GOODS, g.NOMENCLATURE
ORDER BY sales_count DESC;


--Решение 2: С использованием LEFT JOIN и фильтрации null
SELECT g.ID_GOODS, g.NOMENCLATURE, COUNT(*) AS sales_count
FROM GOODS g
JOIN OPERATION o ON g.ID_GOODS = o.ID_GOODS AND o.TYPEOP = 'P'
LEFT JOIN OPERATION o2 ON g.ID_GOODS = o2.ID_GOODS AND o2.TYPEOP = 'R'
WHERE o2.ID_GOODS IS NULL
GROUP BY g.ID_GOODS, g.NOMENCLATURE
ORDER BY sales_count DESC;

--Решение 3: С подзапросом для товаров с возвратами
SELECT g.ID_GOODS, g.NOMENCLATURE, COUNT(*) AS sales_count
FROM GOODS g
JOIN OPERATION o ON g.ID_GOODS = o.ID_GOODS AND o.TYPEOP = 'P'
WHERE g.ID_GOODS NOT IN (
    SELECT DISTINCT ID_GOODS FROM OPERATION WHERE TYPEOP = 'R'
)
GROUP BY g.ID_GOODS, g.NOMENCLATURE
ORDER BY sales_count DESC;


--------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Задание №5. Найти топ-5 агентов с наибольшим оборотом (сумма операций), у которых есть хотя бы одна операция с нулевым количеством

--Решение 1:
    SELECT a.ID_AG, a.NAME_AG, SUM(o.QUANTITY * o.PRICE) AS total_sum
    FROM AGENT a
    JOIN OPERATION o ON a.ID_AG = o.ID_AG
    GROUP BY a.ID_AG, a.NAME_AG
),
ZeroOpsAgents AS (
    SELECT DISTINCT o.ID_AG
    FROM OPERATION o
    WHERE o.QUANTITY = 0
)
SELECT a.ID_AG, a.NAME_AG, a.total_sum
FROM AgentSales a
JOIN ZeroOpsAgents z ON a.ID_AG = z.ID_AG
ORDER BY a.total_sum DESC
ROWS 5;


--Решение 2: Объединение условий в одном запросе
SELECT a.ID_AG, a.NAME_AG, SUM(o.QUANTITY * o.PRICE) AS total_sum
FROM AGENT a
JOIN OPERATION o ON a.ID_AG = o.ID_AG
WHERE EXISTS (
    SELECT 1 FROM OPERATION o2 
    WHERE o2.ID_AG = a.ID_AG AND o2.QUANTITY = 0
)
GROUP BY a.ID_AG, a.NAME_AG
ORDER BY total_sum DESC
ROWS 5;


--Решение 3: С использованием HAVING
SELECT a.ID_AG, a.NAME_AG, SUM(o.QUANTITY * o.PRICE) AS total_sum
FROM AGENT a
JOIN OPERATION o ON a.ID_AG = o.ID_AG
GROUP BY a.ID_AG, a.NAME_AG
HAVING MAX(CASE WHEN o.QUANTITY = 0 THEN 1 ELSE 0 END) = 1
ORDER BY total_sum DESC
ROWS 5;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Задание №6. Сравнить среднюю цену товаров, которые есть на всех складах, с ценой товаров, которые есть только на одном складе

-- Товары на всех складах
WITH GoodsOnAllWH AS (
    SELECT g.ID_GOODS
    FROM GOODS g
    WHERE NOT EXISTS (
        SELECT 1 FROM WAREHOUSE w
        WHERE NOT EXISTS (
            SELECT 1 FROM GOODS_WH gw 
            WHERE gw.ID_WH = w.ID_WH AND gw.ID_GOODS = g.ID_GOODS
        )
    )
),
-- Товары только на одном складе
GoodsOnSingleWH AS (
    SELECT g.ID_GOODS
    FROM GOODS g
    JOIN GOODS_WH gw ON g.ID_GOODS = gw.ID_GOODS
    GROUP BY g.ID_GOODS
    HAVING COUNT(*) = 1
)
SELECT 
    (SELECT AVG(o.PRICE) FROM OPERATION o JOIN GoodsOnAllWH g ON o.ID_GOODS = g.ID_GOODS) AS avg_price_all_wh,
    (SELECT AVG(o.PRICE) FROM OPERATION o JOIN GoodsOnSingleWH g ON o.ID_GOODS = g.ID_GOODS) AS avg_price_single_wh;


   
--Решение 1: Использование UNION ALL для объединения результатов
WITH GoodsOnAllWH AS (
    SELECT g.ID_GOODS, 'ALL' AS goods_type
    FROM GOODS g
    WHERE NOT EXISTS (
        SELECT 1 FROM WAREHOUSE w
        WHERE NOT EXISTS (
            SELECT 1 FROM GOODS_WH gw 
            WHERE gw.ID_WH = w.ID_WH AND gw.ID_GOODS = g.ID_GOODS
        )
    )
),
GoodsOnSingleWH AS (
    SELECT g.ID_GOODS, 'SINGLE' AS goods_type
    FROM GOODS g
    JOIN GOODS_WH gw ON g.ID_GOODS = gw.ID_GOODS
    GROUP BY g.ID_GOODS
    HAVING COUNT(*) = 1
),
CombinedGoods AS (
    SELECT * FROM GoodsOnAllWH
    UNION ALL
    SELECT * FROM GoodsOnSingleWH
)
SELECT 
    c.goods_type,
    AVG(o.PRICE) AS avg_price
FROM CombinedGoods c
JOIN OPERATION o ON c.ID_GOODS = o.ID_GOODS
GROUP BY c.goods_type;



--Решение 2: Использование CASE в агрегации
WITH GoodsDistribution AS (
    SELECT 
        g.ID_GOODS,
        CASE WHEN COUNT(DISTINCT gw.ID_WH) = (SELECT COUNT(*) FROM WAREHOUSE) THEN 'ALL'
             WHEN COUNT(DISTINCT gw.ID_WH) = 1 THEN 'SINGLE'
             ELSE 'OTHER' END AS distribution_type
    FROM GOODS g
    LEFT JOIN GOODS_WH gw ON g.ID_GOODS = gw.ID_GOODS
    GROUP BY g.ID_GOODS
)
SELECT 
    AVG(CASE WHEN gd.distribution_type = 'ALL' THEN o.PRICE ELSE NULL END) AS avg_price_all_wh,
    AVG(CASE WHEN gd.distribution_type = 'SINGLE' THEN o.PRICE ELSE NULL END) AS avg_price_single_wh
FROM GoodsDistribution gd
JOIN OPERATION o ON gd.ID_GOODS = o.ID_GOODS;


