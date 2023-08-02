create database Sale_and_delivery;
use Sale_and_delivery;
select * from cust_dimen;
select * from orders_dimen;
select * from market_fact ;
select * from shipping_dimen;
select * from prod_dimen;



-- 1: Find the top 3 customers who have the maximum number of orders
WITH temp2 AS (
WITH temp1 AS (
  SELECT Cust_id, COUNT(DISTINCT Ord_id) AS Orders
  FROM market_fact
  GROUP BY Cust_id)
  SELECT cust_id, Orders, DENSE_RANK() OVER (ORDER BY Orders DESC) AS ranking
  FROM temp1)
SELECT cust_id, Orders
FROM temp2
WHERE ranking <= 3;

-- 2. Create a new column DaysTakenForDelivery that contains the date difference between Order_Date and Ship_Date.

create or replace view  days_taken_for_delivery as(
SELECT od.order_id ,od.ord_id, order_date, ship_date,
 datediff(str_to_date(ship_date,'%d-%m-%Y'),str_to_date(order_date,'%d-%m-%Y')) as DaysTakenForDelivery 
from orders_dimen od 
JOIN shipping_dimen sd ON od.order_id = sd.order_id );

SELECT * FROM days_taken_for_delivery;

-- 3: Find the customer whose order took the maximum time to get delivered.

SELECT  mf.Cust_id, cd.Customer_Name,mf.Ord_id,order_date,shipping_date, MAX(days_taken_for_delivery) AS max_day
FROM days_taken_for_delivery dtf
JOIN market_fact mf ON dtf.ord_id = mf.Ord_id
JOIN cust_dimen cd ON mf.Cust_id = cd.Cust_id
GROUP BY mf.Cust_id, cd.Customer_Name,mf.Ord_id,order_date,shipping_date
ORDER BY max_day DESC
LIMIT 1;

-- 4: Retrieve total sales made by each product from the data (use Windows function)

select prod_id, sum(sales) as total_sales from market_fact 
group by prod_id 
order by total_sales desc;

select distinct prod_id, round(sum(sales) over( partition by Prod_id),4) total_sales
from market_fact;

-- 5: Retrieve the total profit made from each product from the data (use windows function)
select prod_id, round (sum(profit),4) as total_profit 
from market_fact
group by prod_id 
having total_profit > 0
order by total_profit desc;

-- 6: Count the total number of unique customers in January and how many of them came back every month over the entire year in 2011
create view customer_order_date as(
select cust_id,od.Ord_id,str_to_date(order_date,'%d-%m-%Y') ord_date
from market_fact mf
join orders_dimen od
on mf.Ord_id = od.Ord_id);

SELECT * FROM customer_order_date;

SELECT cust_id
FROM customer_order_date
WHERE year(ord_date) = 2011
GROUP BY cust_id
HAVING COUNT(DISTINCT month(ord_date)) = 12;

-- Restaurant
create database restaurant;
use restaurant;


-- 1: - We need to find out the total visits to all restaurants under all alcohol categories available.
SELECT * FROM chefmozcuisine;
SELECT * FROM geoplaces2;
SELECT * FROM chefmozaccepts;
SELECT * FROM chefmozhours4;
SELECT * FROM rating_final;
SELECT * FROM usercuisine;
SELECT * FROM userpayment;
SELECT * FROM userprofile;

SELECT count(userID) as total_visits
FROM geoplaces2 g
JOIN rating_final
USING (placeID)
WHERE alcohol <> 'No_Alcohol_Served';

-- 2: -Let's find out the average rating according to alcohol and price so that we can 
-- understand the rating in respective price categories as well.
select * from rating_final;



select alcohol,price,avg(ifnull(rating,0)) as average
from rating_final
join geoplaces2
using (placeid)
group by alcohol,price;



select  (select alcohol from geoplaces2 g where g.placeID = r.placeid) as alcohol,
(select  price from geoplaces2 g where g.placeID = r.placeid) as price , avg(ifnull(rating,0)) as avg_rating 
from rating_final r group by alcohol, price order by alcohol;

--  3:  Let’s write a query to quantify that what are the parking availability as well in different alcohol categories
--  along with the total number of restaurants.
select * from chefmozparking;

select  (select alcohol from geoplaces2 g where g.placeid = c.placeid) as alcohol , count(placeid) as total_placeid , parking_lot
from chefmozparking c group by parking_lot, alcohol;

select distinct gp.placeID, gp.name,Rcuisine, gp.alcohol,cp.parking_lot 
from chefmozcuisine cc 
join geoplaces2 gp 
on cc.placeID = gp.placeID
join chefmozparking cp on gp.placeID = cp.placeID
where alcohol <> 'No_Alcohol_Served' and parking_lot <> 'none';

select  gp.alcohol,cp.parking_lot ,count(distinct gp.placeID) as `NO_of_Restuarants`
from chefmozcuisine cc 
join geoplaces2 gp 
on cc.placeID = gp.placeID
join chefmozparking cp 
on gp.placeID = cp.placeID
where alcohol <> 'No_Alcohol_Served' and parking_lot <> 'none'
group by  gp.alcohol,cp.parking_lot ;


-- 4: -Also take out the percentage of different cuisine in each alcohol type.

with temp1 as
(SELECT count(distinct Rcuisine) as total
FROM chefmozcuisine)
,temp2 as(SELECT count( distinct Rcuisine) as actual,alcohol
FROM geoplaces2
JOIN chefmozcuisine
USING (placeID)
GROUP BY alcohol)
SELECT round((actual/total) * 100,2) AS Percentage ,alcohol
FROM temp2
JOIN temp1;

select count(rcuisine) as cuisine_count, rcuisine, (select alcohol from geoplaces2 g where g.placeid = c.placeid) as alcohol, placeid 
from chefmozcuisine c group by placeid, alcohol, rcuisine having alcohol is not null;

-- 5: - let’s take out the average rating of each state.

select distinct state, avg(rating) over(partition by state) avg_rating 
from geoplaces2 g 
JOIN rating_final r 
ON g.placeid = r.placeid 
ORDER BY avg_rating DESC;


select distinct state from geoplaces2;

--  6: -' Tamaulipas' Is the lowest average rated state. 
-- Quantify the reason why it is the lowest rated by providing the summary on the basis of State, alcohol, and Cuisine.
select g.placeID, state, alcohol, rcuisine 
from geoplaces2 g 
join chefmozcuisine c 
ON g.placeid = c.placeid 
where state like '%tamaulipas%';

--  7:  - Find the average weight, food rating, and service rating of the customers who have visited KFC and tried Mexican or Italian types 
-- of cuisine, and also their budget level is low.
-- We encourage you to give it a try by not using joins.
select * from usercuisine;

select avg(food_rating) , avg(service_rating) from rating_final;
select avg(weight) from userprofile where budget = 'low';
select placeid from chefmozcuisine where rcuisine like '%mexican%' or Rcuisine like '%italian%';
select Rcuisine, userid from usercuisine where rcuisine like '%mexican%' or Rcuisine like '%italian%';
select * from userprofile;


select avg(food_rating) as avg_food_rating, avg(service_rating) as avg_service_rating
from rating_final r where userid in (
select  userid from usercuisine where rcuisine in(
select rcuisine from chefmozcuisine where rcuisine like '%mexican%' or Rcuisine like '%italian%' and placeid in (
select placeid from geoplaces2 where name = 'kfc')));
