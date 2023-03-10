/***    FIND THE FREQUENCY AND MONETARY OF EACH USER    ***/

WITH FREQUENCY_MONETARY AS(
  SELECT 
    USER_ID
    ,COUNT(ORDER_ID) AS FREQUENCY
    ,ROUND(SUM(AMOUNT),2) AS MONETARY
  FROM
    `efood2022-376017.main_assessment.orders` 
  GROUP BY
      USER_ID
)

/**   MAKE SEGMENTATIONS FOR FREQUENCY AND MONETARY USING QUANTILES   **/
,SEGMENTATION_GROUPS AS(
  SELECT
    USER_ID
    ,FREQUENCY
    ,MONETARY
    ,CASE WHEN FREQUENCY    <=   (SELECT APPROX_QUANTILES(FREQUENCY,100)[offset(25)]   FROM  FREQUENCY_MONETARY)  THEN 'GROUP 4(1)' 
          WHEN FREQUENCY BETWEEN (SELECT APPROX_QUANTILES(FREQUENCY,100)[offset(25)]+1 FROM  FREQUENCY_MONETARY)  AND (SELECT APPROX_QUANTILES(FREQUENCY,100)[offset(50)] FROM  FREQUENCY_MONETARY)  THEN 'GROUP 3(2)'
          WHEN FREQUENCY BETWEEN (SELECT APPROX_QUANTILES(FREQUENCY,100)[offset(50)]+1 FROM  FREQUENCY_MONETARY)  AND (SELECT APPROX_QUANTILES(FREQUENCY,100)[offset(75)] FROM  FREQUENCY_MONETARY)  THEN 'GROUP 2(3-5)'
          WHEN FREQUENCY     >   (SELECT APPROX_QUANTILES(FREQUENCY,100)[offset(75)]   FROM  FREQUENCY_MONETARY)  THEN 'GROUP 1(6+)'
    END AS FREQUENCY_SEGMENTATION
    ,CASE WHEN MONETARY  <=  (SELECT APPROX_QUANTILES(MONETARY,100)[offset(25)] FROM  FREQUENCY_MONETARY) THEN 'GROUP 4(11.6)' 
          WHEN MONETARY  >   (SELECT APPROX_QUANTILES(MONETARY,100)[offset(25)] FROM  FREQUENCY_MONETARY) AND MONETARY <= (SELECT APPROX_QUANTILES(MONETARY,100)[offset(50)] FROM FREQUENCY_MONETARY) THEN 'GROUP 3(11.7-23.3)'
          WHEN MONETARY  >   (SELECT APPROX_QUANTILES(MONETARY,100)[offset(50)] FROM  FREQUENCY_MONETARY) AND MONETARY <= (SELECT APPROX_QUANTILES(MONETARY,100)[offset(75)] FROM FREQUENCY_MONETARY) THEN 'GROUP 2(23.4-47.3)'
          WHEN MONETARY  >   (SELECT APPROX_QUANTILES(MONETARY,100)[offset(75)] FROM  FREQUENCY_MONETARY) THEN 'GROUP 1(47.4+)'
    END AS MONETARY_SEGMENTATION
  FROM  FREQUENCY_MONETARY
  ORDER BY FREQUENCY DESC,MONETARY DESC
)


/** FIND THE BREAKFAST ORDERS OF EACH USER  **/

,BREAKFAST_USERS AS(
  SELECT 
    USER_ID AS BR_USER_ID
    ,COUNT(ORDER_ID) AS BR_FREQUENCY
    ,SUM(AMOUNT)     AS BR_MONETARY
  FROM
    `efood2022-376017.main_assessment.orders` 
  WHERE 1=1
    AND cuisine = 'Breakfast'
  GROUP BY
      USER_ID
)

/**  CACLULATE THE AVERAGE PERCENTAGE OF BREAKFAST ORDERS FOR EVERY PAIR OF FREQUENCY_SEGMENTATION GROUP AND MONETARY_SEGMENTATION GROUP **/
SELECT 
  FREQUENCY_SEGMENTATION
  ,MONETARY_SEGMENTATION
  ,ROUND(AVG(CASE WHEN B.BR_FREQUENCY/A.FREQUENCY  IS NULL THEN 0 ELSE B.BR_FREQUENCY / A.FREQUENCY  END),2) AS BR_PERCENT
FROM
  SEGMENTATION_GROUPS A
  LEFT JOIN BREAKFAST_USERS B ON A.USER_ID = B.BR_USER_ID
GROUP BY 
  FREQUENCY_SEGMENTATION,MONETARY_SEGMENTATION
ORDER BY
  1,2


