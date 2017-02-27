/************************************************************************
 * Last Run Date: 26 Feb 2017	            							*
 * Program Name: panders2_hw07_prog.sas									*
 * Program Location: C:/Users/Philip/Schools/TAMU/STAT_657/				*
 *				SASUniversityEdition/myfolders/homework/git_hw/hw_07/sasprogs/	* 
 * Creation Date: 26 Feb 2017											*
 * Author: Philip Anderson												*
 * Purpose: Meeting objectives for Assignment 07						*
 * Inputs: ncaam[03,04,06].sas7bdat         *
 * Output: panders2_hw07_output.pdf															*
 * Modification History: *
 * Execution Instructions: N/A - run as-is												*
*/**********************************************************************;


/* the libname you use to access the previous datasets must be set to readonly */
libname ncaa '/folders/myfolders/homework/git_hw/hw_04/sasdata' access=readonly;

filename pdf_out '/folders/myfolders/homework/git_hw/hw_07/output/panders2_hw07_output.pdf' ;


options nodate nonumber;
ods pdf file=pdf_out bookmarkgen=NO;
/*Question 1*/
/* 
Create a report that combines the 2003 and 2004 statistics of only those players who played in both the 2003
and 2004 NCAA championships.  Match the tables on both the player name and team
*/
title 'Players in Both 2003 and 2004 NCAA Championship Tournaments';
proc sql;
select 
*
from
(
select
'2003' as year label='Year'
, three.team
, three.seed_
, three.player
, three.ppg
from
ncaa.ncaam03 three

inner join
ncaa.ncaam04 four
on four.player = three.player
and four.team = three.team

/* use a set operator*/
UNION

select 
'2004' as year
, four.team
, four.seed_
, four.player
, four.ppg
from
ncaa.ncaam04 four

inner join
ncaa.ncaam03 three
on three.player = four.player
and three.team = four.team
)
order by 
player
, ppg desc
;
quit;

/* Question 2 - Create a report of teams that played in all three
of the tournaments for which data were provided.  Use the 
INTERSECT operator to determine which schools were in all three tournaments*/

options date;
title 'Comparison of Teams from 2003, 2004, and 2006 NCAA Championship Tournaments';
proc sql;

select
team
, seed_
, avg_ppg format 8.1
, year
from
(
select 
team
, seed_
, avg(ppg) as avg_ppg label='Average Player PPG'
, '2003' as year label='Year'
from
ncaa.ncaam03
where team in (select team from ncaa.ncaam03 INTERSECT select team from ncaa.ncaam04 INTERSECT select school as team from ncaa.ncaam06)
group by 
team
, seed_

UNION 

select 
team
, seed_
, avg(ppg) as avg_ppg
, '2004' as year
from
ncaa.ncaam04
where team in (select team from ncaa.ncaam03 INTERSECT select team from ncaa.ncaam04 INTERSECT select school as team from ncaa.ncaam06)
group by 
team
, seed_

UNION

select 
school as team
, seed as seed_
, avg(ppg) as avg_ppg
, '2006' as year
from
ncaa.ncaam06
where school in (select team from ncaa.ncaam03 INTERSECT select team from ncaa.ncaam04 INTERSECT select school as team from ncaa.ncaam06)
group by 
team
, seed_
)
order by 
team
, year
;
quit;

/*Cleanup*/
title;
ods pdf close;
