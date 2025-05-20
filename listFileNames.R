# Define the directory path
folder_path <- "/Users/shreya/Downloads/mffZip"

# Get the names of files in the directory
file_names <- list.files(path = folder_path)

# Create a data frame with file names in the first column
file_df <- data.frame(FileNames = file_names)
first_nine_chars <- substr(file_names, 1, 9)

# Specify output CSV file path
output_csv <- "/Users/shreya/Downloads/output_csv"
output2_csv <- "/Users/shreya/Downloads/studyids_csv"

# Write the data frame to CSV
write.csv(file_df, file = output_csv, row.names = FALSE)
write.csv(first_nine_chars, file = output2_csv, row.names = FALSE)