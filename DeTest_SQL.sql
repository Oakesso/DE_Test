/* TRANSACTION and PRODUCT_NOMENCLATURE are imported in bigquery
    they are inserted in a "dataset named "test". they are renamed 
    "transactions" and "product_nomenclature". 
    Few data were added to each table. See provided csv files in folder.*/

/* SQL 1rst part: Calculate total revenues per day from 01/01/2019 to 
31/12/2019 sorted by dates. */

SELECT
	date_ AS date,
    SUM(prod_price_ * prod_qty) AS ca_per_day
FROM `test.transactions`
GROUP BY date_
HAVING date_ BETWEEN '2019-01-01' AND '2019-12-31'
ORDER BY date_ ASC;

/* SQL 2nd part: Get "MEUBLE & DECO" sales per client from 01/01/2019 to 31/12/2019. */

WITH selection1 AS
  /* Get data from product_nomencature joined to transactions on product_id_ 
    common key and add sales calculus. 
    Also filter data for 'MEUBLE' & 'DECO' product_type_ 
    Add another filter layer for purchase date [2019-01-01 to 2019-12-31]. */
  (SELECT 
    *,
    (prod_price_ * prod_qty) AS sales
  FROM `test.product_nomenclature` AS a
  INNER JOIN `test.transactions` AS b
  ON a.product_id_=b.prop_id_
  WHERE product_type_ IN ('MEUBLE', 'DECO')
    AND date_ BETWEEN '2019-01-01' AND '2019-12-31'),

  /* From previous selection1 data aggregate sales values
    and for each client_id_ group by 'product_type_'='DECO'. */
  selection2 AS
  (SELECT 
    client_id_, 
    SUM(sales) AS sales_deco,
  FROM selection1
  WHERE product_type_ = 'DECO'
  GROUP BY client_id_),

  /* From previous selection1 data aggregate sales values
    and for each client_id_ group by 'product_type_'='MEUBLE'. */
  selection3 AS
  (SELECT 
    client_id_, 
    SUM(sales) AS sales_meuble,
  FROM selection1
  WHERE product_type_ = 'MEUBLE'
  GROUP BY client_id_)

/* Join on client_id_' common key selection2 & selection3 tables to be able make 
  appear sales columns for each 'product_type_' together. */
SELECT
  x.client_id_,
  x.sales_deco,
  y.sales_meuble
FROM selection2 AS x 
INNER JOIN selection3 AS y
ON x.client_id_ = y.client_id_