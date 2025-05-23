*** Assignment code *****

**************************************
* Part 1 - Replication
**************************************

use hansen_dwi, clear

/*Install necessary packages
ssc install gtools
net install binscatter2, from("https://raw.githubusercontent.com/mdroste/stata-binscatter2/master/")
ssc install rddensity
net install lpdensity, from("https://raw.githubusercontent.com/nppackages/lpdensity/master/stata/") replace
*/
********************************************************
* Q1: Create variables for DUI and quadratic term for BAC1
********************************************************

gen bac_min=bac1
replace bac_min=bac2 if bac2<bac1

gen bac_min_cent=bac_min-0.08

gen dui_min=0
replace dui_min=1 if bac_min>=0.08 & bac_min ~= .

gen dui=0
replace dui = 1 if bac1 >= 0.08 & bac1 ~= .

gen bac_cent=bac1-0.08

gen bac1_sq=bac1^2
gen bac_cent_sq = bac_cent^2
gen bac_min_cent_sq= bac_min_cent

/// 1.2.1. Non-Random Heaping / Manipulation

//// Figure 1 - BAC1 Distribution – Discrete and Continuous Histograms, Full and Bandwidth Range
/// Full distribution
* Produce discrete histogram for BAC1 - 
histogram bac1, discrete width(0.001) ytitle(Density) xtitle(Blood Alcohol Content) normal ///
xline(0.08) title("Discrete Histogram of BAC1 - Full Distribution") ///
subtitle("Density of Stops for DUI Across BAC") note("Discrete BAC levels") color(%50) lcolor(grey)

* Produce continuous histogram for BAC1
histogram bac1, width(0.001) ytitle(Density) xtitle(Blood Alcohol Content) normal ///
xline(0.08) title("Continuous Histogram of BAC1 - Full Distribution") subtitle("Density of Stops for DUI Across BAC") note("Continuous BAC levels") color(%50) lcolor(grey)

/// Bandwidth 0.03 to 0.13
* Produce discrete histogram
histogram bac1 if bac1 >= 0.03 & bac1 <= 0.13, discrete width(0.001) ytitle(Density) xtitle(Blood Alcohol Content) normal ///
xline(0.08) title("Discrete Histogram of BAC1 - 0.03 to 0.13") ///
subtitle("Density of Stops for DUI Across BAC") note("Discrete BAC levels") color(%50) lcolor(grey)
* Produce continuous histogram
histogram bac1 if bac1 >= 0.03 & bac1 <= 0.13, width(0.001) ytitle(Density) xtitle(Blood Alcohol Content) normal ///
xline(0.08) title("Continuous Histogram of BAC1 - 0.03 to 0.13") subtitle("Density of Stops for DUI Across BAC") note("Continuous BAC levels") color(%50) lcolor(grey)

//// Figure 2 - McCrary Manipulation Test Around BAC Threshold
* McCrary test
rddensity bac1, c(0.08) plot

/// 1.2.2. Discontinuity in Covariates

reg white dui##c.bac_cent if bac1 >= 0.03 & bac1 <= 0.13
eststo cov1 
reg male dui##c.bac_cent if bac1 >= 0.03 & bac1 <= 0.13
eststo cov2
reg aged dui##c.bac_cent if bac1 >= 0.03 & bac1 <= 0.13
eststo cov3
reg acc dui##c.bac_cent if bac1 >= 0.03 & bac1 <= 0.13
eststo cov4

/// Table 1 - Regression Discontinuity Estimates for Effect of Exceeding BAC Threshold on Covariates

esttab cov1 cov2 cov3 cov4

********************************************************
* Q2: Main recidivism results using original and modified bandwidths
********************************************************

/// 1.3 Replication of Main Results

* Original bandwidth linear
/// With controls
reg recidivism dui##c.bac_cent white male aged acc if bac1 >= 0.03 & bac1 <= 0.13, robust
eststo reg1

/// Without controls
reg recidivism dui##c.bac_cent if bac1 >= 0.03 & bac1 <= 0.13, robust
eststo reg1_noc

/// Figure 3 - Main Results: Discontinuity of Binned BACs by Average Recidivism Rate at Threshold
binscatter2 recidivism bac1 if bac1>=0.03 & bac1<=0.13, line(lfit) by(dui) nquantiles(449) title("Binned BACs by Average Recidivism Rate from 0.03 to 0.13") xtitle("Blood Alcohol Content") ytitle("Average Recidivism Rate") xline(0.08)

/// Table 2 – Regression Discontinuity Estimates for Effect of Exceeding BAC Threshold – Linear Model
esttab reg1 reg1_noc

* Original bandwidth quadratic term
/// With controls
reg recidivism dui##c.(bac_cent bac_cent_sq) white male aged acc if bac1 >= 0.03 & bac1 <= 0.13, robust
eststo reg2

/// Without controls
reg recidivism dui##c.(bac_cent bac_cent_sq) if bac1 >= 0.03 & bac1 <= 0.13, robust
eststo reg2_noc

esttab reg2 reg2_noc

/// 1.4.1 Quadratic BAC Interaction

/// Table 3 - Regression Discontinuity Estimates for the Effect of Exceeding BAC the 0.08 BAC Threshold – Including Quadratic Term

esttab reg1 reg2 reg1_noc reg2_noc

/// 1.4.2 Alternative Bandwidth

* Original bandwidth linear
/// With controls
reg recidivism dui##c.bac_cent white male aged acc if bac1 >= 0.05 & bac1 <= 0.11, robust
eststo reg3

/// Without controls
reg recidivism dui##c.bac_cent if bac1 >= 0.05 & bac1 <= 0.11, robust
eststo reg3_noc

/// Table 4 - Regression Discontinuity Estimates for Effect of Exceeding BAC Threshold – Original and Adjusted Bandwidth

esttab reg1 reg1_noc reg3 reg3 reg3_noc

********************************************************
* Q3: Donut hole regressions
********************************************************

gen donut = 0
replace donut = 1 if bac1 >= 0.079 & bac1 <= 0.081

/// 1.4.3 Donut Hole

* Donut hole regression original bandwidth
/// With controls
reg recidivism dui##c.bac_cent white male aged acc if bac1 >= 0.03 & bac1 <= 0.13 & donut == 0, robust
eststo reg4

/// Without controls
reg recidivism dui##c.bac_cent if bac1 >= 0.03 & bac1 <= 0.13 & donut == 0, robust
eststo reg4_noc

/// Table 5 - Regression Discontinuity Estimates for Effect of Exceeding BAC Threshold with and without Donut Between BAC1 0.079 and 0.081

esttab reg1 reg4 reg1_noc reg4_noc

********************************************************
* Q4: Local polynomial regressions and plots
********************************************************

/// 1.4.4 Local Polynomials

/// Uniform kernenl
* With donut
rdrobust recidivism bac_cent if donut == 0, kernel(uniform) masspoints(off) p(2) c(0)
eststo polu2
rdrobust recidivism bac_cent if donut == 0, kernel(uniform) masspoints(off) p(3) c(0)
eststo polu3

*Without donut
rdrobust recidivism bac_cent, kernel(uniform) masspoints(off) p(2) c(0)
eststo polu2_nod
rdrobust recidivism bac_cent, kernel(uniform) masspoints(off) p(3) c(0)
eststo polu3_nod

/// Triangular kernel
*With donut
rdrobust recidivism bac_cent if donut == 0, kernel(triangular) masspoints(off) p(2) c(0)
eststo polt2
rdrobust recidivism bac_cent if donut == 0, kernel(triangular) masspoints(off) p(3) c(0)
eststo polt3

*Without donut
rdrobust recidivism bac_cent, kernel(triangular) masspoints(off) p(2) c(0)
eststo polt2_nod
rdrobust recidivism bac_cent, kernel(triangular) masspoints(off) p(3) c(0)
eststo polt3_nod

/// Epanechnikov kernel
* With donut
rdrobust recidivism bac_cent if donut == 0, kernel(epanechnikov) masspoints(off) p(2) c(0)
eststo pole2
rdrobust recidivism bac_cent if donut == 0, kernel(epanechnikov) masspoints(off) p(3) c(0)
eststo pole3

*Without donut
rdrobust recidivism bac_cent, kernel(epanechnikov) masspoints(off) p(2) c(0)
eststo pole2_nod
rdrobust recidivism bac_cent, kernel(epanechnikov) masspoints(off) p(3) c(0)
eststo pole3_nod 

/// Figure 4 - Linear and Quadratic RD Plots and Cmograms – 0.06 to 0.11 BAC Bandwidth

rdplot recidivism bac1 if bac1 >= 0.06 & bac1 <= 0.11, p(1) masspoints(off) c(0.08) nbins(449) ///
graph_options(title("Linear RD Plot: Recidivism and BAC") ytitle("Average Recidivism Rate") xtitle("Blood Alcohol Content"))

rdplot recidivism bac1 if bac1 >= 0.06 & bac1 <= 0.11, p(2) masspoints(off) c(0.08) nbins(449) ///
graph_options(title("Quadratic RD Plot: Recidivism and BAC") ytitle("Average Recidivism Rate") xtitle("Blood Alcohol Content"))

cmogram recidivism bac1 if bac1 > 0.06 & bac1 < 0.11, cut(0.08) scatter line(0.08) lfitci histopts(bin(449)) ///
title("Linear Cmogram: Recidivism and BAC") 

cmogram recidivism bac1 if bac1 > 0.06 & bac1 < 0.11, cut(0.08) scatter line(0.08) histopts(bin(449)) qfitci ///
title("Quadratic Cmogram: Recidivism and BAC")

/// Table 6 - Regression Discontinuity Estimates for Effect of Exceeding BAC Threshold Using Quadratic and Cubic Local Polynomial Regressions – With and Without Donuts

esttab polu2_nod polu2 pole2_nod pole2 polt2_nod polt2

esttab polu3_nod polu3 pole3_nod pole3 polt3_nod polt3

********************************************************
* Q5: Heterogeneous Treatment Effects
********************************************************

/// 1.4.5 Heterogeneous Treatment Effects

* Gender HTE
/// With controls
reg recidivism dui##c.bac_cent##male white aged acc if bac1 >= 0.03 & bac1 <= 0.13, robust
eststo hte_g

/// Without controls
reg recidivism dui##c.bac_cent##male if bac1 >= 0.03 & bac1 <= 0.13, robust
eststo hte_g_noc

// Looks like DUI has a lower affect for women, but there are fewer women in the total sample. Could this implicate a bias for who is being tested? Are men more likely to be tested or are men more likely to drink and drive? Are women less likely to reoffend anyway?

* Race HTE
/// With controls
reg recidivism dui##c.bac_cent##white male aged acc if bac1 >= 0.03 & bac1 <= 0.13, robust
eststo hte_r

/// Without controls
reg recidivism dui##c.bac_cent##white if bac1 >= 0.03 & bac1 <= 0.13, robust
eststo hte_r_no_c

* Age HTE

gen age40=0
replace age40=1 if aged<=40

/// With controls
reg recidivism dui##c.bac_cent##age40 male white acc if bac1 >= 0.03 & bac1 <= 0.13, robust
eststo hte_a

/// Without controls
reg recidivism dui##c.bac_cent##age40 if bac1 >= 0.03 & bac1 <= 0.13, robust
eststo hte_a_noc

/// Table 7 - Heterogenous Treatment Effects in Regression Discontinuity Estimates for the Effect of Exceeding BAC the 0.08 BAC Threshold by Subgroup

esttab hte_g hte_g_noc hte_r hte_r_no_c hte_a hte_a_noc

**************************************
* Part 5 - Appendix
**************************************

/// Table A1 - Regression Discontinuity Estimates for Effect of Exceeding BAC Threshold on Covariates – Reduced Bandwidth

reg white dui##c.bac_cent if bac1 >= 0.05 & bac1 <= 0.11
eststo cov5
reg male dui##c.bac_cent if bac1 >= 0.05 & bac1 <= 0.11
eststo cov6
reg aged dui##c.bac_cent if bac1 >= 0.05 & bac1 <= 0.11
eststo cov7
reg acc dui##c.bac_cent if bac1 >= 0.05 & bac1 <= 0.11
eststo cov8

esttab cov5 cov6 cov7 cov8

/// Figure A1 - Main Results: Discontinuity of Binned BACs by Average Recidivism Rate at Threshold (Quadratic Fitted Line)

binscatter2 recidivism bac1 if bac1>=0.03 & bac1<=0.13, line(qfit) by(dui) nquantiles(449) title("Binned BACs by Average Recidivism Rate from 0.03 to 0.13") xtitle("Blood Alcohol Content") ytitle("Average Recidivism Rate") xline(0.08)


/// Table A2 - Regression Discontinuity Estimates for the Effect of Exceeding BAC Threshold – Optimally Determined Bandwidth by Kernel

/// One side
// To determine optimal bandwidth
rdbwselect recidivism bac1, kernel(uniform) p(1) c(0.08)
/// Suggests 0.02 on either side - 0.06 to 0.1
reg recidivism dui##c.bac_cent white male aged acc if bac1 >= 0.06 & bac1 <= 0.1, robust
eststo regA1_u

rdbwselect recidivism bac1, kernel(epanechnikov) p(1) c(0.08)
/// Suggests 0.029 on either side - 0.051 to 0.109
reg recidivism dui##c.bac_cent white male aged acc if bac1 >= 0.051 & bac1 <= 0.109, robust
eststo regA1_e

rdbwselect recidivism bac1, kernel(triangular) p(1) c(0.08) bwselect(mserd)
/// Suggests 0.031 on either side - 
reg recidivism dui##c.bac_cent white male aged acc if bac1 >= 0.049 & bac1 <= 0.11, robust
eststo regA1_t

esttab regA1_t regA1_u regA1_e


/// Two side
rdbwselect recidivism bac1, kernel(uniform) p(1) c(0.08) bwselect(msetwo)
reg recidivism dui##c.bac_cent white male aged acc if bac1 >= 0.06 & bac1 <= 0.122, robust
eststo regA2_u

rdbwselect recidivism bac1, kernel(epanechnikov) p(1) c(0.08) bwselect(msetwo)
reg recidivism dui##c.bac_cent white male aged acc if bac1 >= 0.05 & bac1 <= 0.13, robust
eststo regA2_e

rdbwselect recidivism bac1, kernel(triangular) p(1) c(0.08) bwselect(msetwo)
reg recidivism dui##c.bac_cent white male aged acc if bac1 >= 0.047 & bac1 <= 0.134, robust
eststo regA2_t

esttab regA2_t regA2_u regA2_e


/// Table A3 - Regression Discontinuity Estimates for Effect of Exceeding BAC Threshold – Including Quadratic Term – 0.05 to 0.11 Bandwidth

* With updated bandwidth - including quadratic term

/// With controls
reg recidivism dui##c.(bac_cent bac_cent_sq) white male aged acc if bac1 >= 0.05 & bac1 <= 0.11, robust
eststo regA2

/// Without controls
reg recidivism dui##c.(bac_cent bac_cent_sq) if bac1 >= 0.05 & bac1 <= 0.11, robust
eststo regA2_noc

esttab reg3 regA2 reg3_noc regA2_noc


/// Table A4 - Regression Discontinuity Estimates for Effect of Exceeding BAC Threshold with and without Donut Between BAC1 0.079 and 0.081 – Alternative Bandwidth

/// With controls
reg recidivism dui##c.bac_cent white male aged acc if bac1 >= 0.05 & bac1 <= 0.11 & donut == 0, robust
eststo regA3

/// Without controls
reg recidivism dui##c.bac_cent if bac1 >= 0.05 & bac1 <= 0.11 & donut == 0, robust
eststo regA3_noc

esttab regA2 regA3 regA2_noc regA3_noc

// Figure A2 - Cubic and Quartic RD Plots of Binned BAC1 by Average Recidivism Rate

rdplot recidivism bac1 if bac1 >= 0.06 & bac1 <= 0.11, p(3) masspoints(off) c(0.08) nbins(449) ///
graph_options(title("Cubic RD Plot: Recidivism and BAC") ytitle("Average Recidivism Rate") xtitle("Blood Alcohol Content"))

rdplot recidivism bac1 if bac1 >= 0.06 & bac1 <= 0.11, p(4) masspoints(off) c(0.08) nbins(449) ///
graph_options(title("Quartic RD Plot: Recidivism and BAC") ytitle("Average Recidivism Rate") xtitle("Blood Alcohol Content"))


// Figure A3 - 

/// Triangular kernel
rdplot recidivism bac1 if bac1 >= 0.06 & bac1 <= 0.11, p(1) masspoints(off) c(0.08) nbins(449) ///
graph_options(title("Linear RD Plot: Recidivism and BAC - Triangular Kernel")ytitle("Average Recidivism Rate") xtitle("Blood Alcohol Content")) kernel(triangular)

rdplot recidivism bac1 if bac1 >= 0.06 & bac1 <= 0.11, p(2) masspoints(off) c(0.08) nbins(449) ///
graph_options(title("Quadratic RD Plot: Recidivism and BAC - Triangular Kernel")ytitle("Average Recidivism Rate") xtitle("Blood Alcohol Content")) kernel(triangular)

/// Epanechnikov kernel
rdplot recidivism bac1 if bac1 >= 0.06 & bac1 <= 0.11, p(1) masspoints(off) c(0.08) nbins(449) ///
graph_options(title("Linear RD Plot: Recidivism and BAC - Epanechnikov Kernel")ytitle("Average Recidivism Rate") xtitle("Blood Alcohol Content")) kernel(epanechnikov)

rdplot recidivism bac1 if bac1 >= 0.06 & bac1 <= 0.11, p(2) masspoints(off) c(0.08) nbins(449) ///
graph_options(title("Quadratic RD Plot: Recidivism and BAC - Epanechnikov Kernel")ytitle("Average Recidivism Rate") xtitle("Blood Alcohol Content")) kernel(epanechnikov)


/// Subgroup analysis

* Gender
// With controls
reg recidivism dui##c.bac_cent white aged acc if bac1 >= 0.03 & bac1 <= 0.13 & male==1, robust
eststo reghte_g1
reg recidivism dui##c.bac_cent white aged acc if bac1 >= 0.03 & bac1 <= 0.13 & male==0, robust
eststo reghte_g0

// Without controls
reg recidivism dui##c.bac_cent if bac1 >= 0.03 & bac1 <= 0.13 & male==1, robust
eststo reghte_g1_noc
reg recidivism dui##c.bac_cent if bac1 >= 0.03 & bac1 <= 0.13 & male==0, robust
eststo reghte_g0_noc

/// Figure A5 - Regression Discontinuity Estimates for the Effect of Exceeding BAC Threshold – Linear Model, Gender Subgroups
esttab reghte_g1 reghte_g0 reghte_g1_noc reghte_g0_noc


* Race
// With controls
reg recidivism dui##c.bac_cent male aged acc if bac1 >= 0.03 & bac1 <= 0.13 & white==1, robust
eststo reghte_r1
reg recidivism dui##c.bac_cent male aged acc if bac1 >= 0.03 & bac1 <= 0.13 & white==0, robust
eststo reghte_r0

// Without controls
reg recidivism dui##c.bac_cent if bac1 >= 0.03 & bac1 <= 0.13 & white==1, robust
eststo reghte_r1_noc
reg recidivism dui##c.bac_cent if bac1 >= 0.03 & bac1 <= 0.13 & white==0, robust
eststo reghte_r0_noc

/// Figure A6 - Regression Discontinuity Estimates for the Effect of Exceeding BAC Threshold – Linear Model, Race Subgroups
esttab reghte_r1 reghte_r0 reghte_r1_noc reghte_r0_noc

* Age
// With controls
reg recidivism dui##c.bac_cent white male acc if bac1 >= 0.03 & bac1 <= 0.13 & age40==1, robust
eststo reghte_a1
reg recidivism dui##c.bac_cent white male acc if bac1 >= 0.03 & bac1 <= 0.13 & age40==0, robust
eststo reghte_a0

// Without controls
reg recidivism dui##c.bac_cent white male acc if bac1 >= 0.03 & bac1 <= 0.13 & age40==1, robust
eststo reghte_a1_noc
reg recidivism dui##c.bac_cent white male acc if bac1 >= 0.03 & bac1 <= 0.13 & age40==0, robust
eststo reghte_a0_noc

/// Figure A7 - Regression Discontinuity Estimates for the Effect of Exceeding BAC Threshold – Linear Model, Age Subgroups
esttab reghte_a1 reghte_a0 reghte_a1_noc reghte_a0_noc

