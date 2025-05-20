#-----------------------------------FINAL ANALYSIS-----------------------------------#
library(readxl)
#install.packages("devtools")
#devtools::install_github("cardiomoon/ggiraphExtra")
library(car)
library(readxl)
library(openxlsx)
library(writexl)
library(ggplot2)
library(dplyr)
library(ggpubr)


# reading in my data set 
allData_p100_wAttdTrials <- read_xlsx("Desktop/INSAR/allData_p100_wAttdTrials.xlsx")
df <- allData_p100_wAttdTrials

### CASI ADHD SYMPTOMS AND P100 ### 
ggscatter(allData_p100_wAttdTrials, x = "casi5_inatt_t_score", y = "erp_vep_veeg_oz_p100_amp", add = "reg.line", conf.int = TRUE, cor.coef = TRUE, cor.method = "pearson", xlab = "ADHD Inattention T-score", ylab = "P100 Amplitude")
# inattention and amplitude not sig 
ggscatter(allData_p100_wAttdTrials, x = "casi5_inatt_t_score", y = "erp_vep_veeg_oz_p100_lat", add = "reg.line", conf.int = TRUE, cor.coef = TRUE, cor.method = "pearson", xlab = "ADHD Inattention T-score", ylab = "P100 Latency")
# inattention and latency not sig 
ggscatter(allData_p100_wAttdTrials, x = "casi5_hyp_impuls_t_score", y = "erp_vep_veeg_oz_p100_amp", add = "reg.line", conf.int = TRUE, cor.coef = TRUE, cor.method = "pearson", xlab = "ADHD Hyperactive-Impulsive T-score", ylab = "P100 Amplitude")
# hyperactive-impulsive and amplitude not significant 
ggscatter(allData_p100_wAttdTrials, x = "casi5_hyp_impuls_t_score", y = "erp_vep_veeg_oz_p100_lat", add = "reg.line", conf.int = TRUE, cor.coef = TRUE, cor.method = "pearson", xlab = "ADHD Hyperactive-Impulsive T-score", ylab = "P100 Latency")
# hyperactive-impulsive and amplitude not sig 

# reverse coding the % attended trials column (1-original value)
# TRIED THIS NO: offTaskBeh <- mutate(df, offTask = 1.0 - df["erp_vep_veeg_a_pct"])
df$offTaskBehavior <- 1 - df$erp_vep_veeg_a_pct

### ON TASK BEHAVIOR DURING SESSION AND P100 ###
ampOffTask <- ggscatter(df, x = "offTaskBehavior", y = "erp_vep_veeg_oz_p100_amp", add = "reg.line", conf.int = TRUE, cor.coef = TRUE, cor.method = "pearson", xlab = "Off-Task Behavior (%)", ylab = "P100 Amplitude (µV)")
ampOffTask +
  #scale_y_continuous(limits=c(-1,30)) +
  font("xlab", size = 20) +
  font("ylab", size = 20)
# p = 0.04, r = 0.13 --> % attended trials and amp sig, more off task behavior related to lower amplitude 
# increasing font after 

latOffTask <- ggscatter(df, x = "offTaskBehavior", y = "erp_vep_veeg_oz_p100_lat", add = "reg.line", conf.int = TRUE, cor.coef = TRUE, cor.method = "pearson", xlab = "Off-Task Behavior (%)", ylab = "P100 Latency (ms)")
latOffTask +
  font("xlab", size = 20)+
  font("ylab", size = 20)
# p = 0.04, r = -0.13 --> % attended trials and lat sig, more off task behavior related to faster latency 

### AUTISM SYMPTOMS AND P100 ###
ggscatter(allData_p100_wAttdTrials, x = "ados_combined", y = "erp_vep_veeg_oz_p100_amp", add = "reg.line", conf.int = TRUE, cor.coef = TRUE, cor.method = "pearson", xlab = "ADOS-2 Combined", ylab = "P100 Amplitude")
# ados and p100 amp not significant 
ggscatter(allData_p100_wAttdTrials, x = "ados_combined", y = "erp_vep_veeg_oz_p100_lat", add = "reg.line", conf.int = TRUE, cor.coef = TRUE, cor.method = "pearson", xlab = "ADOS-2 Combined", ylab = "P100 Latency")
# ados and p100 lat not significant 

### AUTISM SYMPTOMS AND % ATTENDED TRIALS ### 
adosOffTask <- ggscatter(df, x = "ados_combined", y = "offTaskBehavior", add = "reg.line", conf.int = TRUE, cor.coef = TRUE, cor.method = "pearson", xlab = "ADOS-2 Combined", ylab = "Off-Task Behavior (%)")
adosOffTask +
  font("xlab", size = 20)+
  font("ylab", size = 20)
  
# ados and % attended trials correlate significant (p < 0.01, r = -0.21)

### AUTISM SYMPTOMS AND ADHD SYMPTOMS ON CASI ###
ggscatter(allData_p100_wAttdTrials, x = "ados_combined", y = "casi5_combined_t_score", add = "reg.line", conf.int = TRUE, cor.coef = TRUE, cor.method = "pearson", xlab = "ados_combined", ylab = "casi combined t score")
ggscatter(allData_p100_wAttdTrials, x = "ados_combined", y = "casi5_inatt_t_score", add = "reg.line", conf.int = TRUE, cor.coef = TRUE, cor.method = "pearson", xlab = "ados_combined", ylab = "casi inatt t score")
ggscatter(allData_p100_wAttdTrials, x = "ados_combined", y = "casi5_hyp_impuls_t_score", add = "reg.line", conf.int = TRUE, cor.coef = TRUE, cor.method = "pearson", xlab = "ados_combined", ylab = "casi hyp t score")

### REGRESSION W/ AUTISM SYMP CONTROLLED FOR AND % ATTENDED TRIALS ###
# enter ADOS (autism symptoms) first, then behavior --> does behavior predict p100 amplitude and latency independent of autism symptoms 
# do the results from the off task behavior correlations only occur because of autism symptoms --> how do we know that p100 wasn't 
# result of autism symptoms instead of the off task behavior?
model <- lm(erp_vep_veeg_oz_p100_amp ~ ados_combined + offTaskBehavior, data = df)
summary(model)
# amp finding ^ didn't survive controlling for autism symptoms but latency did --> off task behavior could be interesting variable to look at ADHD symptoms 
model2 <- lm(erp_vep_veeg_oz_p100_lat ~ ados_combined + offTaskBehavior, data = df)
summary(model2)
# beta = 19.6599 for %offTaskBeh, beta = 0.2020 for ados_combined
# r^2 = 0.01748 --> only 1.7% of variability in latency is explained by ados and off-task behavior 

# trying to plot multiple regressions
mtcars_added_variable_plots <- mtcars





library(ggplot2) 
avPlots(model2)
ggplotRegression <- function (fit) {
  
  require(ggplot2)
  
  ggplot(fit$model, aes_string(x = names(fit$model)[2], y = names(fit$model)[1])) + 
    geom_point() +
    stat_smooth(method = "lm", col = "red") +
    labs(title = paste("Adj R2 = ",signif(summary(fit)$adj.r.squared, 5),
                       "Intercept =",signif(fit$coef[[1]],5 ),
                       " Slope =",signif(fit$coef[[2]], 5),
                       " P =",signif(summary(fit)$coef[2,4], 5)))
}

equation1=function(x){coef(model2)[2]*x+coef(model2)[1]}
equation2=function(x){coef(model2)[2]*x+coef(model2)[1]+coef(model2)[3]}

ggplot(allData_p100_wAttdTrials,aes(y=erp_vep_veeg_oz_p100_lat,x=ados_combined,color=erp_vep_veeg_a_pct))+geom_point()+
  stat_function(fun=equation1,geom="line",color=scales::hue_pal()(2)[1])+
  stat_function(fun=equation2,geom="line",color=scales::hue_pal()(2)[2])+


### Demographics Info ###
mean(allData_p100_attndtrials$erp_vep_age_at_evaluation)
# mean age = 10.38 years
sd(allData_p100_attndtrials$erp_vep_age_at_evaluation)
# sd age = 1.80 years 

mean(allData_p100_attndtrials$indiv_sex)
# mean sex = 0.767
sd(allData_p100_attndtrials$indiv_sex)
# sd sex = 0.4236729

mean(allData_p100_attndtrials$dxsumm_fscale_ratio_iq)
# mean = 101.78
sd(allData_p100_attndtrials$dxsumm_fscale_ratio_iq)
# sd = 23.14

countMale <- length(which(allData_p100_attndtrials$indiv_sex == 1))
countMale
# 181 male
countFemale <- length(which(allData_p100_attndtrials$indiv_sex == 0))
countFemale
# 55 female

mean(allData_p100_attndtrials$casi5_inatt_t_score)
# 72.55097
sd(allData_p100_attndtrials$casi5_inatt_t_score)
# 12.42882

mean(allData_p100_attndtrials$casi5_hyp_impuls_t_score)
# 69.15547
sd(allData_p100_attndtrials$casi5_hyp_impuls_t_score)
# 14.39255

mean(allData_p100_attndtrials$ados_combined)
# 7.588983
sd(allData_p100_attndtrials$ados_combined)
# 1.811466
