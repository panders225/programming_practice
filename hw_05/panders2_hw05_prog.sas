
/************************************************************************
 * Last Run Date: 12 Feb 2017	            							*
 * Program Name: panders2_hw05_prog.sas									*
 * Program Location: C:/Users/Philip/Schools/TAMU/STAT_657/				*
 *				SASUniversityEdition/myfolders/homework/git_hw/hw_05/sasprogs/	* 
 * Creation Date: 08 Feb 2017											*
 * Author: Philip Anderson												*
 * Purpose: Meeting objectives for Assignment 05						*
 * Inputs: scholarship03.sas7bdat         *
 * Output: panders2_hw05_output.pdf															*
 * Modification History:*
 * Execution Instructions: N/A - run as-is												*
*/**********************************************************************;


/* Question 1 - assign a readonly libref to the location of our data*/

libname sasdata '/folders/myfolders/homework/git_hw/hw_05/sasdata' access=readonly;

/* Assign an output location for our file */
filename one_out '/folders/myfolders/homework/git_hw/hw_05/output/panders2_hw05_output.pdf' ;

/* turn off page numbering for our output */
options nonumber;

/* Question 2 - Create a table using the SQL procedure */

proc sql;
/* Final table will be referred to as scoring03, stored in work space */
create table scoring03 as
select
player
, team
, region
, PPG
/* remerge a global summary statistic of mean ppg */
, mean(PPG) as Average_Points
from
sasdata.scholarship03
/* remove players with team seeds of 15 or 16 */
where Seed_ not in (15, 16)
;
quit;


/* Question 3 - Use a single proc sql step to create two reports */

/* part a. - use a single find function in your where clause to subset the data
 so the report includes only those students from teams with State or the abbreviation St in
 the team name.  If the St. is referring to 'Saint', as in 'St.' ,keep it in*/

ods pdf file=one_out style=minimal startpage=no;

proc sql;
title 'Average Scholarships for State Schools';
select
/* pull back only particular columns */
player 
, team
, tot_scholarship label='Total Scholarship' format=dollar10.
, max_scholarship 'Maximum Scholarship' format=dollar10.
, Scholarships
from

    (select 
    player
    , team
    , sum(amt1, amt2, amt3, amt4, amt5, amt6, amt7, amt8, amt9, amt10) as tot_scholarship
    , max(amt1, amt2, amt3, amt4, amt5, amt6, amt7, amt8, amt9, amt10) as max_scholarship
    , (10 - nmiss(amt1, amt2, amt3, amt4, amt5, amt6, amt7, amt8, amt9, amt10)) as Scholarships
    from
    sasdata.scholarship03
    /* use a single find function to pull back only 'state' schools*/
    where (find(team, "St", 3) > 0)
    group by 
    player
    , team)
    
/* eliminate players with only a single scholarship*/    
where Scholarships ^= 1
order by 
/* order the report by team, then by scholarship descending */
team
, tot_scholarship desc
;

/* Output options - input text in middle of pdf page - align it with the 
main title for that page and print two blank lines before it */
ods escapechar='^';
ods text='^{style [textalign=C] ^n ^n 2003 NCAA Team Scoring Analysis}' ;

/* Question 4*/

title '2003 NCAA Team Scoring Analysis';
select
/* keep only one record per school */
team
/* create some additional columns */
, count(distinct player) as Players
, round(avg(ppg), 0.1) as team_avg label='Average PPG'
, (calculated team_avg / tot_avg_ppg ) as t_v_o label='Team vs. Overall' format=percent8.1
/* Create a column that changes labels based on team's relative ppg */
, (case when calculated t_v_o > 1 then 'Above Avg.' else 'Avg. or Below' end) as ppg_lev
    label='PPG Level'
from
(
select
team
, player
, ppg
, (select avg(ppg) from scoring03) as tot_avg_ppg
from
scoring03
)
group by
team
having calculated Players >= 5
/* sort by PPG highest to lowest */
order by 
calculated team_avg desc
;
quit;

ods pdf close;




/* Question 5 - housekeeping */

/* clear the titles */
title;


