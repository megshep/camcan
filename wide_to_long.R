library(readxl)
library(dplyr)
library(tidyr)
library(writexl)

root <- "N:/meg_proj/camcan_run2/demographics"

wide <- read_excel(file.path(root, "sample_information.xlsx"))

long <- wide %>%
  select(Subject_ID, Age_p2, Age_p3, Age_p5, sex,
         p2_mri_scanner, p3_mri_scanner, p5_mri_scanner, ELE) %>%   # drops any empty extra columns
  rename(MRI_scanner_p2 = p2_mri_scanner,
         MRI_scanner_p3 = p3_mri_scanner,
         MRI_scanner_p5 = p5_mri_scanner) %>%
  mutate(across(starts_with("MRI_scanner"), as.character)) %>%
  pivot_longer(cols = c(starts_with("Age_p"), starts_with("MRI_scanner_p")),
               names_to = c(".value", "Session"),
               names_sep = "_p") %>%
  mutate(Subject_ID = paste0("CC", Subject_ID),
         Session    = paste0("P", Session)) %>%
  filter(!is.na(Age)) %>%                       # removes P3 rows for people with no P3 scan
  arrange(Subject_ID, Session)

write_xlsx(long, file.path(root, "sample_information_long.xlsx"))
