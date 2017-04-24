/************************************************************************
 * Last Run Date: 23 April 2017	            							*
 * Program Name: panders2_hw12_prog.sas									*
 * Program Location: C:/Users/Philip/Schools/TAMU/STAT_657/				*
 *				SASUniversityEdition/myfolders/homework/git_hw/hw_12/sasprogs/	* 
 * Creation Date: 17 April 2017											*
 * Author: Philip Anderson												*
 * Purpose: Meeting objectives for Assignment 12						*
 * Inputs: orion folder         *
 * Output: panders2_hw12_output.pdf															*
 * Modification History: *
 * Execution Instructions: N/A - run as-is												*
*/**********************************************************************;

/* set the macro options, set the ncaam06 libname */
options symbolgen mprint mlogic nonumber;
libname bball '/folders/myfolders/homework/git_hw/hw_04/sasdata' access=readonly;
ods pdf file='/folders/myfolders/homework/git_hw/hw_12/output/panders2_hw12_output.pdf';


/* Question 1 - use proc sql to create a table with selected columns consisting only of 
schools that have 5 or more players in the dataset*/

proc sql;
create table completes as
select
seed
, school
, region
, player
, ppg
, rpg
from
bball.ncaam06
group by 
school
having count(school) >= 5
;
quit;


/* Question 2 - Overhaul the data-driven macro that will produce the region-level reports as the previous assignment, 
but only using sql statements */

%macro looper(dset);
proc sql noprint;
/*2a - create a table with an unduplicated list of the regions*/
create table region_dedup as 
select 
distinct 
region
from
&dset.
order by 
region
;

/*2b - assign a macro containing the number of regions from the sqlobs macro value */
%global region_num;
%let region_num = &sqlobs.;

/*2c - create macro variables for each region */
%global region_num_1 region_num_2 region_num_3 region_num_4;
%let region_num_1 = ATL;
%let region_num_2 = MIN;
%let region_num_3 = OAK;
%let region_num_4 = WDC;
%put &region_num_1. &region_num_2. &region_num_3. &region_num_4.;

/*2d + 2e - recreate the report from the previous assignment with an SQL
statement - loop through the regions*/
reset print;

   %do i = 1 %to &region_num.;
        title "Team Statistics for the &&region_num_&i Region";

        select 
        seed 'Row'
        , school 'Team'
        , avg(ppg) as avg_points 'Average Points' format 8.1
        , avg(rpg) as avg_rebounds 'Average Rebounds' format 8.1
        from
        &dset.
        where region="&&region_num_&i"
        group by 
        seed
        , school
        ;

    %end;

quit;

%mend;

%looper(dset=completes);


/* Question 3 - use an SQL procedure to create a report of the top 20 players with the highest number of points from the ncaam06 dataset */
title 'Top 20 Scorers';
proc sql;
create table top_twenty as
select 
player 'Name'
, ppg 'Points'
, school 'Team'
, region 'Region'
, seed 'Seed'
from
bball.ncaam06
order by 
ppg descending
;

select
*
from
top_twenty
where monotonic() <= 20
;
quit;



/*Question 4 - create a macro to report on the rebounders from the ncaam06 dataset, 
subset by a selected region 
and greater than or equal to a selected minimum number of rebounds per game 
macro will have a positional parameter for the region and keyword param for number of rebounds, defaulting to 7
*/

%macro rebounder(reg_inp, rebound_num=7 );
/*Question 4a - use a macro function to transform the region parameter to all-caps*/
%global reg_inp_b;
%let reg_inp_b = %upcase(&reg_inp.);

/*Question 4b - use a data step to create in the work lib, a table that is the subset of ncaam06, 
based on the two macro parameters*/

data ncaam06_sub;
    set bball.ncaam06;
    where region = "&reg_inp_b."
    and rpg >= %eval(&rebound_num.)
    ;
run;

/* Question 4c - use an SQL statement to read the number of observations in your new table from 
the appropriate SASHELP view and place this in a macro variable */
%global sub_obs;
proc sql noprint;
select 
nobs into :sub_obs
from
sashelp.vtable
where libname = 'WORK'
and memname = 'NCAAM06_SUB'
;
quit;

/*Question 4d - Use macro logic to print a new line of text on a new page if there are no records found 
using the supplied parameters on the macro*/
    %if %eval(&sub_obs.) = 0 %then %do;
    	title "Players from the &reg_inp_b. Region Averaging &rebound_num. or More Rebounds Per Game";
    	ods startpage=NOW;
        ods text="No players from &reg_inp_b. average &rebound_num. or more rebound per game.";
    %end;

/*Question 4e - if records are found then use an SQL statement to produce the printed table*/
    %else %do;
       ods startpage=now;
       title "Players from the &reg_inp_b. Region Averaging &rebound_num. or More Rebounds Per Game";
       proc sql;
       select
       player 'Name'
       , rpg 'Rebounds' format = 8.1
       , school 'Team'
       , seed 'Seed'
       from
       ncaam06_sub
       order by 
       rpg desc
       ;
       quit;        
    %end;

%mend;

/* Question 4f - call the macro using wdc and 10 as the rebounding threshold */
%rebounder(wdc, rebound_num = 10);
/* Question 4g - call the macro again specifying only ATL as the region */
%rebounder(ATL);

/* Housekeeping */
title;
footnote;
ods pdf close;