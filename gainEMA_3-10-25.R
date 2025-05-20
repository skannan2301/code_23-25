# Load necessary libraries
library(dplyr)
library(tidyr)
library(stringr) #needed for str_detect function
library(lubridate)

#load in file and reformat the date and time 
file <- ("/Users/shreya/Downloads/gain424_March 7, 2025_10.23.csv")
merged_frames <- read.csv(file, header = TRUE, sep = ",", stringsAsFactors = FALSE) %>% separate(RecordedDate, c("date1", "timea"), " ")

record_id <- ""

#convert date1 into Date format - new 3/7 srk --> want it to be ymd for dateDiff later
merged_frames$date1 <- parse_date_time(merged_frames$date1, orders = c("mdy", "ymd", "dmy"))
merged_frames$date1 <- as.Date(merged_frames$date1)

#remove the time column
merged_frames <- merged_frames %>% select(-timea)

#remove unwanted columns by name
columns_to_remove <- c("StartDate", "EndDate", "Status", "IPAddress", "Progress", 
                       "Duration..in.seconds.", "Finished", "ResponseId", 
                       "RecipientLastName", "RecipientFirstName", "RecipientEmail", 
                       "LocationLatitude", "LocationLongitude", "DistributionChannel", 
                       "UserLanguage")  
merged_frames <- merged_frames %>% select(-all_of(columns_to_remove))

#Change study ID here: 
merged_frames <- merged_frames %>% filter(str_detect(ExternalReference, record_id))

#grouping by their id + creating column for which day of the survey info is coming from
merged_frames <- merged_frames %>%
  group_by(ExternalReference) %>%
  mutate(
    day1 = first(date1),  # Keep day1 as date object
    date_diff = as.numeric(difftime(date1, day1, units = "days")) + 1
  )

#remove the date column
merged_frames <- merged_frames %>% select(-date1)

# srk 3/7 - don't need these anymore, there's no longer a RecordedDate column, making RecordedDate column NULL in new df b/c it's diff every day, messes w pivot_wider
# merged_frames_nodate <- merged_frames
# merged_frames_nodate$RecordedDate <- NULL

#wide df
new_merge <- merged_frames %>%
  pivot_wider(
    names_from = c(date_diff),            # names of columns coming from which day of survey
    names_glue = "d{date_diff}_{.value}", # names of columns: includes day of survey + what the question was
    values_from = c(Distract:randomID)    # what values are included 
    #names_vary = "slowest" # columns go day by day (d1...) --> didn't work for d1, d2... but works for d0, d1...
    #values_fn = list # gets rid of "there's a list in there now" warning when pt does survey twice in one day 
  )

#rename ExternalReference to record_id
colnames(new_merge)[colnames(new_merge) == "ExternalReference"] <- "record_id"

#make column names lowercase
names(new_merge) <- gsub("[^[:alnum:]_]", "", names(new_merge))  # Remove special characters
names(new_merge) <- tolower(names(new_merge))

#duplicate rows and append --1 and --2 for REDCap --> srk 3/7 changed first line to take from new_merge so you don't get NA rows
duplicated_df <- new_merge[rep(1:nrow(new_merge), each = 2), ]
duplicated_df$record_id[seq(1, nrow(duplicated_df), by = 2)] <- paste0(duplicated_df$record_id[seq(1, nrow(duplicated_df), by = 2)], "--1")
duplicated_df$record_id[seq(2, nrow(duplicated_df), by = 2)] <- paste0(duplicated_df$record_id[seq(2, nrow(duplicated_df), by = 2)], "--2")

#save to CSV
write.csv(duplicated_df, paste0("/Users/shreya/Desktop/", record_id, "_EMA.csv"), row.names = FALSE)
