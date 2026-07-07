/* ===========================================
   01_data_import_check.sas
   목적: CSV 원본 데이터 불러오기 + 결측치/이상치 점검
   =========================================== */

/* events.csv */
proc import datafile='/home/u64184255/중쎄/events.csv'
    out=events
    dbms=csv
    replace;
    guessingrows=max;
run;

*초기 데이터 점검;
proc sql;
    select
        sum(missing(event_id)) as missing_event,
        sum(missing(user_id)) as missing_user,
        sum(missing(product_id)) as missing_product,
        sum(missing(event_type)) as missing_type,
        sum(missing(event_timestamp)) as missing_timestamp
    from events;
quit;
proc sql;
    select event_timestamp, count(*) as cnt
    from events
    group by event_timestamp
    order by event_timestamp;
quit;
proc sql;
    select distinct event_type from events;
quit;
* => 결측치 X, 이상치 확인 불필요, 날짜 문제 X,
    범주형- event_type: cart/purchase/view/wishlist;


/* order_items.csv */
proc import datafile='/home/u64184255/중쎄/order_items.csv'
    out=order_items
    dbms=csv
    replace;
    guessingrows=max;
run;
proc contents data=order_items; run;

*초기 데이터 점검;
proc sql;
    select
       sum(missing(order_item_id)) as missing_items,
        sum(missing(order_id)) as missing_order,
        sum(missing(user_id)) as missing_user,
        sum(missing(quantity)) as missing_quantity,
        sum(missing(item_price)) as missing_price,
        sum(missing(item_total)) as missing_totalprice
    from order_items;
quit;
proc sql;
    select
        sum(item_price <= 0) as invalid_price,
        sum(item_total <= 0) as invalid_total,
        sum(quantity <= 0) as invalid_quantity
    from order_items;
quit;
* => 결측치 X, 이상치 X;


/* orders.csv */
proc import datafile='/home/u64184255/중쎄/orders.csv'
    out=orders
    dbms=csv
    replace;
    guessingrows=max;
run;

*초기 데이터 점검;
proc sql;
    select
        sum(missing(order_id)) as missing_order,
        sum(missing(user_id)) as missing_user,
        sum(missing(order_date)) as missing_date,
        sum(missing(order_status)) as missing_status,
        sum(missing(total_amount)) as missing_totalprice
    from orders;
quit;
proc sql;
   select sum(total_amount <= 0) as invalid_totalprice
   from orders;
quit;
proc sql;
   select order_date, count(*) as cnt
   from orders
   group by order_date
   order by order_date;
quit;
proc sql;
   select distinct order_status from orders;
quit;
* => 결측치 X, 이상치 X, 날짜 문제 X,
    범주형- order_status: cancelled, completed, processing, returned, shipped;


/* products.csv */
proc import datafile='/home/u64184255/중쎄/products.csv'
    out=products
    dbms=csv
    replace;
    guessingrows=max;
run;

*초기 데이터 점검;
proc sql;
    select
        sum(missing(product_id)) as missing_id,
        sum(missing(product_name)) as missing_name,
        sum(missing(category)) as missing_category,
        sum(missing(brand)) as missing_brand,
        sum(missing(price)) as missing_price,
        sum(missing(rating)) as missing_rating
    from products;
quit;
proc sql;
   select sum(price <= 0) as invalid_price,
         sum(rating <= 0) as invalid_rating
   from products;
quit;
proc sql;
   select distinct category from products;
   select distinct brand from products;
quit;
* => 결측치 X, 이상치 X,
    범주형- category: 10종 + brand 12곳;


/* reviews.csv */
proc import datafile='/home/u64184255/중쎄/reviews.csv'
    out=reviews
    dbms=csv
    replace;
    guessingrows=max;
run;

*초기 데이터 점검;
proc sql;
    select
       sum(missing(review_id)) as missing_review,
        sum(missing(order_id)) as missing_order,
        sum(missing(product_id)) as missing_product,
        sum(missing(user_id)) as missing_user,
        sum(missing(rating)) as missing_rating,
        sum(missing(review_text)) as missing_text,
        sum(missing(review_date)) as missing_date
    from reviews;
quit;
proc sql;
   select sum(rating <= 0) as invalid_rating
   from reviews;
quit;
proc sql;
   select review_date, count(*) as cnt
   from reviews
   group by review_date
   order by review_date;
quit;
proc sql;
   select distinct review_text from reviews;
quit;
* => 결측치 X, 이상치 X, 날짜 문제 X,
    범주형- review_text: 10종;


/* users.csv */
proc import datafile='/home/u64184255/중쎄/users.csv'
    out=users
    dbms=csv
    replace;
    guessingrows=max;
run;

*초기 데이터 점검;
proc sql;
    select
        sum(missing(user_id)) as missing_ID,
        sum(missing(name)) as missing_name,
        sum(missing(email)) as missing_email,
        sum(missing(gender)) as missing_gender,
        sum(missing(city)) as missing_city,
        sum(missing(signup_date)) as missing_date
    from users;
quit;
proc sql;
   select signup_date, count(*) as cnt
   from users
   group by signup_date
   order by signup_date;
quit;
proc sql;
   select distinct gender from users;
   select distinct city from users;
quit;
* => 결측치 X, 이상치 X, 날짜 문제 X,
    범주형- gender: Female/Male/Other;
