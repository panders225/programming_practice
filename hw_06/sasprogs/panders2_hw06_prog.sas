/************************************************************************
 * Last Run Date: 18 Feb 2017	            							*
 * Program Name: panders2_hw06_prog.sas									*
 * Program Location: C:/Users/Philip/Schools/TAMU/STAT_657/				*
 *				SASUniversityEdition/myfolders/homework/git_hw/hw_06/sasprogs/	* 
 * Creation Date: 13 Feb 2017											*
 * Author: Philip Anderson												*
 * Purpose: Meeting objectives for Assignment 06						*
 * Inputs: scholarship03.sas7bdat         *
 * Output: panders2_hw06_output.pdf															*
 * Modification History: Finished work on 18 Feb*
 * Execution Instructions: N/A - run as-is												*
*/**********************************************************************;

/* Using the library from the previous hw assignment*/
libname prev '/folders/myfolders/homework/git_hw/hw_05/sasdata' access=readonly;

/*output pdf*/
filename out_pdf '/folders/myfolders/homework/git_hw/hw_06/output/panders2_hw06_output.pdf';

/* Assign sasdata library to the directory for this assignment*/
libname sasdata '/folders/myfolders/homework/git_hw/hw_06/sasdata' access=readonly;

/* link to the orion datasets*/
libname orion '/folders/myfolders/orion_dat/sasdata' access=readonly;

/* remove page numbers from output */
options nonumber;
/* Question 1 - Create the report from step 4 of assignment 05, using an in-line view */

/* Open up our output pdf */
ods pdf file=out_pdf;

title '2003 NCAA Team Scoring Analysis';
proc sql;
select
/* b. keep only one record per school */
team
/* c. create some additional columns */
, count(distinct player) as Players
, round(avg(ppg), 0.1) as team_avg label='Average PPG'
, (calculated team_avg / tot_avg_ppg ) as t_v_o label='Team vs. Overall' format=percent8.1
/* d. Create a column that changes labels based on team's relative ppg */
, (case when calculated t_v_o > 1 then 'Above Avg.' else 'Avg. or Below' end) as ppg_lev
   label='PPG Level'
    from
    (
    select
    team
    , player
    , ppg
/*     , (select avg(ppg) from prev.scholarship03 ) as tot_avg_ppg */
    , average_points as tot_avg_ppg
    from
    /* a. use an inline view instead of a pre-created dataset*/
        (
            select
            player
            , team
            , region
            , PPG
            /* remerge a global summary statistic of mean ppg */
            , mean(PPG) as Average_Points
            from
            prev.scholarship03
            /* a. remove players with team seeds of 15 or 16 */
            where Seed_ not in (15, 16)
        )

    )
group by
team
/* e. only keep teams with 5 or more players */
having calculated Players >= 5
/* f. sort by PPG highest to lowest */
order by 
calculated team_avg desc
;
quit;

/* Question 2 - examine the givers.sas7bdat data set */

/* Question 3 - create a list of records from givers with duplicate names */

title 'Duplicate Givers';
proc sql;
select 
employee_id
, employee_name
, qtr1
, qtr2
, qtr3
, qtr4
, recipients
from
sasdata.givers
where employee_name in 
                    (
                    select
                    employee_name
                    from
                    (
                    select 
                    employee_name
                    , count(employee_id) as num_recs
                    from
                    sasdata.givers
                    group by 
                    employee_name
                    having
                    num_recs > 1
                    ) )
order by 
employee_name
, employee_id desc
;

/* 
Question 4 - create a list of Active Employees who are not in the Giver list
Use a subquery in the where cluase to determine which IDs to eliminate
*/

title 'Active Employees not on Giver List';
proc sql;
select
employee_id
, employee_name
from
orion.employee_addresses
where employee_id not in (select distinct employee_id from sasdata.givers)
and employee_id in (select distinct employee_id from orion.employee_payroll where employee_term_date = .)
order by 
employee_name
;
quit;

/*
Question 5 - use data in one or more of the tables above to create a list of people from the givers table
who are no longer active employees at Orion Star
*/
title 'Terminated Givers';
proc sql;
select
giv.employee_id as ID
, giv.employee_name as Name
, pay.employee_gender as Gender

from
sasdata.givers giv

inner join
orion.employee_payroll pay
on giv.employee_id = pay.employee_id

where pay.employee_term_date ^= .

order by
giv.employee_name
;


/*
Question 6 - Create a report using a multiway-join
List customers who purchased products from product_groups that are not designated as being shoes
Sort the list by country, birth month, customer name, product group
*/

title "Orion's Customers Who Bought Products Other Than Shoes" ;
proc sql;
select
distinct
cust.customer_id as ID label='ID'
, cust.customer_name as Name label='Name'
, cust.customer_address as Address label='Address'
, cust.country label='Customer Country'
, prods.product_group label='Product Group'
, month(cust.birth_date) as birth_month label='Birth Month'

from
orion.customer cust

inner join
orion.order_fact fct
on fct.customer_id = cust.customer_id

inner join
orion.product_dim prods
on prods.product_id = fct.product_id

where lowcase(prods.product_group) not like  '%shoe%' 

order by
cust.country
, month(cust.birth_date)
, cust.customer_name
, prods.product_group

;
quit;




/* Question 7 - Housekeeping and PDF close*/

ods pdf close;
title;
