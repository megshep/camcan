library(openxlsx)

# Paths to the Excel files (this instance its an excel file for who has imagaing and who has ELE data)
file1 <- read.xlsx('participants.xlsx')
file2 <- read.xlsx('ELE.xlsx')

# Read both Excel sheets (assuming they all have a column called "Subject_ID" - this needs to be checked beforehand or it will fail!)
ids1 <- file1$Subject_ID
ids2 <- file2$Subject_ID

# Find common IDs across all three Excel sheets
common_ids <- Reduce(intersect, list(ids1, ids2))

# Create a data frame of the overlapping IDs
common_df <- data.frame(Common_Subject_IDs = common_ids)

# Save to a new Excel file
write.xlsx(common_df, file = "common_id.xlsx", rowNames = FALSE)

# Subset imaging to only rows with IDs present in both files (so ids with both sets of complete data)
file1_subset <- file1[file1$Subject_ID %in% common_ids, ]

# Save the subsetted file
write.xlsx(file1_subset, file = "sample_imaging.xlsx", rowNames = FALSE)
