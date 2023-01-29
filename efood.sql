/********    PART I     *********/      
---------   QUERY #1    ---------  


/**   FIND CITIES THAT EXCEEDS 1000 ORDERS    **/

WITH CITIES_OVER_1000_ORDERS AS(
  SELECT 
    city
  FROM 
    `efood2022-376017.main_assessment.orders` 
  GROUP BY
    CITY
  HAVING
    COUNT(order_id) > 1000
)



/**   BREAKFAST USERS WITH >3 ORDERS    **/

,BREAKFAST_USERS_OVER_3_ORDERS_PER_CITY AS(
SELECT
  CITY
  ,COUNT(*) NUM_OF_BREAKFAST_USERS
FROM  (
      SELECT 
        CITY
        ,USER_ID
        ,COUNT(ORDER_ID) ORDERS_PER_USER
      FROM `efood2022-376017.main_assessment.orders` 
      WHERE 
        cuisine = 'Breakfast'
      GROUP BY CITY,USER_ID 
      HAVING COUNT(ORDER_ID) > 3
      )
GROUP BY CITY
)


/**   EFOOD USERS WITH >3 ORDERS    **/

,USERS_OVER_3_ORDERS_PER_CITY AS(
  SELECT CITY,COUNT(*) NUM_OF_USERS
  FROM  (
        SELECT 
          CITY
          ,user_id
          ,COUNT(ORDER_ID) ORDERS_PER_USER
        FROM
          `efood2022-376017.main_assessment.orders` 
        GROUP BY CITY,user_id
        HAVING COUNT(ORDER_ID) > 3
        )
  GROUP BY CITY
)

/**    FIND TOP 5 CITIES WITH THE MOST BREAKFAST ORDERS   **/

,TOP_BREAKFAST_CITIES AS(
  SELECT
    CITY
    ,COUNT(order_id) ORDERS
  FROM 
    `efood2022-376017.main_assessment.orders`
  WHERE 
    cuisine = 'Breakfast'
  GROUP BY CITY 
  ORDER BY 2 DESC
  LIMIT 5 
)

SELECT 
  A.city
  ,SUM(CASE WHEN CUISINE = 'Breakfast' THEN AMOUNT END)
   /COUNT(CASE WHEN CUISINE = 'Breakfast' THEN order_id END)         AS breakfast_basket
  ,SUM(AMOUNT)/COUNT(order_id)                                       AS efood_basket
  ,COUNT(CASE WHEN CUISINE = 'Breakfast' THEN order_id END)
   /COUNT(DISTINCT CASE WHEN CUISINE = 'Breakfast' THEN user_id END) AS breakfast_freq
  ,COUNT(order_id) / COUNT(DISTINCT user_id)                         AS efood_freq
  ,B.NUM_OF_BREAKFAST_USERS
   /COUNT(DISTINCT CASE WHEN CUISINE = 'Breakfast' THEN user_id END) AS breakfast_user3freq_perc
  ,C.NUM_OF_USERS / COUNT(DISTINCT user_id)                          AS efood_user3freq_perc
FROM 
  `efood2022-376017.main_assessment.orders` A
  LEFT JOIN BREAKFAST_USERS_OVER_3_ORDERS_PER_CITY B ON A.CITY = B.CITY
  LEFT JOIN USERS_OVER_3_ORDERS_PER_CITY C           ON A.CITY = C.CITY
  INNER JOIN TOP_BREAKFAST_CITIES D                  ON A.CITY = D.CITY
WHERE 
  A.CITY IN (SELECT * FROM CITIES_OVER_1000_ORDERS)
GROUP BY 
  A.CITY,B.NUM_OF_BREAKFAST_USERS,C.NUM_OF_USERS

  