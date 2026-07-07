/* ===========================================
   01_preprocessing_funnel.sas
   목적: 데이터 전처리 + event_type -> depth 매핑
        고객 단위 행동 요약(avg_depth 등) 산출
   =========================================== */

/* 1-1 Users 문자열 처리 & 결측 처리 */
proc sql;
    create table users_norm as
    select user_id,
        case when missing(lowcase(city)) then '미기입'
             else lowcase(city)
        end as city length=30,
        case when missing(lowcase(gender)) then '미기입'
             else lowcase(gender)
        end as gender length=10,
        signup_date
    from users;
quit;

/* 1-2 Products 카테고리 문자열 정규화 */
proc sql;
    create table products_norm as
    select product_id, lowcase(category) as category length=30,
           price, rating
    from products;
quit;

/* 1-3 Orders 전처리: Cancelled/Returned 제거, 날짜 YYYY-MM-DD 변환 */
proc sql;
    create table orders_clean as
    select user_id, order_id, total_amount,
           lowcase(strip(order_status)) as order_status_norm length=15,
           order_date as order_dt format=datetime20.,
           datepart(order_date) as order_date_num format=yymmdd10.
    from orders
    where lowcase(strip(order_status)) not in ('cancelled','returned');
quit;

/* 1-4 Cancelled/Returned만 따로 추출 (반품 분석용) */
proc sql;
    create table orders_return as
    select user_id, order_id, lowcase(strip(order_status)) as order_status_norm
    from orders
    where lowcase(strip(order_status)) in ('cancelled','returned');
quit;

/* 2-1 신규 vs 기존 고객 분류 */
proc sql;
    create table users_base as
    select u.*,
           year(signup_date) as signup_year,
           case when year(signup_date) >= 2024 then 1 else 0 end as new_flag
    from users_norm u;
quit;

/* 2-2 지역별 구매량 분석 */
proc sql;
    create table city_sales as
    select u.city, sum(o.total_amount) as total_sales,
           count(distinct o.order_id) as order_cnt
    from users_base u
    left join orders_clean o on u.user_id = o.user_id
    group by u.city;
quit;

/* 2-3 성별x도시별 소비 패턴 분석 */
proc sql;
    create table gender_city_sales as
    select u.gender, u.city,
           sum(o.total_amount) as total_sales, avg(o.total_amount) as avg_order_amount
    from users_base u
    left join orders_clean o on u.user_id = o.user_id
    group by u.gender, u.city;
quit;

/* 3-1 event_type -> depth 매핑 */
data events_depth;
    set events;
    if event_type = "view" then depth = 1;
    else if event_type = "wishlist" then depth = 2;
    else if event_type = "cart" then depth = 3;
    else if event_type = "purchase" then depth = 4;
run;

/* 3-2 고객 x 상품별 최대 행동 깊이 계산 */
proc sql;
    create table user_product_depth as
    select user_id, product_id, max(depth) as max_depth
    from events_depth
    group by user_id, product_id;
quit;

/* 3-3 고객 x 상품별 행동 횟수 요약 */
proc sql;
    create table user_product_counts as
    select user_id, product_id,
        sum(event_type="view") as view_count,
        sum(event_type="wishlist") as wishlist_count,
        sum(event_type="cart") as cart_count,
        sum(event_type="purchase") as purchase_count
    from events_depth
    group by user_id, product_id;
quit;

/* 3-4 행동 요약 테이블 통합 */
proc sql;
    create table user_product_summary as
    select d.user_id, d.product_id, d.max_depth,
           c.view_count, c.wishlist_count, c.cart_count, c.purchase_count
    from user_product_depth d
    left join user_product_counts c
        on d.user_id = c.user_id and d.product_id = c.product_id;
quit;

/* 3-5 고객 단위 요약 (행동 기반 통계) */
proc sql;
    create table user_summary as
    select user_id,
           mean(max_depth) as avg_depth,
           max(max_depth) as max_depth,
           sum(view_count) as total_view,
           sum(wishlist_count) as total_wishlist,
           sum(cart_count) as total_cart,
           sum(purchase_count) as total_purchase,
           count(distinct product_id) as product_variety
    from user_product_summary
    group by user_id;
quit;
