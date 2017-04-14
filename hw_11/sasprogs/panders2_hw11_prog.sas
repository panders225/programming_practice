/************************************************************************
 * Last Run Date: 14 April 2017	            							*
 * Program Name: panders2_hw11_prog.sas									*
 * Program Location: C:/Users/Philip/Schools/TAMU/STAT_657/				*
 *				SASUniversityEdition/myfolders/homework/git_hw/hw_11/sasprogs/	* 
 * Creation Date: 11 April 2017											*
 * Author: Philip Anderson												*
 * Purpose: Meeting objectives for Assignment 11						*
 * Inputs: orion folder         *
 * Output: panders2_hw11_output.pdf															*
 * Modification History: *
 * Execution Instructions: N/A - run as-is												*
*/**********************************************************************;


/*Question 1 - use all three system options that will cause macro resolution
, macro code, and macro execution info to be written to the log*/

options symbolgen mprint mlogic;

ods pdf file='/folders/myfolders/homework/git_hw/hw_11/output/panders2_hw11_output.pdf';

/* Question 2 - Copy the donations macro code created in step 4 of assignment 9 and paste it in */

/* Question 3 - change the macro definition so that the start date and end date are positional parameters */
/* make library and gender keyword parameters, with default values of work and Female, respectively */
%macro donations(startdt, enddt, outlib=work, gender=Female); 
** Convert the status to proper case; 
%let gender=%sysfunc(propcase(&gender)); 

proc sql;    
create table &outlib..&gender%substr(&startdt,6) as    
select 
c.employee_id 'ID'
, employee_name 'Name'
, salary format=dollar8.
, qtr1
, qtr2
, qtr3
, qtr4
, sum(qtr1, qtr2, qtr3, qtr4) as tot_donation 'Ann. Donation'    
from 
(select 
a.employee_id
, employee_name
, salary 
from 
orion.employee_payroll a
, orion.employee_addresses b        
where a.employee_id=b.employee_id 
and employee_term_date is missing 
/* Question 4 - add macro logic to your macro so that if the end date parameter is null, the macro will ignore the end_date 
and return employees hired on or after the start date
*/
%if &enddt.= %then %do;
and (employee_hire_date >= "&startdt"d)
%end;

%else %do;
and (employee_hire_date between "&startdt"d and "&enddt"d) 
%end;

and employee_gender = "%substr(&gender,1,1)") as c    
left join    
orion.employee_donations as d    
on c.employee_id=d.employee_id
;

/* Question 5 - use macro logic to display the appropriate title depending on whether there is an end date */
%if &enddt.= %then %do;
    title "Donations of &gender Employees Hired on or after &startdt.";
%end;
%else %do;
    title "Donations of &gender Employees Hired between &startdt and &enddt"; footnote "&syslast";    
%end;

select 
*    
from &outlib..&gender%substr(&startdt,6);    
/* It would be acceptable to use &syslast on the from statement above. */ 
quit;
/* Housekeeping */ title;
footnote;
%mend donations;

/* Question 6 - Call your new donations macro specifying only January 1, 2004 as the start date */
libname orion '/folders/myfolders/orion_dat/sasdata/' access=readonly;

%donations(01Jan2004);

/* Question 7 - call the macro again specifying parameters to produce a report for Male Employees 
hired between Jan 1 2000 and Dec 31 2006*/

%donations(01Jan2000, 31Dec2006, gender=Male);

/* Question 8 - use PROC SQL to create a table with columns seed, school, region, player, ppg, 
and rpg from ncaam06 with only schools that have 5 or more players listed in the dataset   */

libname bball '/folders/myfolders/homework/git_hw/hw_04/sasdata' access=readonly;

proc sql;
create table basketball as
select 
baser.seed
, baser.school
, baser.region
, baser.player
, baser.ppg
, baser.rpg
from 
bball.ncaam06 baser

inner join
(
select 
school
, count(distinct player) as tot_players
from
bball.ncaam06
group by 
school
having calculated tot_players >= 5
) sq
on sq.school = baser.school
;
quit;



/* Question 9 - create a data-driven macro definition that will produce a separate report for each region in the data */

/* 9A - create a data set with an unduplicated list of regions */
proc sort data=basketball (keep=region) out=dedup_region nodupkey;
by region;
run;

/* 9B - use a data step to create macro variables for each region and the total number of regions*/
data _null_;
    set dedup_region end=file_end;
    call symputx(compress('region_'||_n_) , region);
    if file_end then do;
        call symputx('dist_regions', _n_);
    end;
run;

/* 9C - replace the data set name and WDC in the original proc report with macros and use a loop
to iteratively process the report procedure for each of the regions in the data*/

%macro looper(dset);
    %do i = 1 %to %eval(&dist_regions.);
    
            proc report data=&dset. nowd;
            where region = "&&region_&i";
            columns ("Region = &&region_&i" seed school ppg rpg);
            define seed / group 'Seed';
            define school / group 'Team';
            define ppg /mean format=8.1 'Average Points';
            define rpg /mean format=8.1 'Average Rebounds';
            run;        
    %end;
%mend;

%looper(basketball);



title;
footnote;
ods pdf close;