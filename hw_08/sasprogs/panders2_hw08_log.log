
/************************************************************************
 * Last Run Date: 12 March 2017	            							*
 * Program Name: panders2_hw08_prog.sas									*
 * Program Location: C:/Users/Philip/Schools/TAMU/STAT_657/				*
 *				SASUniversityEdition/myfolders/homework/git_hw/hw_08/sasprogs/	* 
 * Creation Date: 07 March 2017											*
 * Author: Philip Anderson												*
 * Purpose: Meeting objectives for Assignment 08						*
 * Inputs: orion folder         *
 * Output: panders2_hw08_output.pdf															*
 * Modification History: *
 * Execution Instructions: N/A - run as-is												*
*/**********************************************************************;



/* Define the libname for the permanent output for this assignment */
libname sasdata '/folders/myfolders/homework/git_hw/hw_08/sasdata';
filename pdf_out '/folders/myfolders/homework/git_hw/hw_08/output/panders2_hw08_output.pdf';
options nodate nonumber;

/* Question 1 - Create a permanent view */

ods pdf file=pdf_out;

proc sql;
create view sasdata.femdonors as 
select 
pay.employee_id label='ID'
, add.employee_name label='Name' 
, pay.salary format=dollar10.
, don.qtr1
, don.qtr2
, don.qtr3
, don.qtr4
, sum(don.qtr1, don.qtr2, don.qtr3, don.qtr4) as total_don label='Ann. Donation'

from
orion.employee_payroll pay

inner join
orion.employee_addresses add
on add.employee_id = pay.employee_id

left join
orion.employee_donations don
on pay.employee_id = don.employee_id

where pay.employee_gender = 'F' 
and pay.employee_hire_date between mdy(01,01,2006) and mdy(12,31,2006)
and pay.employee_term_date is null

order by 
pay.employee_id

using libname orion '/folders/myfolders/orion_dat/sasdata' access=readonly
;
quit;

/* 
Question 2 - use the CONTENTS procedure to display the contents of your permanent library
without showing the descriptor portion of each data set 
*/
proc contents data=sasdata._all_ nods; run;

/* Question 3 - run a second CONTENTS procedure to show the descriptor portion of the view created above */
proc contents data=sasdata.femdonors ; run;

/* Question 4 - use a SQL statement that writes the definition of the view to the SAS log*/

proc sql;
    describe view sasdata.femdonors;
quit;

/* 
Question 5 - use a SQL statement to access the view and print all of the data
returned by the view. 
*/

title 'Donations by Active Female Employees Hired in 2006';
footnote 'Output from SQL';
proc sql;
    select * from sasdata.femdonors;
quit;

/* 
Question 6 - use a proc print statement to access the view and print all of the data
returned by the view. 
*/

title 'Donations by Active Female Employees Hired in 2006';
footnote 'Output from Proc Print';
proc print data = sasdata.femdonors; run;

/* Housekeeping */
title;
footnote;
ods pdf close;
