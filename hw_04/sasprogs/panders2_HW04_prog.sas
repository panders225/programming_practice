
/************************************************************************
 * Last Run Date: 05 Feb 2017	            							*
 * Program Name: panders2_hw04_prog.sas									*
 * Program Location: C:/Users/Philip/Schools/TAMU/STAT_657/				*
 *				SASUniversityEdition/myfolders/git_hw/homework/hw_04/sasprogs/	* 
 * Creation Date: 30 Jan 2017											*
 * Author: Philip Anderson												*
 * Purpose: Meeting objectives for Assignment 04						*
 * Inputs: ncaam03.sas7bdat, ncaam04.sas7bdat, ncaam06.sas7bdat         *
 * Output: panders2_hw04_output.pdf															*
 * Modification History:*
 * Execution Instructions: N/A - run as-is												*
*/**********************************************************************;

/* Question 1 - Assign a readonly libref to the location of the data for this assignment*/
libname sasdata '/folders/myfolders/homework/git_hw/hw_04/sasdata' access=readonly;

/* Assign a fileref for the pdf output of this assignment*/
filename out_dat '/folders/myfolders/homework/git_hw/hw_04/output/panders2_hw04_output.pdf' ;


/* Question 2 - open a pdf destination to capture the output from the following procedures */
/* Generate bookmarks, but not by default; choose a style that incorporates color */
ods pdf (ID=one) file = out_dat bookmarkgen=YES style=Festival;


/* Question 3 - Concatenate ncaam03 and ncaam04 */
/* Note - these data sets have different fields - will result in an append coercion*/

data ncaam_03_04;
    set sasdata.ncaam03
        sasdata.ncaam04
    ;
run;

/* Question 4 - Use SQL to print the data portion of the new data set - match the titles and footnotes in sample output*/

title1 "Top Teams from 2003 and 2004 Men's NCAA Tournaments";
title2 "Concatenated Data";

proc sql;
select 
*
from
ncaam_03_04
;
quit;


/* Question 5 - Interleave ncaam03 and ncaam04 based on player name and team */
/* Interleaving will require a prior sort */

proc sort data=sasdata.ncaam03 out=ncaam03;
    by player team;

proc sort data=sasdata.ncaam04 out=ncaam04;
    by player team;

data ncaam_interleave ; 
    /* eliminate any variable that does not appear in both data sets */
     set ncaam03 (drop=region)
        ncaam04 (drop=f3)
    ;
    by player team;
run;
     

/* Question 6 - use the print procedure and a data set option to print the first 30 records of interleaved data set */

data inter;
    set ncaam_interleave (obs=30);

/* Update the report title*/
title2 'First 30 Records of Interleaved Data';

proc print data=inter;
run;

/* Question 7*/
/* Use the match-merge process to create a data set of only those who played in both the 2003 and 2004 tournaments */
/* Our data sets will already be sorted by player and team from a previous module*/

data ncaam_mm;
    merge ncaam03 (in=a drop=region)
          ncaam04 (in=b drop=f3)
    ; 
    by player team;
    if a and b;
run;



/* Question 8 - use SQL to print player, team, and PPG from the merged data
    The SQL statement should sort the list by descending PPG*/
    
title1 'Players Who Played in Both 2003 and 2004 Tournaments';    
title2 'NOTE: PPG is from 2004';
footnote1 ' PPG is from year 2004 because I specified the 2004 data set second in the above match-merge';
footnote2 'The second data set field names overwrite those of the first if identically named';
proc sql;
select 
player
, team
, ppg
from
ncaam_mm
order by 
ppg descending
;
quit;

/* Question 9 - Match merge ncaam03, ncaam04, and ncaam06 into a single data set */
/* Use data set options as needed so that the resulting data set has the variables
    player, team, ppg2003 ppg2004, ppg2006*/
/* use a length statement to set the length of the player variable to match the longest size of the player 
  variable from the three data sets*/

proc sort data=sasdata.ncaam03 (keep=player team ppg) out=ncaam03 (rename=(ppg=ppg_2003));
    by player team;

proc sort data=sasdata.ncaam04 (keep= player team ppg) out=ncaam04 (rename=(ppg=ppg_2004));
    by player team;

proc sort data=sasdata.ncaam06 (keep= player school ppg) out=ncaam06 (rename=(school=team ppg=ppg_2006));
    by player school;

data ncaam_tot; 
/* Use a length statement to match the length of the longest player name from the incoming sets*/
    length player $23.;
    set ncaam03
        ncaam04
        ncaam06
    ;
    by player team;
run;

/* Question 10 - Create a SQL procedure with multiple statements*/

footnote; /* Drop the previous footnotes*/
title 'Three-year NCAA Tournament Statistics'; /*Bring in a new title*/

proc sql feedback;
/* Statement 1 must write a list of all columns to the log all of the columns and their attributes of the previous data step */
validate
select
*
from
ncaam_tot
;

/* statement 2 will print the data portion of that set in the order shown */
select 
player
, team 
, ppg_2003 label = "2003 PPG"
, ppg_2004 label = "2004 PPG"
, ppg_2006 label = "2006 PPG"
from
ncaam_tot
;
quit;

/* Question 11 - use a single proc step to print the descriptor portion of all of the data sets in your work library */

title 'Descriptor Portion of Data Sets in the Work Library';
proc contents data=work._all_;
run;


/* Question 12 - End the program with the appropriate housekeeping steps to ensure titles and footnotes do not carry over to the next
   program that is executed */

title;
footnote;

/*close the output destination*/
ods pdf close;
