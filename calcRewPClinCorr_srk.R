library(tidyverse)
library(fs)
library(ggExtra)
library(ggpubr)
library(ggsci)
library(here)
library(dplyr)


# #https://jennybc.github.io/purrr-tutorial/
# timeDir = here("TIMES")
# 
# timeFiles <- fs::dir_ls(timeDir,regexp = ".*TIMES.*\\.csv$") # not safe but not AWFUL
# 
# reactionTimeFrame = 
# timeFiles %>% 
#   map_dfr(read_csv, .id = "fileName") %>% 
#   mutate(fileName = str_remove(fileName,timeDir)) %>% 
#   filter(str_detect(tag,"playerResponse") |str_detect(tag,"showAvatarChoice")) %>% 
#   separate(tag,c("trialType","response"),sep = "--") %>% 
#   separate(trialType,c("trialType","name"),sep = ":") %>%  
#   mutate(name = str_squish(name)) %>% 
#   group_by(fileName, round, name) %>% 
#   mutate(theResponse = str_squish(dplyr::last(response, na_rm = TRUE))) %>% 
#   select(-response) %>% 
#   pivot_wider(names_from = trialType, values_from = time, id_cols = c(name,round,fileName,theResponse) ) %>% 
#   mutate(reactionTime = playerResponse-showAvatarChoice) %>% 
#   filter(name != "jared") %>% 
#   filter(name != "Beth")
# 
# #savefileforeachperson
# # Define the output directory where the CSVs will be saved
# outputDir <- "~/Desktop/ptsreactiontimes"
# 
# # Create the output directory if it doesn't exist
# if (!dir.exists(outputDir)) {
#   dir.create(outputDir)
# }
# 
# # Export a CSV for each file in reactionTimeFrame
# reactionTimeFrame %>%
#   group_by(fileName) %>%
#   group_walk(~ {
#     file_path <- file.path(outputDir, paste0(.y$fileName, "_reaction_times.csv"))
#     write_csv(.x, file_path)
#   })
# 
# 
# #plots
# # for preliminary data we will use a 4 second cutoff
# reactionTimeFrame %>% 
#   filter(reactionTime <4) %>% 
#   ggplot(aes(x =reactionTime, color = theResponse ))+
#   geom_density() +
#   facet_wrap("fileName")
#   
# 
# reactionTimeFrame %>% 
#   filter(reactionTime <4) %>% 
#   ggplot(aes(x =reactionTime, color = theResponse, y = round ))+
#   geom_point() +
#   facet_wrap("fileName")
# 
# # per person varibles we can correlate with brain and behavior
# # mean diff between yea no
# # reaction time variance (this is a harder one to justify) integrity of decision process (ratcliff/mckoon)
# # reaction time differences to different avatars? sex of avatar
# # means/medians of reaction times (with caveats that we can cite)
# # plot RT by IQ
# #
# 
# 
# #avatar
# # Add sex column based on avatar names
# reactionTimeFrame <- reactionTimeFrame %>%
#   mutate(sex = case_when(
#     name %in% c("Ava", "Kylie", "Olivia") ~ "F",
#     name %in% c("Max", "Evan", "Jake") ~ "M",
#     TRUE ~ NA_character_  # Handle unexpected names, though not likely here
#   ))
# 
# head(reactionTimeFrame)
# 
# 
# #Summarystats for everything we want
# summaryStats <- reactionTimeFrame %>%
#   group_by(fileName) %>%
#   summarise(
#     reactionTimeMean = mean(reactionTime, na.rm = TRUE),
#     reactionTimeMedian = median(reactionTime, na.rm = TRUE),
#     reactionTimeVariance = var(reactionTime, na.rm = TRUE),
#     meanDifferenceYesNo = mean(reactionTime[theResponse == "y"], na.rm = TRUE) - mean(reactionTime[theResponse == "n"], na.rm = TRUE),
#     
#     # Calculate mean reaction time for Females and Males
#     meanReactionTimeFemale = mean(reactionTime[sex == "F"], na.rm = TRUE),
#     meanReactionTimeMale = mean(reactionTime[sex == "M"], na.rm = TRUE),
#     
#     # Calculate reaction time difference between Females and Males
#     reactionTimeDifferenceMF = mean(reactionTime[sex == "M"], na.rm = TRUE) - mean(reactionTime[sex == "F"], na.rm = TRUE),
#     
#     .groups = "drop"
#   )
# 
# # Create output directory
# outputDir = here("times_output")
# if (!dir.exists(outputDir)) {
#   dir.create(outputDir)
# }
# 
# # Write the output to a CSV file
# outputFile = file.path(outputDir, "reaction_time_summary.csv")
# write_csv(summaryStats, outputFile)
# 
# --
# #plotting mean/median on density plots just to look
# # Calculate mean and median for each file
# summaryStats <- reactionTimeFrame %>%
#   group_by(fileName) %>%
#   summarise(
#     reactionTimeMean = mean(reactionTime, na.rm = TRUE),
#     reactionTimeMedian = median(reactionTime, na.rm = TRUE)
#   )
# 
# # Plot with mean and median lines
# reactionTimeFrame %>%
#   filter(reactionTime < 4) %>%
#   ggplot(aes(x = reactionTime, color = theResponse)) +
#   geom_density() +
#   facet_wrap("fileName") +
#   geom_vline(
#     data = summaryStats,
#     aes(xintercept = reactionTimeMean, linetype = "Mean"),
#     color = "red",
#     linewidth = 0.8
#   ) +
#   geom_vline(
#     data = summaryStats,
#     aes(xintercept = reactionTimeMedian, linetype = "Median"),
#     color = "blue",
#     linewidth = 0.8
#   ) +
#   scale_linetype_manual(
#     name = "Statistics",
#     values = c("Mean" = "dashed", "Median" = "dotted"),
#     labels = c("Mean", "Median")
#   ) +
#   labs(
#     title = "Reaction Time Density with Mean and Median",
#     x = "Reaction Time (s)",
#     y = "Density"
#   ) +
#   theme_minimal()

#IQ scores now
# Load the IQ data
allData <- read_csv("/Users/shreya/Downloads/flamingoclinicalvars_03182025.csv")
rewpData <- read_csv("/Volumes/T7/flamingo/RewP_amp_output.csv")

# # Extract subject ID from fileName in reactionTimeFrame
# reactionTimeFrame <- reactionTimeFrame %>%
#   mutate(
#     # Remove directory path (anything before the last `/`) and extract string before the first `_`
#     subject_id_info = str_extract(basename(fileName), "^[^_]+")
#   )

# Merge reaction time data with IQ data
mergedData_clin <- rewpData %>%
  left_join(allData %>%
              filter(redcap_event_name == "participant_data_arm_1"), by = "subject_id_info") # Match on subject_id_info

# Check for unmatched IDs
unmatched_clin <- mergedData_clin %>% filter(is.na(dx_summary_das_wasi)) %>% distinct(subject_id_info)
if (nrow(unmatched_clin) > 0) {
  warning("The following IDs did not match: ", paste(unmatched_clin$subject_id_info, collapse = ", "))
}

# # Calculate mean reaction time for each participant
# meanReactionTimeData <- mergedData %>%
#   group_by(subject_id_info, dx_summary_das_wasi) %>%
#   summarise(meanReactionTime = mean(reactionTime, na.rm = TRUE), .groups = "drop")
# 
# # Create scatterplot using mean reaction time
# meanReactionTimeData %>%
#   ggplot(aes(x = dx_summary_das_wasi, y = meanReactionTime)) +
#   geom_point(alpha = 0.6, color = "blue") +
#   geom_smooth(method = "lm", color = "red", se = TRUE) + # Add regression line
#   labs(
#     title = "Mean Reaction Time vs IQ Score",
#     x = "IQ Score (dx_summary_das_wasi)",
#     y = "Mean Reaction Time (s)"
#   ) +
#   theme_minimal()


#depressionstuffbelow

#depdata <- read_csv(here("/Users/casey/Desktop/flamingoclinicalvars_03182025.csv"))

# Extract subject ID from fileName in reactionTimeFrame
# reactionTimeFrame <- reactionTimeFrame %>%
#   mutate(
#     # Remove directory path (anything before the last `/`) and extract string before the first `_`
#     subject_id_info = str_extract(basename(fileName), "^[^_]+")
#   )

# Merge reaction time data with IQ data
# mergedData <- reactionTimeFrame %>%
#   left_join(depdata %>% 
#               filter(redcap_event_name == "child_surveys_arm_1"), by = "subject_id_info") # Match on subject_id_info
# 
# # Check for unmatched IDs
# unmatched <- mergedData %>% filter(is.na(mpvs_total)) %>% distinct(subject_id_info)
# if (nrow(unmatched) > 0) {
#   warning("The following IDs did not match: ", paste(unmatched$subject_id_info, collapse = ", "))
# }
# 
# # Calculate mean reaction time for each participant
# meanReactionTimeData <- mergedData %>%
#   group_by(subject_id_info, mpvs_total) %>%
#   summarise(meanReactionTime = median(reactionTime, na.rm = TRUE), .groups = "drop")
# 
# library(ggpubr)
# library(ggsci)
# # Create scatterplot using mean reaction time
# meanReactionTimeData %>%
#   ggplot(aes(x = mpvs_total, y = meanReactionTime)) +
#   geom_point(alpha = 0.6, color = "blue") +
#   geom_smooth(method = "lm", color = "red", se = TRUE) + # Add regression line
#   labs(
#     title = "Median Reaction Time vs MPVS Score",
#     x = "MPVS Score",
#     y = "Median Reaction Time (s)"
#   ) +
#   theme_minimal()
# 
# 
# 
# cor.test(meanReactionTimeData$mpvs_total, meanReactionTimeData$meanReactionTime)

#corrs for all clinical vars

# Load necessary libraries
library(tidyverse)
library(here)
library(ggpubr)

# Define the output folder
output_folder <- here("corr_output")
if (!dir.exists(output_folder)) {
  dir.create(output_folder)
}

# Extract subject ID from fileName in reactionTimeFrame
# reactionTimeFrame <- reactionTimeFrame %>%
#   mutate(subject_id_info = str_extract(basename(fileName), "^[^_]+"))

# Filter for autistic participants
autistic_participants <- allData %>%
  filter(redcap_event_name == "participant_data_arm_1", group_placement == 1)

autistic_participants_childSurveys <- allData %>%
  filter(redcap_event_name == "child_surveys_arm_1" |
           (redcap_event_name == "participant_data_arm_1" & group_placement == 1))

autistic_participants_parentSurveys <- allData %>%
  filter(redcap_event_name == "parent_surveys_arm_1" |
           (redcap_event_name == "participant_data_arm_1" & group_placement == 1))

# Separate participant data rows
participant_data_child <- autistic_participants_childSurveys %>%
  filter(redcap_event_name == "participant_data_arm_1")

participant_data_parent <- autistic_participants_parentSurveys %>%
  filter(redcap_event_name == "participant_data_arm_1")

# Filter child data rows that have a matching participant row
autistic_participants_childSurveys <- autistic_participants_childSurveys %>%
  filter(redcap_event_name == "child_surveys_arm_1") %>%
  semi_join(participant_data_child, by = "subject_id_info")

autistic_participants_parentSurveys <- autistic_participants_parentSurveys %>%
  filter(redcap_event_name == "parent_surveys_arm_1") %>%
  semi_join(participant_data_parent, by = "subject_id_info")

# just TD if anybody wants it 
td_participants <- allData %>%
  filter(redcap_event_name == "participant_data_arm_1", group_placement == 0)

# Merge child survey data --> all pts
mergedData_child <- rewpData %>%
  left_join(allData %>% 
              filter(redcap_event_name == "child_surveys_arm_1"), 
            by = "subject_id_info")

# merge clin AT only
mergedData_clin_at <- rewpData %>%
  left_join(autistic_participants %>% 
              filter(redcap_event_name == "participant_data_arm_1"), 
            by = "subject_id_info")
mergedData_clin_at <- mergedData_clin_at %>% filter(!is.na(redcap_event_name))

# merge child surveys AT only 
mergedData_child_at <- rewpData %>%
  left_join(autistic_participants_childSurveys %>% 
              filter(redcap_event_name == "child_surveys_arm_1"), 
            by = "subject_id_info")
mergedData_child_at <- mergedData_child_at %>% filter(!is.na(redcap_event_name))

# Merge parent surveys all pts 
mergedData_parent <- rewpData %>%
  left_join(allData %>% 
              filter(redcap_event_name == "parent_surveys_arm_1"), 
            by = "subject_id_info")

# merge parent surveys AT only 
mergedData_parent_at <- rewpData %>%
  left_join(autistic_participants_parentSurveys %>% 
              filter(redcap_event_name == "parent_surveys_arm_1"), 
            by = "subject_id_info")
mergedData_parent_at <- mergedData_parent_at %>% filter(!is.na(redcap_event_name))

# Check for unmatched IDs in each dataset
# unmatched_child <- mergedData_child %>% filter(is.na(alex_total)) %>% distinct(subject_id_info)
# unmatched_parent <- mergedData_parent %>% filter(is.na(tot_raw_cdi2p)) %>% distinct(subject_id_info)

# if (nrow(unmatched_child) > 0) {
#   warning("The following IDs in child surveys did not match: ", paste(unmatched_child$subject_id_info, collapse = ", "))
# }
# if (nrow(unmatched_parent) > 0) {
#   warning("The following IDs in parent surveys did not match: ", paste(unmatched_parent$subject_id_info, collapse = ", "))
# }

# Variables for child and parent datasets --> didn't use this
clin_variables <- c("ados_css")
child_variables <- c("alex_total", "tot_raw_cdi2s", "tot_t_cdi2s", "mpvs_total", "nse_raw_cdi2s", "nse_t_cdi2s", "emotp_raw_cdi2s", "emotp_t_cdi2s")
parent_variables <- c("tot_raw_cdi2p", "tot_t_cdi2p", "emotp_t_cdi2p", "cam_total", "abe_overall_score")

###### all pts corr #######

# all pt ados rewp
corAdosRewPAmp <- cor.test(mergedData_clin$meanAmplitude, mergedData_clin$ados_css)
print(corAdosRewPAmp)

ggscatter(mergedData_clin, x = "meanAmplitude", y = "ados_css", 
          add = "reg.line", conf.int = TRUE, 
          cor.coef = TRUE, cor.method = "pearson",
          xlab = "Mean RewP Amplitude", ylab = "ADOS CSS")

# cdi t scores all pt 
corcdirewp <- cor.test(mergedData_child$meanAmplitude, mergedData_child$tot_t_cdi2s)
print(corcdirewp)

ggscatter(mergedData_child, x = "meanAmplitude", y = "tot_t_cdi2s", 
          add = "reg.line", conf.int = TRUE, 
          cor.coef = TRUE, cor.method = "pearson",
          xlab = "Mean RewP Amplitude", ylab = "CDI T Score Total")

# cdi t score total parent survey
corcdirewp_parent <- cor.test(mergedData_parent$meanAmplitude, mergedData_parent$tot_t_cdi2p)
print(corcdirewp_parent)

ggscatter(mergedData_parent, x = "meanAmplitude", y = "tot_t_cdi2p", 
          add = "reg.line", conf.int = TRUE, 
          cor.coef = TRUE, cor.method = "pearson",
          xlab = "Mean RewP Amplitude", ylab = "CDI T Score Total Parent")

# cdi nse t score child survey
corcdinserewp <- cor.test(mergedData_child$meanAmplitude, mergedData_child$nse_t_cdi2s)
print(corcdinserewp)

ggscatter(mergedData_child, x = "meanAmplitude", y = "nse_t_cdi2s", 
          add = "reg.line", conf.int = TRUE, 
          cor.coef = TRUE, cor.method = "pearson",
          xlab = "Mean RewP Amplitude", ylab = "CDI T Score NSE")

# cdi emo t score child surveys 
corcdiemorewp <- cor.test(mergedData_child$meanAmplitude, mergedData_child$emotp_t_cdi2s)
print(corcdiemorewp)

ggscatter(mergedData_child, x = "meanAmplitude", y = "emotp_t_cdi2s", 
          add = "reg.line", conf.int = TRUE, 
          cor.coef = TRUE, cor.method = "pearson",
          xlab = "Mean RewP Amplitude", ylab = "CDI T Score Emo")

# cdi tscores emo parent surveys 
corcdiemorewp_parent <- cor.test(mergedData_parent$meanAmplitude, mergedData_parent$emotp_t_cdi2p)
print(corcdiemorewp_parent)

ggscatter(mergedData_parent, x = "meanAmplitude", y = "emotp_t_cdi2p", 
          add = "reg.line", conf.int = TRUE, 
          cor.coef = TRUE, cor.method = "pearson",
          xlab = "Mean RewP Amplitude", ylab = "CDI T Score Emo Parent")

# just at clinical corrs 
corAdosRewPAmp_at <- cor.test(mergedData_clin_at$meanAmplitude, mergedData_clin_at$ados_css)
print(corAdosRewPAmp_at)

ggscatter(mergedData_clin_at, x = "meanAmplitude", y = "ados_css", 
          add = "reg.line", conf.int = TRUE, 
          cor.coef = TRUE, cor.method = "pearson",
          xlab = "Mean RewP Amplitude AT Group", ylab = "ADOS CSS AT Group")

# cdi t scores all pt 
corcdirewp <- cor.test(mergedData_child$meanAmplitude, mergedData_child$tot_t_cdi2s)
print(corcdirewp)

ggscatter(mergedData_child, x = "meanAmplitude", y = "tot_t_cdi2s", 
          add = "reg.line", conf.int = TRUE, 
          cor.coef = TRUE, cor.method = "pearson",
          xlab = "Mean RewP Amplitude", ylab = "CDI T Score Total")

corcdinserewp <- cor.test(mergedData_child$meanAmplitude, mergedData_child$nse_t_cdi2s)
print(corcdinserewp)

ggscatter(mergedData_child, x = "meanAmplitude", y = "nse_t_cdi2s", 
          add = "reg.line", conf.int = TRUE, 
          cor.coef = TRUE, cor.method = "pearson",
          xlab = "Mean RewP Amplitude", ylab = "CDI T Score NSE")

corcdiemorewp <- cor.test(mergedData_child$meanAmplitude, mergedData_child$emotp_t_cdi2s)
print(corcdiemorewp)

ggscatter(mergedData_child, x = "meanAmplitude", y = "emotp_t_cdi2s", 
          add = "reg.line", conf.int = TRUE, 
          cor.coef = TRUE, cor.method = "pearson",
          xlab = "Mean RewP Amplitude", ylab = "CDI T Score Emo")

# cdi t scores at only 
corcdirewp_at <- cor.test(mergedData_child_at$meanAmplitude, mergedData_child_at$tot_t_cdi2s)
print(corcdirewp_at)

ggscatter(mergedData_child_at, x = "meanAmplitude", y = "tot_t_cdi2s", 
          add = "reg.line", conf.int = TRUE, 
          cor.coef = TRUE, cor.method = "pearson",
          xlab = "Mean RewP Amplitude AT Group", ylab = "CDI T Score Total AT Group")

corcdirewp_atPar <- cor.test(mergedData_parent_at$meanAmplitude, mergedData_parent_at$tot_t_cdi2p)
print(corcdirewp_atPar)

ggscatter(mergedData_parent_at, x = "meanAmplitude", y = "tot_t_cdi2p", 
          add = "reg.line", conf.int = TRUE, 
          cor.coef = TRUE, cor.method = "pearson",
          xlab = "Mean RewP Amplitude AT Group", ylab = "CDI T Score Total Parent AT Group")


corcdinserewp_at <- cor.test(mergedData_child_at$meanAmplitude, mergedData_child_at$nse_t_cdi2s)
print(corcdinserewp_at)

ggscatter(mergedData_child, x = "meanAmplitude", y = "nse_t_cdi2s", 
          add = "reg.line", conf.int = TRUE, 
          cor.coef = TRUE, cor.method = "pearson",
          xlab = "Mean RewP Amplitude AT Group", ylab = "CDI T Score NSE AT Group")

corcdiemorewp_at <- cor.test(mergedData_child_at$meanAmplitude, mergedData_child_at$emotp_t_cdi2s)
print(corcdiemorewp_at)

ggscatter(mergedData_child_at, x = "meanAmplitude", y = "emotp_t_cdi2s", 
          add = "reg.line", conf.int = TRUE, 
          cor.coef = TRUE, cor.method = "pearson",
          xlab = "Mean RewP Amplitude AT Group", ylab = "CDI T Score Emo At Group")

corcdiemorewp_atPar <- cor.test(mergedData_parent_at$meanAmplitude, mergedData_parent_at$emotp_t_cdi2p)
print(corcdiemorewp_atPar)

ggscatter(mergedData_parent_at, x = "meanAmplitude", y = "emotp_t_cdi2p", 
          add = "reg.line", conf.int = TRUE, 
          cor.coef = TRUE, cor.method = "pearson",
          xlab = "Mean RewP Amplitude AT Group", ylab = "CDI T Score Emo Parent At Group")


# # Initialize an empty data frame for storing correlation results
# correlation_results <- tibble(
#   variable = character(),
#   survey_type = character(),
#   correlation_mean = numeric(),
#   p_value_mean = numeric(),
#   correlation_median = numeric(),
#   p_value_median = numeric()
# )
# 
# # Helper function to process data, create plots, and calculate correlations
# process_survey_data <- function(data, variables, survey_type) {
#   results <- tibble(
#     variable = character(),
#     survey_type = character(),
#     correlation_mean = numeric(),
#     p_value_mean = numeric(),
#     correlation_median = numeric(),
#     p_value_median = numeric()
#   )
#   for (var in variables) {
#     # Check if the variable exists in the data
#     if (!var %in% colnames(data)) {
#       warning(paste("Variable", var, "not found in merged data for", survey_type, ". Skipping."))
#       next
#     }
#     
#     # Calculate mean and median reaction time for each participant
#     reactionTimeStats <- data %>%
#       group_by(subject_id_info) %>%
#       summarise(
#         meanReactionTime = mean(reactionTime, na.rm = TRUE),
#         medianReactionTime = median(reactionTime, na.rm = TRUE),
#         variable_value = first(.data[[var]]), # Take the variable value for the participant
#         .groups = "drop"
#       ) %>%
#       filter(!is.na(variable_value)) # Remove rows where the variable is NA
#     
#     # Check if reactionTimeStats has valid data
#     if (nrow(reactionTimeStats) == 0) {
#       warning(paste("No valid data for variable", var, "in", survey_type, ". Skipping."))
#       next
#     }
#     
#     # Calculate correlations
#     cor_mean <- cor.test(reactionTimeStats$variable_value, reactionTimeStats$meanReactionTime, use = "complete.obs")
#     cor_median <- cor.test(reactionTimeStats$variable_value, reactionTimeStats$medianReactionTime, use = "complete.obs")
#     
#     # Append results to the results tibble
#     results <- results %>%
#       add_row(
#         variable = var,
#         survey_type = survey_type,
#         correlation_mean = cor_mean$estimate,
#         p_value_mean = cor_mean$p.value,
#         correlation_median = cor_median$estimate,
#         p_value_median = cor_median$p.value
#       )
#     
#     # Create scatterplot for mean reaction time
#     plot <- reactionTimeStats %>%
#       ggplot(aes(x = variable_value, y = meanReactionTime)) +
#       geom_point(alpha = 0.6, color = "blue") +
#       geom_smooth(method = "lm", color = "red", se = TRUE) +
#       labs(
#         title = paste("Mean Reaction Time vs", var, "-", survey_type),
#         x = var,
#         y = "Mean Reaction Time (s)"
#       ) +
#       theme_minimal()
#     
#     # Save the plot to the output folder as a PDF
#     ggsave(filename = paste0(output_folder, "/", var, "_", survey_type, "_mean_reaction_time_plotasdgroup.pdf"), 
#            plot = plot, width = 8, height = 6, device = "pdf")
#   }
#   return(results)
# }
# 
# # Process child and parent survey data
# child_results <- process_survey_data(mergedData_child, child_variables, "child_surveys")
# parent_results <- process_survey_data(mergedData_parent, parent_variables, "parent_surveys")
# 
# # Combine results and export to CSV
# correlation_results <- bind_rows(child_results, parent_results)
# write_csv(correlation_results, file = paste0(output_folder, "/reaction_time_correlations_asdgroup.csv"))



