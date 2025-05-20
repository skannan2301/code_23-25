library(dplyr)

data <- read.csv("/Users/shreya/Downloads/PFSExport1125.csv")

#deleted redcap_repeat_instrument and redcap_repeat_instance b/c empty columns 

#Fill missing values of `scr_sex_birth` within each ID group
data <- data %>%
  group_by(record_id) %>% 
  mutate(scr_sex_birth = first(na.omit(scr_sex_birth)))

#Fill missing values of `cba_study_grp` within each ID group
data <- data %>%
  group_by(record_id) %>% 
  mutate(dxsumm_dsm5_clin_dx = first(na.omit(dxsumm_dsm5_clin_dx)))

#removing any rows that have the screener
#data_filtered <- data[!data$redcap_event_name %in% c("screening_arm_1")]
data <- data[!(data$redcap_event_name %in% c("screening_arm_1")), ]

#filter out any rows that have NA (pt didn't get EEG data that day/exited study)
data_filtered <- na.omit(data)

#Save the updated CSV
write.csv(data_filtered, "/Users/shreya/Desktop/daac/newEEGStuff/runlogsPFS1125.csv", row.names = FALSE)
