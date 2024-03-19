--------danny's 1st week challange
CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

--drop table if exists sales;
CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  
-- 1. What is the total amount each customer spent at the restaurant?
 select customer_id,sum(price) from sales e1 inner join menu e2 on e1.product_id=e2.product_id
 group by customer_id order by customer_id;

 -- 2. How many days has each customer visited the restaurant?
with tt1 as(
select customer_id,
dense_rank() over(partition by customer_id order by order_date) as edays 
from sales)
select customer_id,max(edays) from tt1 group by customer_id;

-- 3. What was the first item from the menu purchased by each customer?
select e1.customer_id,e1.product_id,product_name from(
select customer_id,product_id,row_number() over(partition by customer_id) as nr from sales) e1 inner join menu e2 on e1.product_id=e2.product_id 
where nr=1


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
with e5 as (
select product_id,count(*) as psmee from sales group by product_id)
select e.psmee,e8.product_name from e5 e inner join menu e8 on e.product_id=e8.product_id 
order by psmee desc limit 1;

-- 5. Which item was the most popular for each customer?
with q1 as(
select customer_id,product_id,count(*) as notba 
from sales group by customer_id,product_id order by customer_id,product_id desc)
select customer_id,product_name from (
select customer_id,product_name,
rank()over(partition by customer_id order by notba desc) as rn from q1 e5 inner join menu e8 on e5.product_id=e8.product_id)
where rn=1;


-- 6. Which item was purchased first by the customer after they became a member?
select customer_id,product_name from(
select e1.customer_id
,e1.order_date,e1.product_id,e5.product_name,
rank()over(partition by e1.customer_id order by e1.order_date) as nr
from sales e1 inner join members e2 on e1.customer_id=e2.customer_id
inner join menu e5 on e1.product_id=e5.product_id
where e1.order_date>=e2.join_date)
where nr=1;

-- 7. Which item was purchased just before the customer became a member?
select customer_id,product_name from(
select e1.customer_id
,e1.order_date,e1.product_id,e5.product_name,
dense_rank()over(partition by e1.customer_id order by e1.order_date desc) as nr1
from sales e1 inner join members e2 on e1.customer_id=e2.customer_id
inner join menu e5 on e1.product_id=e5.product_id
where e1.order_date<e2.join_date)
where nr1=1;

-- 8. What is the total items and amount spent for each member before they became a member?
select customer_id,ip,sm from (select row_number() over(partition by e1.customer_id) as nr,
e1.customer_id,e1.product_id,price,
count(e1.product_id)over(partition by e1.customer_id) as ip,
sum(price) over(partition by e1.customer_id) as sm
from sales e1 inner join members e5 on e1.customer_id=e5.customer_id and e1.order_date<e5.join_date
inner join menu e8 on e1.product_id=e8.product_id)
where nr=1;


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with t1 as(select customer_id,
case when e1.product_id= 1 then e8.price*20 
else e8.price*10 end as point
from sales e1 
inner join menu e8 on e1.product_id=e8.product_id) 
select customer_id,sum(point) as points from t1 group by customer_id order by customer_id;



---- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
------------this one is solution for the order will get 2x points after their first ordering date 
with et1 as(
select customer_id,order_date+6 as edate from(
select *,row_number() over(partition by customer_id order by order_date) as enr11 from sales) where enr11=1),
 t1 as(select e1.customer_id,--order_date,edate,e1.product_id,price,
case when e1.product_id= 1 then e8.price*20 
	when e1.product_id in (2,3) and order_date between order_date and edate then e8.price*20
else e8.price*10 end as point
from sales e1 inner join menu e8 on e1.product_id=e8.product_id
inner join et1 on e1.customer_id=et1.customer_id )  



select customer_id,sum(point)from t1 group by customer_id order by customer_id; --order by customer_id,order_date;



