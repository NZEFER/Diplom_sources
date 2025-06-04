-- Firebird SQL Solutions Script
-- Содержит решения для всех 6 заданий с альтернативными вариантами

SET TERM ^;

-- Задание №1: Товары без операций
EXECUTE BLOCK AS
BEGIN
    -- Вариант 1: LEFT JOIN
    FOR SELECT g.ID_GOODS, g.NOMENCLATURE
        FROM GOODS g
        LEFT JOIN OPERATION o ON g.ID_GOODS = o.ID_GOODS
        WHERE o.ID_GOODS IS NULL
        INTO :id_goods, :nomenclature
    DO
        SUSPEND;

    -- Вариант 2: NOT EXISTS
    FOR SELECT g.ID_GOODS, g.NOMENCLATURE
        FROM GOODS g
        WHERE NOT EXISTS (SELECT 1 FROM OPERATION o WHERE o.ID_GOODS = g.ID_GOODS)
        INTO :id_goods, :nomenclature
    DO
        SUSPEND;

    -- Вариант 3: NOT IN
    FOR SELECT g.ID_GOODS, g.NOMENCLATURE
        FROM GOODS g
        WHERE g.ID_GOODS NOT IN (
            SELECT o.ID_GOODS FROM OPERATION o 
            WHERE o.ID_GOODS IS NOT NULL
        )
        INTO :id_goods, :nomenclature
    DO
        SUSPEND;
END^

-- Задание №2: Агенты без телефона с операциями в своем городе
EXECUTE BLOCK AS
BEGIN
    -- Вариант 1: С JOIN
    FOR SELECT DISTINCT a.ID_AG, a.NAME_AG
        FROM AGENT a
        JOIN OPERATION o ON a.ID_AG = o.ID_AG
        JOIN WAREHOUSE w ON o.ID_WH = w.ID_WH AND a.TOWN = w.TOWN
        WHERE a.PHONE IS NULL
        INTO :id_ag, :name_ag
    DO
        SUSPEND;

    -- Вариант 2: С EXISTS
    FOR SELECT a.ID_AG, a.NAME_AG
        FROM AGENT a
        WHERE a.PHONE IS NULL
        AND EXISTS (
            SELECT 1 FROM OPERATION o 
            JOIN WAREHOUSE w ON o.ID_WH = w.ID_WH
            WHERE o.ID_AG = a.ID_AG AND w.TOWN = a.TOWN
        )
        INTO :id_ag, :name_ag
    DO
        SUSPEND;
END^

-- Задание №3: Склады с нулевыми остатками без операций в последний месяц
EXECUTE BLOCK AS
BEGIN
    -- Вариант 1: С EXISTS
    FOR SELECT w.ID_WH, w.NAME
        FROM WAREHOUSE w
        WHERE EXISTS (
            SELECT 1 FROM GOODS_WH gw 
            WHERE gw.ID_WH = w.ID_WH AND gw.QUANTITY = 0
        )
        AND NOT EXISTS (
            SELECT 1 FROM OPERATION o 
            WHERE o.ID_WH = w.ID_WH 
            AND o.OP_DATE >= DATEADD(-1 MONTH TO CURRENT_DATE)
        )
        INTO :id_wh, :name
    DO
        SUSPEND;

    -- Вариант 2: С JOIN
    FOR SELECT DISTINCT w.ID_WH, w.NAME
        FROM WAREHOUSE w
        JOIN GOODS_WH gw ON w.ID_WH = gw.ID_WH AND gw.QUANTITY = 0
        LEFT JOIN (
            SELECT DISTINCT ID_WH 
            FROM OPERATION 
            WHERE OP_DATE >= DATEADD(-1 MONTH TO CURRENT_DATE)
        ) recent_ops ON w.ID_WH = recent_ops.ID_WH
        WHERE recent_ops.ID_WH IS NULL
        INTO :id_wh, :name
    DO
        SUSPEND;

    -- Вариант 3: С использованием агрегации
    FOR SELECT w.ID_WH, w.NAME
        FROM WAREHOUSE w
        WHERE w.ID_WH IN (
            SELECT ID_WH FROM GOODS_WH WHERE QUANTITY = 0
        )
        AND w.ID_WH NOT IN (
            SELECT ID_WH FROM OPERATION 
            WHERE OP_DATE >= DATEADD(-1 MONTH TO CURRENT_DATE)
        )
        INTO :id_wh, :name
    DO
        SUSPEND;
END^

-- Задание №4: Часто продаваемые товары без возвратов
EXECUTE BLOCK AS
BEGIN
    -- Решение 1: NOT EXISTS
    FOR SELECT g.ID_GOODS, g.NOMENCLATURE, COUNT(*) AS sales_count
        FROM GOODS g
        JOIN OPERATION o ON g.ID_GOODS = o.ID_GOODS AND o.TYPEOP = 'P'
        WHERE NOT EXISTS (
            SELECT 1 FROM OPERATION o2 
            WHERE o2.ID_GOODS = g.ID_GOODS AND o2.TYPEOP = 'R'
        )
        GROUP BY g.ID_GOODS, g.NOMENCLATURE
        ORDER BY sales_count DESC
        INTO :id_goods, :nomenclature, :sales_count
    DO
        SUSPEND;

    -- Решение 2: LEFT JOIN
    FOR SELECT g.ID_GOODS, g.NOMENCLATURE, COUNT(*) AS sales_count
        FROM GOODS g
        JOIN OPERATION o ON g.ID_GOODS = o.ID_GOODS AND o.TYPEOP = 'P'
        LEFT JOIN OPERATION o2 ON g.ID_GOODS = o2.ID_GOODS AND o2.TYPEOP = 'R'
        WHERE o2.ID_GOODS IS NULL
        GROUP BY g.ID_GOODS, g.NOMENCLATURE
        ORDER BY sales_count DESC
        INTO :id_goods, :nomenclature, :sales_count
    DO
        SUSPEND;

    -- Решение 3: NOT IN
    FOR SELECT g.ID_GOODS, g.NOMENCLATURE, COUNT(*) AS sales_count
        FROM GOODS g
        JOIN OPERATION o ON g.ID_GOODS = o.ID_GOODS AND o.TYPEOP = 'P'
        WHERE g.ID_GOODS NOT IN (
            SELECT DISTINCT ID_GOODS FROM OPERATION WHERE TYPEOP = 'R'
        )
        GROUP BY g.ID_GOODS, g.NOMENCLATURE
        ORDER BY sales_count DESC
        INTO :id_goods, :nomenclature, :sales_count
    DO
        SUSPEND;
END^

-- Задание №5: Топ-5 агентов с наибольшим оборотом и нулевыми операциями
EXECUTE BLOCK AS
BEGIN
    -- Решение 1: С CTE
    FOR WITH AgentSales AS (
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
        SELECT FIRST 5 a.ID_AG, a.NAME_AG, a.total_sum
        FROM AgentSales a
        JOIN ZeroOpsAgents z ON a.ID_AG = z.ID_AG
        ORDER BY a.total_sum DESC
        INTO :id_ag, :name_ag, :total_sum
    DO
        SUSPEND;

    -- Решение 2: Объединение условий
    FOR SELECT FIRST 5 a.ID_AG, a.NAME_AG, SUM(o.QUANTITY * o.PRICE) AS total_sum
        FROM AGENT a
        JOIN OPERATION o ON a.ID_AG = o.ID_AG
        WHERE EXISTS (
            SELECT 1 FROM OPERATION o2 
            WHERE o2.ID_AG = a.ID_AG AND o2.QUANTITY = 0
        )
        GROUP BY a.ID_AG, a.NAME_AG
        ORDER BY total_sum DESC
        INTO :id_ag, :name_ag, :total_sum
    DO
        SUSPEND;

    -- Решение 3: С HAVING
    FOR SELECT FIRST 5 a.ID_AG, a.NAME_AG, SUM(o.QUANTITY * o.PRICE) AS total_sum
        FROM AGENT a
        JOIN OPERATION o ON a.ID_AG = o.ID_AG
        GROUP BY a.ID_AG, a.NAME_AG
        HAVING MAX(CASE WHEN o.QUANTITY = 0 THEN 1 ELSE 0 END) = 1
        ORDER BY total_sum DESC
        INTO :id_ag, :name_ag, :total_sum
    DO
        SUSPEND;
END^

-- Задание №6: Сравнение средней цены товаров
EXECUTE BLOCK RETURNS (avg_price_all_wh DECIMAL(18,2), avg_price_single_wh DECIMAL(18,2)) AS
BEGIN
    -- Решение 1: С подзапросами
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
    GoodsOnSingleWH AS (
        SELECT g.ID_GOODS
        FROM GOODS g
        JOIN GOODS_WH gw ON g.ID_GOODS = gw.ID_GOODS
        GROUP BY g.ID_GOODS
        HAVING COUNT(*) = 1
    )
    SELECT 
        (SELECT AVG(o.PRICE) FROM OPERATION o JOIN GoodsOnAllWH g ON o.ID_GOODS = g.ID_GOODS),
        (SELECT AVG(o.PRICE) FROM OPERATION o JOIN GoodsOnSingleWH g ON o.ID_GOODS = g.ID_GOODS)
    FROM RDB$DATABASE
    INTO avg_price_all_wh, avg_price_single_wh;
    
    SUSPEND;
    
    -- Решение 2: UNION ALL
    FOR WITH GoodsOnAllWH AS (
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
        GROUP BY c.goods_type
        INTO :goods_type, :avg_price
    DO
        SUSPEND;
END^

SET TERM ;^