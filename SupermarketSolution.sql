---SQL Queries to Answers of Supermarket_sale_Problem--
---1                  -----
SELECT
    b.`Branch Name` AS branch_name,
    t1.`Product line` AS product_line,
    Round(((t1.`Gross income` - t2.avg_income) / t2.avg_income) * 100,2) AS income_increase
FROM
    supermarket_sales_dataset t1
    JOIN (
        SELECT
            `Branch Code`,
            AVG(`Gross income`) AS avg_income
        FROM
            supermarket_sales_dataset
        WHERE
            MONTH(`Date`) IN (1, 2)
            AND `Product line` = 'Electronic accessories'
        GROUP BY
            `Branch Code`
    ) t2 ON t1.`Branch Code` = t2.`Branch Code`
    JOIN branch b ON b.`Branch Code` = t1.`Branch Code`
WHERE
    MONTH(t1.`Date`) = 3
    AND t1.`Product line` = 'Electronic accessories'
ORDER BY
    income_increase ASC;

---2    -----
SELECT
    `Product line` AS product_line,
    SUM(`Gross income`) AS total_income
FROM
    supermarket_sales_dataset
WHERE
    YEAR(`Date`) = 2019
    AND WEEK(`Date`, 1) = 1
GROUP BY
    `Product line`
ORDER BY
    total_income DESC
LIMIT 1
----3------

SELECT
    TIME(`Time`) AS time,
    COUNT(*) AS no_of_occurrences
FROM
    supermarket_sales_dataset
WHERE
    MONTH(`Date`) = 2
    AND WEEKDAY(`Date`) IN (5, 6) -- 5 and 6 represent Saturday and Sunday
GROUP BY
    TIME(`Time`)
ORDER BY
    no_of_occurrences DESC
LIMIT 5;


----4----
SELECT
    s.`Date` AS date,
    s.`Product line` AS product_line,
    c.`City Name` AS city_name,
    s.`Gross income` AS gross_income
FROM
    supermarket_sales_dataset s
    JOIN branch b ON s.`Branch Code` = b.`Branch Code`
    JOIN city c ON s.`City Code` = c.`City Code`
WHERE
    s.`Product line` IN ('Electronic accessories', 'Food and beverages')
    AND DATE_FORMAT(s.`Date`, '%Y-%m-%d') BETWEEN '2019-02-01' AND '2019-02-07'
    AND s.`Gross income` = (
        SELECT MAX(`Gross income`)
        FROM supermarket_sales_dataset
        WHERE `Product line` = s.`Product line`
        AND DATE_FORMAT(`Date`, '%Y-%m-%d') BETWEEN '2019-02-01' AND '2019-02-07'
    )
ORDER BY
    s.`Date`, s.`Product line`;


-- 5                             --

SELECT
    t.`Customer type`,
    t.`Product line`,
    Round(t.`gross_income`,2),
    t.no_of_purchases,
    t.rank_val
FROM (
    SELECT
        s1.`Customer type`,
        s1.`Product line`,
        s1.gross_income,
        s1.no_of_purchases,
        (CASE
            WHEN (@prev_customer_type = s1.`Customer type`) THEN @rank := @rank + 1
            ELSE @rank := 1
        END) AS rank_val,
        (@prev_customer_type := s1.`Customer type`)
    FROM (
        SELECT
            s.`Customer type`,
            s.`Product line`,
            SUM(s.`Gross income`) AS gross_income,
            COUNT(*) AS no_of_purchases
        FROM
            supermarket_sales_dataset s
        WHERE
            s.`Customer type` != 'Unknown'
        GROUP BY
            s.`Customer type`,
            s.`Product line`
        ORDER BY
            s.`Customer type`,
            gross_income DESC
    ) s1
    CROSS JOIN (SELECT @rank := 0, @prev_customer_type := '') AS r
) t
WHERE
    t.rank_val <= 3
ORDER BY
    t.`Customer type`,
    t.rank_val DESC;
--6  ------

SELECT
    b.`Branch Code`,
    b.`Branch Name`,
    s.`Customer Type`,
    SUM(s.`Gross income`) AS gross_income,
    CASE
        WHEN SUM(s.`Gross income`) >= 500 THEN 'high income'
        ELSE 'low income'
    END AS income_category
FROM
    supermarket_sales_dataset s
JOIN
    branch b ON s.`Branch Code` = b.`Branch Code`
WHERE
    s.`Customer Type` IN ('Member', 'Normal') AND s.`Customer Type` != 'Unknown'
GROUP BY
    b.`Branch Code`,
    b.`Branch Name`,
    s.`Customer Type`
ORDER BY
    b.`Branch Code`,
    s.`Customer Type`;


-----7---


SELECT
    s1.`Date`,
    s1.`Product line`,
    s1.total_quantity_sold,
    COALESCE(prev.prev_day_qty, 0) AS prev_day_qty,
    COALESCE(next.next_day_qty, 0) AS next_day_qty,
    COALESCE(s1.total_quantity_sold, 0) - COALESCE(prev.prev_day_qty, 0) AS diff_prev_day_qty,
    COALESCE(next.next_day_qty, 0) - COALESCE(s1.total_quantity_sold, 0) AS diff_next_day_qty
FROM (
    SELECT
        `Date`,
        `Product line`,
        SUM(`Quantity`) AS total_quantity_sold
    FROM
        supermarket_sales_dataset
    WHERE
        `Date` BETWEEN '2019-03-01' AND '2019-03-07'
        AND `Product line` IN ('Health and beauty', 'Home and lifestyle', 'Food and beverages')
    GROUP BY
        `Date`,
        `Product line`
) s1
LEFT JOIN (
    SELECT
        `Date`,
        `Product line`,
        SUM(`Quantity`) AS prev_day_qty
    FROM
        supermarket_sales_dataset
    WHERE
        DATE_SUB(`Date`, INTERVAL 1 DAY) BETWEEN '2019-03-01' AND '2019-03-07'
        AND `Product line` IN ('Health and beauty', 'Home and lifestyle', 'Food and beverages')
    GROUP BY
        `Date`,
        `Product line`
) prev ON s1.`Date` = DATE_SUB(prev.`Date`, INTERVAL 1 DAY) AND s1.`Product line` = prev.`Product line`
LEFT JOIN (
    SELECT
        `Date`,
        `Product line`,
        SUM(`Quantity`) AS next_day_qty
    FROM
        supermarket_sales_dataset
    WHERE
        DATE_ADD(`Date`, INTERVAL 1 DAY) BETWEEN '2019-03-01' AND '2019-03-07'
        AND `Product line` IN ('Health and beauty', 'Home and lifestyle', 'Food and beverages')
    GROUP BY
        `Date`,
        `Product line`
) next ON s1.`Date` = DATE_ADD(next.`Date`, INTERVAL 1 DAY) AND s1.`Product line` = next.`Product line`
ORDER BY
    s1.`Date`;

-- 8  ----

SELECT
    rank_val AS `rank`,
    t.`City Name` AS `city_name`,
    t.`Customer type` AS `customer_type`,
    avg_rating AS `avg_rating`
FROM (
    SELECT
        `City Name`,
        `Customer type`,
        AVG(Rating) AS avg_rating,
        RANK() OVER (ORDER BY AVG(Rating) DESC) AS rank_val
    FROM
        supermarket_sales_dataset ss
    JOIN
        city c ON ss.`City Code` = c.`City Code`
    WHERE
        ss.`Customer type` != 'Unknown'
    GROUP BY
        `City Name`,
        `Customer type`
) t
ORDER BY
    rank_val;


--9---


SELECT
    s.`Product line` AS product_line,
    c.`City name` AS city_name,
    SUM(s.Quantity) AS total_qty_sold,
    Round(SUM(s.`Gross income`),2)as gross_income
FROM
    supermarket_sales_dataset s
JOIN
    city c ON s.`City code` = c.`City code`
WHERE
    DAYOFWEEK(s.`Date`) = 1 OR DAYOFWEEK(s.`Date`) = 7
GROUP BY
    s.`Product line`,
    c.`City name`
ORDER BY
    total_qty_sold DESC;



