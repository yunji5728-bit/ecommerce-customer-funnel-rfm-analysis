/* ===========================================
   02_vip_behavior_segment.sas
   목적: 매출/반품 요약, VIP 등급, 행동 세그먼트,
        Behavior x VIP 매트릭스 분석
   =========================================== */

/* 4-1 매출 요약 (orders_clean 사용) */
proc sql;
    create table user_sales_summary as
    select user_id,
           count(distinct order_id) as order_cnt,
           sum(total_amount) as total_sales
    from orders_clean
    group by user_id;
quit;

/* 4-2 반품 요약 */
proc sql;
    create table user_return_summary as
    select user_id, count(distinct order_id) as return_cnt
    from orders_return
    group by user_id;
quit;

/* 4-3 매출+반품 결합 */
proc sql;
    create table user_sales_summary2 as
    select s.user_id, s.order_cnt, s.total_sales,
           case when r.return_cnt is null then 0 else r.return_cnt end as return_cnt,
           case when s.order_cnt > 0 then
                (case when r.return_cnt is null then 0 else r.return_cnt end) / s.order_cnt
                else . end as return_rate
    from user_sales_summary s
    left join user_return_summary r on s.user_id = r.user_id;
quit;

/* 5. 행동 + 매출 통합 테이블 */
proc sql;
    create table final_user_summary as
    select u.user_id, u.avg_depth, u.max_depth,
           u.total_cart, u.total_view, u.product_variety,
           case when s.order_cnt is null then 0 else s.order_cnt end as order_cnt,
           case when s.total_sales is null then 0 else s.total_sales end as total_sales,
           case when s.return_cnt is null then 0 else s.return_cnt end as return_cnt,
           s.return_rate
    from user_summary u
    left join user_sales_summary2 s on u.user_id = s.user_id;
quit;

/* 6. VIP 등급 생성 (5분위, Monetary 기준) */
proc rank data=final_user_summary out=final_user_vip groups=5;
    var total_sales;
    ranks monetary_quintile;
run;

data final_user_vip;
    set final_user_vip;
    length VIP_level $5;
    if monetary_quintile = 4 then VIP_level = 'VIP1';       /* 상위 20% */
    else if monetary_quintile = 3 then VIP_level = 'VIP2';
    else if monetary_quintile = 2 then VIP_level = 'VIP3';
    else if monetary_quintile = 1 then VIP_level = 'VIP4';
    else VIP_level = 'VIP5';                                 /* 하위 20% */
run;

/* 7. 행동 세그먼트 생성
   * 초기에는 avg_depth >= 3 기준으로 High_engager를 정의했으나,
     실제 데이터 분포상 해당 고객이 극소수임을 확인.
     퍼널 단계별 의미와 세그먼트 해석력을 높이기 위해
     평균 깊이 분포를 기준으로 컷을 조정함 (>=2 기준). */
data final_user_segment;
    set final_user_vip;
    length behavior_segment $15;
    if avg_depth >= 2 then behavior_segment = 'High_engager';
    else if avg_depth >= 1.5 then behavior_segment = 'Medium_engager';
    else behavior_segment = 'Low_engager';
run;

/* 8. Behavior x Monetary 매트릭스 */
proc sql;
    create table behavior_monetary_matrix as
    select behavior_segment, VIP_level,
           count(user_id) as user_count,
           avg(total_sales) as avg_sales
    from final_user_segment
    group by behavior_segment, VIP_level
    order by behavior_segment, VIP_level;
quit;

/* 엑셀 검증용 샘플 추출 */
proc sql;
    create table excel_check_sample as
    select *
    from final_user_segment
    where user_id in ('U000003', 'U000077', 'U000310');
quit;

proc export data=excel_check_sample
    outfile="/home/u64184255/excel_check_sample.xlsx"
    dbms=xlsx
    replace;
run;
