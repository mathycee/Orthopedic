data allhospital;
infile 'C:\Users\Kevin\Desktop\Xiaomeng\488 Statistical Consultation\Individual Presentation\allhospital.txt' dlm=',';
input ZIP $ HID $ CITY $ STATE $ BEDS RBEDS OUTV ADM 
      SIR SALESY SALES12 HIP95 KNEE95 TH TRAUMA REHAB HIP96 KNEE96 FEMUR96;
run;

data hospital;
set allhospital;


**Creat new response variable-SALES**;
SALES=log(1+SALESY+SALES12);
if SALES=0 then SALES=.;

	
**code for selecting states--Lake Michigan Region**;
IF STATE EQ 'IL' or STATE EQ 'IN' or STATE EQ 'MI' or STATE EQ 'WI';
ARRAY X [10] BEDS RBEDS HIP95 KNEE95 HIP96 KNEE96 FEMUR96 OUTV ADM SIR;

**transformation**;
do i=1 to 4; X[i]=SQRT(X[i]);end;
do i=5 to 7; X[i]=log(1+0.01*X[i]);end;
do i=8 to 10; X[i]=log(1+0.001*X[i]);end;

**Factor Analysis**;
PROC FACTOR data=hospital plots=scree METHOD=PRINCIPAL NFACT=1 out=fac1; 
VAR HIP95 KNEE95 HIP96 KNEE96 FEMUR96;
RUN;
PROC FACTOR data=hospital plots=scree METHOD=PRINCIPAL ROTATE=VARIMAX NFACT=2 out=fac2;
VAR BEDS RBEDS OUTV ADM SIR TH trauma rehab;          
RUN;
*VARIMAX--orthogonal rotation, uncorrelated components;

**PCA**;
PROC PRINCOMP data=hospital;
VAR HIP95 KNEE95 HIP96 KNEE96 FEMUR96;
RUN;
PROC PRINCOMP data=hospital;
VAR BEDS RBEDS OUTV ADM SIR TH trauma rehab;          
RUN;

DATA fac2; 
set fac2;
factor3 = factor1; 
keep factor2 factor3; 
RUN;
DATA newhospital; 
merge fac1 fac2; 
run;

**PCA plot**;
/*PROC GPLOT DATA=fac2;
 plot factor1*factor2=TRAUMA;
run;*/


**cluster anaysis using WARD**;
PROC CLUSTER data=newhospital METHOD=WARD OUTTREE=tree;
VAR factor1-factor3;
COPY ZIP CITY STATE HID BEDS RBEDS 
	HIP95 KNEE95 HIP96 KNEE96 FEMUR96 
	OUTV ADM SIR TH TRAUMA REHAB SALES factor1-factor3;
RUN;

/*PROC TREE data=tree;
run;*/

PROC TREE data=tree NOPRINT NCL=5 OUT=TXCLUST;
COPY ZIP CITY STATE HID BEDS RBEDS 
	HIP95 KNEE95 HIP96 KNEE96 FEMUR96 
	OUTV ADM SIR TH TRAUMA REHAB SALES factor1-factor3;
RUN;

**procuce the cluster summary and pick athe best cluster**;
PROC SORT data=TXCLUST;by cluster;run;
Proc means data=TXCLUST noprint;
by cluster;
var SALES factor1-factor3;
OUTPUT out=c mean=msales mf1-mf3;
run;
Proc boxplot data=TXCLUST; plot SALES*cluster;run;
/*proc sql;
	select cluster, count(distinct(HID))
	from TXCLUST
	group by CLUSTER;
quit;*/
DATA cl; set TXCLUST; IF cluster=5; run;
ods graphics on;
PROC REG DATA=cl;
MODEL sales=factor1-factor3/P R selection=b;
OUTPUT OUT=c P=PRED R=RESID STDP=STDP;
run;
ods graphics off;

**Estimate potential sales**;
data c;
set c;
rowp=exp(PRED+0.5*STDP*STDP)-1;
sales=exp(sales)-1;
gain=rowp-sales;
run;
proc sort; 
by gain;
proc print;
var HID CITY STATE SALES GAIN;
run;
















