/************************************************************************
 * Last Run Date: 30 April 2017	            							*
 * Program Name: panders2_hw12_prog.sas									*
 * Program Location: C:/Users/Philip/Schools/TAMU/STAT_657/				*
 *				SASUniversityEdition/myfolders/homework/git_hw/hw_13/sasprogs/	* 
 * Creation Date: 24 April 2017											*
 * Author: Philip Anderson												*
 * Purpose: Meeting objectives for Assignment 13						*
 * Inputs: basketball data         *
 * Output: panders2_hw13_output.pdf															*
 * Modification History: *
 * Execution Instructions: N/A - run as-is												*
*/**********************************************************************;
 
/*specify the option that will print information about the indexes */
options msglevel=i nonumber nodate;
libname bball '/folders/myfolders/homework/git_hw/hw_04/sasdata' access=readonly;
libname sasdata '/folders/myfolders/homework/git_hw/hw_13/sasdata';

ods pdf file='/folders/myfolders/homework/git_hw/hw_13/output/panders2_hw13_output.pdf' ;

/*Question 1 - recreate the output of p306d02 using SQL */
/*original SAS step is as follows: */
/* data country;
   keep Start Label FmtName;
   retain FmtName '$Country';
   set orion.Country(rename=(Country=Start
                              Country_Name = Label));
run;
 */

/*1a - convert the data step to sql*/ 
proc sql;
create table sql_conversion as
select 
distinct
/*1d - give the format a name of your choosing*/
'$seedz' as FmtName 
/*1b - use the team column to create the Start variable*/
, team as Start
/*1c - use seed_ as the label in your format; use a put function to conver the number to text */
, put(seed_, 2.) as Label
from
bball.ncaam04
;

/*1e - after you have created the datast, use SQL to insert a row at the end 
this row will have values of start=other, label=NA, along with format name*/
insert into sql_conversion  values ('$seedz', 'other', 'NA')
;
quit;

/*1f - use the format procedure to create a user-defined format in the work library*/
/*1g - use the format procedure to write the contents of the new format to your output doc*/
proc format library=work.myfmts cntlin=sql_conversion fmtlib;
    select $seedz;
run;


/* Question 2 - create a picture format that can be applied to the PPG column 
allow space for PPG to be displayed as two digits along with a single decimal place (00.0)*/


proc format;
    picture ppg_fmt
    15 - high = '(00.0)' (prefix='High(')
    7.7 -< 15 = '(00.0)' (prefix='Medium(')
    low -< 7.7 = '(00.0)' (prefix='Low(')
    ;
run;


/*Question 3 - use a SAS procedure to place a copy of the ncaam06 dataset in the WORK library */
proc datasets noprint;
copy in=bball out=work;
select ncaam06;
quit;

/* Question 4 - use SQL statements to make several modifications to the ncaam06 dataset */
options fmtsearch=(work work.myfmts);

proc sql;
create table ncaam06_update as
select 
ncaam06.*
/*4a+d - populate the ppg rating column with a put function*/
, put(ppg, ppg_fmt.) as ppgrate label='PPG Rating'
/*4b+f - populate the 2004 seeding column using the put function */
, put(school, $seedz.) as seed04 label='2004 Seeding'

/*4e - correct a number of school name mispellings*/
, (case
    when School = 'Indania' then 'Indiana'
    when School = 'Boston Coll' then 'Boston College'
    when School = 'George mason' then 'George Mason'
    when School = 'Oral Robt-16' then 'Oral Roberts'
    when School = 'Wisc. Milwaukee' then 'Wisconsin Milwaukee'
    else School end) as School_b
from
ncaam06
;


/* 4c - change the length of the school variable */
alter table ncaam06_update 
	modify School_b char(19)
	
	drop School
	;
quit;

data ncaam06_update;
set ncaam06_update;
rename School_b = School;
run;






/*Question 5 - create a composite index for ncaam06 using player, school, and region-  in that order */
data ncaam06_update 
    (index=(bball_idx=(player school region )));
set ncaam06_update;
run;

title 'Descriptor Portion of ncaam06';
proc contents data=ncaam06_update; run;

data ncaam06_update_b 
    (index=(bball_idx=(player school region )));
retain player school region seed ppgrate seed2004;
set ncaam06_update (keep=player school region seed ppgrate seed04);
run;


/*Question 6 - create a print procedure that will print the columns shown in the output */

/* the bball_idx index was used in this step because we called for it.  The note
in the log about forcing index usage rather than allowing the default sequential pass implies that 
the index was not the most efficient route to take */

title '6a. IDXWHERE on Player';
proc print data=ncaam06_update_b (idxwhere=yes) label;
where player in ('Steve Burtt', 'Jared Dudley', 'Stanley Burrell');
label school='School' ppgrate='PPG Rating' seed04='2004 Seeding';
format seed04 $seedz.;
run;

/*procedure fails because SAS is unable to determine which index to use for where-clause
optimization*/
title '6b. IDXWHERE on School';
proc print data=ncaam06_update_b (idxwhere=yes) label;
where school='Texas';
label school='School' ppgrate='PPG Rating' seed04='2004 Seeding';
run;

/*even if we specify the index that we would like SAS to use, it is unable to optimize the 
data retrieval using it*/
title '6c. IDXNAME on School';
proc print data=ncaam06_update_b (idxname=bball_idx) label;
where school='Texas';
label school='School' ppgrate='PPG Rating' seed04='2004 Seeding';
run;

/* No note about index usage implies that use of the index was the most 
efficient route.  The procedure should be using compound optimization */
title '6d. IDXWHERE on Player or School';
proc print data=ncaam06_update_b (idxwhere=yes) label;
where player in ('Steve Burtt', 'Jared Dudley', 'Stanley Burrell') or school='Indiana';
label school='School' ppgrate='PPG Rating' seed04='2004 Seeding';
run;

/*This procedure is not taking advantage of compound optimization, because of the 
substring operation on player */
title '6e. IDXWHERE on Player and School';
proc print data=ncaam06_update_b (idxwhere=yes) label;
where substr(player, 1, 1) = 'S' and school in ('Duke', 'Oral Roberts', 'Iona', 'Boston College', 'Gonzaga');
label school='School' ppgrate='PPG Rating' seed04='2004 Seeding';
run;

title;
footnote;
ods pdf close;