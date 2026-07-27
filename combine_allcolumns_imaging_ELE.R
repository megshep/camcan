library(openxlsx)
library(dplyr)

# Read Excel files
file1 <- read.xlsx("participants.xlsx")
file2 <- read.xlsx("ELE.xlsx")

# Keep only matching IDs and include all variables from both files
common_data <- inner_join(file1, file2, by = "Subject_ID")

# Save
write.xlsx(common_data, "sample_information.xlsx", rowNames = FALSE)
