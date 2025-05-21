# Load necessary libraries
library(dplyr)
library(tidyr)
library(stringr) #needed for str_detect function
library(lubridate)
library(ggplot2)


#load in file and reformat the date and time 
file <- ("")
merged_frames <- read.csv(file, header = TRUE, sep = ",", stringsAsFactors = FALSE) %>% separate(RecordedDate, c("dateCompleted", "timeCompleted"), " ")

#record_id <- "tryzrej98"

#convert date1 into Date format - new 3/7 srk --> want it to be ymd for dateDiff later
merged_frames$dateCompleted <- parse_date_time(merged_frames$dateCompleted, orders = c("mdy", "ymd", "dmy"))
merged_frames$dateCompleted <- as.Date(merged_frames$dateCompleted)

# long format --> want to keep like this for plotting
merged_frames <- merged_frames %>%
  group_by(ExternalReference) %>%
  arrange(dateCompleted, .by_group = TRUE) %>%
  mutate(
    day1 = first(dateCompleted),  # First date in the group
    date_diff = as.numeric(difftime(dateCompleted, day1, units = "days")) + 1
  ) %>%
  ungroup()
merged_frames$dateCompleted <- as.Date(merged_frames$dateCompleted)

# i only want the random id columns 
new_merge <- merged_frames %>%
  select(-Distract:-Headphones_3_TEXT)  %>%
  filter(date_diff <= 15)

# get rid of duplicates? (pt completed survey twice in one day)
#duplicates <- new_merge %>%
#  group_by(ExternalReference, dateCompleted) %>%
#  filter(n() > 1) %>%
#  ungroup()

#print(duplicates)

# get a csv of just randomid columns by ID --> not relevant for now, good check though 
#write.csv(new_merge, "/Users/shreya/Desktop/EMACleanWider.csv", row.names = FALSE)

# start from your long df with date_diff (1–…) and one row per completion
new_merge_plot <- new_merge %>%
  mutate(present = TRUE) %>%
  complete(
    ExternalReference,
    date_diff = 1:15,
    fill = list(present = FALSE)
  )

# compute % complete per ExternalReference
percent_new_merge <- new_merge_plot %>%
  group_by(ExternalReference) %>%
  summarise(pct = sum(present) / 15 * 100) %>%
  mutate(
    label = paste0(ExternalReference, " (", sprintf("%.1f%%", pct), ")")
  )

# plot, but map y against the new label
ggplot(new_merge_plot, aes(x = date_diff, y = ExternalReference, fill = present)) +
  geom_tile(color = "grey90") +
  scale_x_continuous(breaks = 1:15, expand = c(0,0)) +
  scale_y_discrete(
    # replace raw refs with “Ref (xx.x%)”
    labels = setNames(percent_new_merge$label, percent_new_merge$ExternalReference)
  ) +
  scale_fill_manual(
    values = c("FALSE" = "white", "TRUE" = "steelblue"),
    name   = "Completed"
  ) +
  labs(
    x = "Day (1–15)",
    y = NULL,
    title = "Survey Completions by Day with % Complete"
  ) +
  theme_minimal() +
  theme(
    axis.text.y = element_text(size = 7),
    panel.grid  = element_blank()
  )
