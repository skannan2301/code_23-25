library(dplyr)
library(purrr)
library(tidyr)
library(ggplot2)
library(afex)
library(lsr)
library(effectsize)
library(ggpubr)


###### ALL KIDS #######
# Read in data 
hfChildAll <- read.csv("/Volumes/T7/HFdata/childEEG/6_hfChildAll.csv")

# Create new long-format data frames
desired_cols <- c("record_id", "info_dx", "info_age", "vabs_3_exp", "info_gender")
gamma_cols <- grep("^Gamma", colnames(hfChildAll), value = TRUE)
gamma_cols_lm <- grep("ln$", gamma_cols, value = TRUE)
all_cols <- c(desired_cols, gamma_cols_lm)
GammaData <- hfChildAll[, all_cols]

GammaData_long <- GammaData %>%
  pivot_longer(
    cols = starts_with("Gamma_ROIave_"),  # Specify columns that start with "Gamma_ROIave_"
    names_to = "ROI",                     # New column for Gamma variable names
    names_prefix = "Gamma_ROIave_",       # Remove the "Gamma_ROIave_" prefix from the names
    values_to = "AvePower"                # New column for the values from Gamma variables
  )
GammaData_long <- GammaData_long %>%
  mutate(ROI = recode(ROI,
                      "all_ln"  = "All Chans",
                      "cele_ln" = "Central Left",
                      "cemi_ln" = "Central Midline",
                      "ceri_ln" = "Central Right",
                      "frle_ln" = "Frontal Left",
                      "frmi_ln" = "Frontal Midline",
                      "frri_ln" = "Frontal Right",
                      "pole_ln" = "Posterior Left",
                      "pomi_ln" = "Posterior Middle",
                      "pori_ln" = "Posterior Right"
  ))
  
save(GammaData_long, file = "/Users/shreya/Desktop/Gamma_INSAR.Rdata")
# Create smaller data frames for analyses 

# All Channels
GammaDataAllChans <- GammaData_long %>%
  filter(ROI == "All Chans")
save(GammaDataAllChans, file = "/Users/shreya/Desktop/GammaDataAllChans.Rdata")

# ROIs
GammaDataROI <- GammaData_long %>%
  filter(ROI != "All Chans")
save(GammaDataROI, file = "/Users/shreya/Desktop/GammaDataROI.Rdata")

# Frontal ROIs
FrontalGamma <- GammaDataROI %>%
  filter(ROI %in% grep("^Frontal", ROI, value = TRUE))
save(FrontalGamma, file = "/Users/shreya/Desktop/FrontalGamma.Rdata")


# # ANOVA to test whether group and ROI predict gamma power (all channels) - omnibus that Jamie wanted 
groupROI_anova <- aov_car(AvePower ~ info_dx * ROI + Error(record_id/ROI), data = GammaDataROI)
print(groupROI_anova)
eta_squared_results <- eta_squared(groupROI_anova)
print(eta_squared_results)
# #      Effect           df  MSE         F  ges p.value
# #     info_dx        1, 39 1.65      2.67 .040    .110
# #         ROI 4.50, 175.31 0.23 40.70 *** .287   <.001
# # info_dx:ROI 4.50, 175.31 0.23      1.50 .015    .198
# 
# # No main effect of Group
# # Main effect of ROI
# # No group x ROI interaction 

# Parameter   | Eta2 (partial) |       95% CI
# -------------------------------------------
# info_dx     |           0.06 | [0.00, 1.00]
# ROI         |           0.51 | [0.44, 1.00]
# info_dx:ROI |           0.04 | [0.00, 1.00]


# Follow-up linear regression model indicated this effect was driving by [higher/lower] power in frontal regions
# Bri will work on this and follow up with you
lm_group_ROI <- lmer(AvePower ~ info_dx + ROI + (1|record_id), data = GammaDataROI)
summary(lm_group_ROI)

lm_group_ROI <- lm(AvePower ~ info_dx * ROI + (1 | record_id), data = GammaDataROI)
lm_ROI <- AvePower ~ ROI + (1 | record_id)

library(afex)
m1AJN <-mixed(AvePower ~ info_dx + ROI +info_age+ (1|record_id), data = GammaDataROI)
m2AJN <-mixed(AvePower ~ info_dx + ROI +info_age+ (1|record_id), data = GammaDataROI %>% 
                filter(ROI != "Central Midline"))


GammaDataROI %>% 
  ggplot(aes(x= AvePower, color = info_dx))+
  geom_density()+
  facet_wrap(~ROI)

afex_plot(m1AJN, x = "ROI", trace = "info_dx")


# GammaDataROI$ROI %>% table()


# (Optional)
# Pick one of these (anova or t-test) if you want to include this group difference (without including ROI in model and just looking at group differences in overall gamma power across the scalp)
# ANOVA to test for group difference in gamma power - all channels 
AllChansAnova <- aov(AvePower ~ info_dx , data = GammaDataAllChans)
summary(AllChansAnova)
#             Df Sum Sq Mean Sq F value Pr(>F)  
# info_dx      1  0.725  0.7250   3.493 0.0692 .
allChansttest <- t.test(AvePower ~ info_dx, data = GammaDataAllChans)
print(allChansttest)

install.packages("effsize") # if not installed
library(effsize)

cohen.d(AvePower ~ info_dx, data = GammaDataAllChans, hedges.correction = TRUE)

# t = -1.99, df = 37.878, p-value = 0.05384
# 95 percent confidence interval: [-0.54992491  0.004737047]

# compute effect size (cohen's d or parital eta squared, depending on which test you decide to report)
# effect size for ANOVA --> partial eta-squared
etaSq_ANOVA <- etaSquared(AllChansAnova, anova = TRUE)
print(etaSq_ANOVA)
# eta.sq eta.sq.part        SS df        MS       F          p
# info_dx   0.08220006  0.08220006 0.7249508  1 0.7249508 3.49292 0.06915539
# Residuals 0.91779994          NA 8.0943957 39 0.2075486      NA         NA

# graphing the one-way ANOVA for funsies
GammaDataAllChansNew <- GammaDataAllChans
GammaDataAllChansNew <- GammaDataAllChansNew %>%
  mutate(info_dx = case_when(
    info_dx == "asd" ~ "Autistic",
    info_dx == "td" ~ "Neurotypical",
    TRUE ~ info_dx
  ))


# Plot
ggplot(GammaDataAllChansNew, aes(x = info_dx, y = AvePower, fill = info_dx)) +
  geom_boxplot() +
  scale_fill_manual(values = c("Autistic" = "plum", "Neurotypical" = "gray")) +
  labs(
    title = "Gamma Power in Autistic and Neurotypical Youth",
    x = "Diagnosis",
    y = "Gamma Power (All Electrodes)"
  ) +
  theme_minimal(base_family = "Arial") +  # Set base font to Arial
  theme(
    plot.title = element_text(hjust = 0.5),
    #legend.position = "none"
  )


# looking at gender diff --> not much 
allChansGenderttest <- t.test(AvePower ~ info_gender, data = GammaDataAllChans)
print(allChansGenderttest)


# splitting into age groups (split at the median)
GammaDataAllChans$age_group <- ifelse(GammaDataAllChans$info_age <= median(GammaDataAllChans$info_age), "Lower Half", "Upper Half")

# Calculate correlations for each group
lower_half_cor <- cor(GammaDataAllChans[GammaDataAllChans$age_group == "Lower Half", "AvePower"], 
                      GammaDataAllChans[GammaDataAllChans$age_group == "Lower Half", "vabs_3_exp"])

upper_half_cor <- cor(GammaDataAllChans[GammaDataAllChans$age_group == "Upper Half", "AvePower"], 
                      GammaDataAllChans[GammaDataAllChans$age_group == "Upper Half", "vabs_3_exp"])

# Fisher's z-transformation
z_lower <- 0.5 * log((1 + lower_half_cor) / (1 - lower_half_cor))
z_upper <- 0.5 * log((1 + upper_half_cor) / (1 - upper_half_cor))

# Calculate the standard error
n_lower <- nrow(GammaDataAllChans[GammaDataAllChans$age_group == "Lower Half", ])
n_upper <- nrow(GammaDataAllChans[GammaDataAllChans$age_group == "Upper Half", ])
se <- sqrt((1 / (n_lower - 3)) + (1 / (n_upper - 3)))

# Z-test for comparing correlations
z_diff <- (z_lower - z_upper) / se
p_value <- 2 * (1 - pnorm(abs(z_diff)))

# Print results
cat("Lower Half Correlation:", lower_half_cor, "\n")
cat("Upper Half Correlation:", upper_half_cor, "\n")
cat("Z-test result:", z_diff, "\n")
cat("P-value:", p_value, "\n")



# all kiddos avg power over head and vabs expressive language corr 
ggscatter(hfChildAll, x = "vabs_3_exp", y = "Gamma_ROIave_all_ln", 
          add = "reg.line", conf.int = TRUE, 
          cor.coef = TRUE, cor.method = "pearson",
          xlab = "vabs_3_exp", ylab = "Gamma all")

########## ASD KIDS ############
# just asd kiddos section
# Filter rows where 'info_dx' is 'asd'
filtered_asd <- hfChildAll[hfChildAll$info_dx == "asd", ]
filtered_td <- hfChildAll[hfChildAll$info_dx == "td", ]

print(filtered_asd$info_age)
mean(filtered_asd$info_age) / 12
sd(filtered_asd$info_age) / 12
mean(hfChildAll$info_age) / 12
sd(hfChildAll$info_age) / 12
mean(filtered_td$info_age) / 12
sd(filtered_td$info_age) / 12
mean(hfChildAll$dx_summary_gca, na.rm=TRUE)
sd(hfChildAll$dx_summary_gca, na.rm=TRUE)
mean(filtered_asd$dx_summary_gca, na.rm=TRUE)
sd(filtered_asd$dx_summary_gca)
mean(filtered_td$dx_summary_gca, na.rm=TRUE)
sd(filtered_td$dx_summary_gca, na.rm=TRUE)

mean(hfChildAll$vabs_3_exp)
sd(hfChildAll$vabs_3_exp)

# count m and f
library(stringr)
sum(str_count(hfChildAll$info_gender, "male"))
sum(str_count(hfChildAll$info_gender, "female"))
sum(str_count(hfChildAll$info_dx, "asd"))
sum(str_count(hfChildAll$info_dx, "td"))

print(hfChildAll$dx_summary_gca)

# higher gamma power, higher expressive language skills ? this is opp of hyp
# R = 0.42, p = 0.035
ggscatter(filtered_asd, x = "vabs_3_exp", y = "Gamma_ROIave_frmi_ln", 
          add = "reg.line", conf.int = TRUE, 
          cor.coef = TRUE, cor.method = "pearson",
          title = "Gamma Power over Frontal Midline in Autistic Youth",
          xlab = "Vineland Expressive Score", ylab = "Gamma Power over Frontal Midline")
# R = 0.41, p = 0.044
ggscatter(filtered_asd, x = "vabs_3_exp", y = "Gamma_ROIave_cele_ln", 
          add = "reg.line", conf.int = TRUE, 
          cor.coef = TRUE, cor.method = "pearson",
          xlab = "vabs exp", ylab = "Gamma Central Left")
# R = 0.44, p = 0.029
ggscatter(filtered_asd, x = "vabs_3_exp", y = "Gamma_ROIave_pori_ln", 
          add = "reg.line", conf.int = TRUE, 
          cor.coef = TRUE, cor.method = "pearson",
          xlab = "vabs exp", ylab = "Gamma Posterior Right")

# over all eelctrodes 
ggscatter(filtered_asd, 
          x = "vabs_3_exp", y = "Gamma_ROIave_all_ln", 
          add = "reg.line", conf.int = TRUE, 
          cor.coef = TRUE, cor.method = "pearson",
          xlab = "Vineland Expressive T Score", ylab = "Gamma Power (All Electrodes)",
          add.params = list(color = "black", fill = "plum")) +  # plum is a nice lilac shade
  ggtitle("Correlation Between Expressive Language and Gamma Power in Autistic Youth") +
  theme(
    plot.title = element_text(hjust = 0.3, family = "Arial"),
    text = element_text(family = "Arial")
  )

# no gender diff in autistic group
allChansAutGenderttest <- t.test(Gamma_ROIave_all_ln ~ info_gender, data = filtered_asd)
print(allChansAutGenderttest)

# corr btwn gamma over all electrodes and vabs expressive survives controlling for age of pt 
model <- lm(Gamma_ROIave_all_ln ~ info_age + vabs_3_exp, data = filtered_asd)
summary(model)

model2 <- lm(Gamma_ROIave_cele_ln ~ info_age + vabs_3_exp, data = filtered_asd)
summary(model)

model3 <- lm(Gamma_ROIave_frmi_ln ~ info_age + vabs_3_exp, data = filtered_asd)
summary(model)

########## group diffs (old) #########

# p = 0.05384
t.test(Gamma_ROIave_all_ln~info_dx, data = hfChildAll)
ggplot(hfChildAll, aes(x = info_dx, y = Gamma_ROIave_all_ln, fill = info_dx)) +
  geom_boxplot() +
  labs(title = "Gamma Power in Autistic and Typically Developing Children",
       x = "Diagnosis", y = "Gamma Power Over All Electrodes") +
  theme_minimal()

# p = 0.0217
t.test(Gamma_ROIave_frmi_ln~info_dx, data = hfChildAll)
ggplot(hfChildAll, aes(x = info_dx, y = Gamma_ROIave_frmi_ln, fill = info_dx)) +
  geom_boxplot() +
  labs(title = "Frontal Midline Gamma Power in Autistic and Typically Developing Children",
       x = "Diagnosis", y = "Gamma Power Frontal Midline") +
  theme_minimal()

# p = 0.01525
t.test(Gamma_ROIave_frle_ln~info_dx, data = hfChildAll)
ggplot(hfChildAll, aes(x = info_dx, y = Gamma_ROIave_frle_ln, fill = info_dx)) +
  geom_boxplot() +
  labs(title = "Frontal Left Gamma Power in Autistic and Typically Developing Children",
       x = "Diagnosis", y = "Gamma Power Frontal Left") +
  theme_minimal()

# no sig diff btwn groups 
t.test(Gamma_ROIave_cele_ln~info_dx, data = hfChildAll)
t.test(Gamma_ROIave_cemi_ln~info_dx, data = hfChildAll)
t.test(Gamma_ROIave_ceri_ln~info_dx, data = hfChildAll)

t.test(Gamma_ROIave_frri_ln~info_dx, data = hfChildAll)

t.test(Gamma_ROIave_pole_ln~info_dx, data = hfChildAll)
t.test(Gamma_ROIave_pomi_ln~info_dx, data = hfChildAll)
t.test(Gamma_ROIave_pori_ln~info_dx, data = hfChildAll)

############ AGE #############
# age increase, gamma power decrease R = -0.24, p = 0.12
# pretty flat when looking at regions where gamma&vabs correlated significantly 
ggscatter(hfChildAll, x = "info_age", y = "Gamma_ROIave_all_ln", 
          add = "reg.line", conf.int = TRUE, 
          cor.coef = TRUE, cor.method = "pearson",
          xlab = "age", ylab = "Gamma")

ggscatter(filtered_asd, x = "info_age", y = "Gamma_ROIave_all_ln", 
          add = "reg.line", conf.int = TRUE, 
          cor.coef = TRUE, cor.method = "pearson",
          cor.coef.coord = c(max(filtered_asd$info_age) * 0.8, max(filtered_asd$Gamma_ROIave_all_ln)),  # Adjust as needed
          xlab = "Age (Months)", ylab = "Gamma Power (All Electrodes)",
          add.params = list(color = "black", fill = "plum")) +  # plum is a nice lilac shade
  ggtitle("Correlation Between Age and Gamma Power in Autistic Youth") +
  theme(
    plot.title = element_text(hjust = 0.3, family = "Arial"),
    text = element_text(family = "Arial")
    )

ggscatter(filtered_td, x = "info_age", y = "Gamma_ROIave_all_ln", 
          add = "reg.line", conf.int = TRUE, 
          cor.coef = TRUE, 
          cor.method = "pearson",
          cor.coef.coord = c(max(filtered_td$info_age) * 0.8, max(filtered_td$Gamma_ROIave_all_ln)),  # Adjust as needed
          xlab = "Age (Months)", ylab = "Gamma Power (All Electrodes)",
          add.params = list(color = "black", fill = "gray")) +
  ggtitle("Correlation Between Age and Gamma Power in Neurotypical Youth") +
  theme(
    plot.title = element_text(hjust = 0.3, family = "Arial"),
    text = element_text(family = "Arial")
  )


# nothing with receptive language 

########### COG #####################
# non verbal and gamma --> iq increases with gamma power
ggscatter(hfChildAll, x = "dx_summary_non", y = "Gamma_ROIave_all_ln", 
          add = "reg.line", conf.int = TRUE, 
          cor.coef = TRUE, cor.method = "pearson",
          xlab = "non verbal iq", ylab = "Gamma")

# so flat
ggscatter(hfChildAll, x = "dx_summary_verb", y = "Gamma_ROIave_all_ln", 
          add = "reg.line", conf.int = TRUE, 
          cor.coef = TRUE, cor.method = "pearson",
          xlab = "verbal iq", ylab = "Gamma")

# gca and gamma --> iq up gamma up 
ggscatter(hfChildAll, x = "dx_summary_gca", y = "Gamma_ROIave_all_ln", 
          add = "reg.line", conf.int = TRUE, 
          cor.coef = TRUE, cor.method = "pearson",
          xlab = "gca", ylab = "Gamma")

# just td kids, best was pomi p = 0.16
filtered_data2 <- hfChildAll[hfChildAll$info_dx == "td", ]
ggscatter(filtered_data2, x = "vabs_3_exp", y = "Gamma_ROIave_pomi_ln", 
          add = "reg.line", conf.int = TRUE, 
          cor.coef = TRUE, cor.method = "pearson",
          xlab = "vabs exp", ylab = "Gamma")

###########################################################
# cele within participant correlations
hfChild_cele <- read.csv("/Volumes/T7/HFdata/childEEG/3_runThroughR/1_ASD/allSubs_bandpower_cele_asd.csv")
df_long_cele <- hfChild_cele %>%
  pivot_longer(cols = starts_with("Delta") | starts_with("Theta") | starts_with("LowAlpha") | starts_with("HighAlpha") | starts_with("Beta") | starts_with("Gamma"),  # Specify which columns to pivot
               names_to = c(".value", "electrode"),
               names_sep = "_") %>%
  filter(electrode != "ROIave")

gam_bet <- df_long_cele %>%
  group_by(Row) %>%
  summarise(correlation = cor(Gamma, Beta))

# average corr is .5893
averageCorrGamBet <- mean(gam_bet$correlation)

del_the <- df_long_cele %>%
  group_by(Row) %>%
  summarise(correlation = cor(Delta, Theta))

# average corr is .7914
averageCorrDelThe <- mean(del_the$correlation)

alp_bet <- df_long_cele %>%
  group_by(Row) %>%
  summarise(correlation = cor(HighAlpha, Beta))

# average corr is .6092
averageCorrAlpBet <- mean(alp_bet$correlation)

alp_gam <- df_long_cele %>%
  group_by(Row) %>%
  summarise(correlation = cor(HighAlpha, Gamma))

# average corr is .1441
averageCorrAlpGam <- mean(alp_gam$correlation)

del_gam <- df_long_cele %>%
  group_by(Row) %>%
  summarise(correlation = cor(Delta, Gamma))

# average corr is .4717
averageCorrDelGam <- mean(del_gam$correlation)


########### within pt corrs #########################
hfChildBands <- read.csv("/Volumes/T7/HFdata/childEEG/3_runThroughR/1_ASD/allSubs_bandpower_all_asd.csv")
df_long_all <- hfChildBands %>%
  pivot_longer(cols = starts_with("Delta") | starts_with("Theta") | starts_with("LowAlpha") | starts_with("HighAlpha") | starts_with("Beta") | starts_with("Gamma"),  # Specify which columns to pivot
               names_to = c(".value", "electrode"),
               names_sep = "_") %>%
  filter(electrode != "ROIave")

del_gam <- df_long_all %>%
  group_by(Row) %>%
  summarise(correlation = cor(Delta, Gamma))

plot(df_long_all$Delta, df_long_all$Gamma)
plot(del_gam$correlation)
mean(del_gam$correlation)

alp_gam <- df_long_all %>%
  group_by(Row) %>%
  summarise(correlation = cor(HighAlpha, Gamma))
plot(df_long_all$HighAlpha, df_long_all$Gamma)
plot(alp_gam$correlation)
mean(alp_gam$correlation)




