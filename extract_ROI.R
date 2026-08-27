library(oro.nifti)
library(readxl)
library(dplyr)
library(stringr)
library(writexl)

# Load directories
smwc_dir <- "/Users/megsheppard/Desktop/camcan/extract_ROI/smwc"
sample_file <- "/Users/megsheppard/Desktop/camcan/extract_ROI/sample_information.xlsx"

# Load Excel sheet
sample_info <- read_excel(sample_file)

# Make Subject_ID character and add "CC" to match scan filenames
sample_info$Subject_ID <- paste0("CC", as.character(sample_info$Subject_ID))

# Load resampled amygdala mask
mask_file <- "/Users/megsheppard/Desktop/camcan/extract_ROI/bilateral_amygdala_resampled.nii"
amygdala_mask <- readNIfTI(mask_file, reorient = FALSE)
mask_data <- img_data(amygdala_mask)

# Binary mask
mask <- mask_data > 0

# Find all smwc images
smwc_files <- list.files(smwc_dir,pattern = "^smwc1.*\\.nii$", full.names = TRUE)

# Extract subject ID and session from filenames
scan_info <- data.frame(file = smwc_files,filename = basename(smwc_files),stringsAsFactors = FALSE)

scan_info$Subject_ID <- str_extract(scan_info$filename, "sub-CC[0-9]+")
scan_info$Subject_ID <- str_remove(scan_info$Subject_ID, "sub-")
scan_info$Session <- str_extract(scan_info$filename, "ses-P[0-9]+")
scan_info$Session <- str_remove(scan_info$Session, "ses-")

head(scan_info)

# Extract amygdala value from every scan
scan_info$Amygdala_GM <- NA_real_

for (i in seq_len(nrow(scan_info))) {
  img <- readNIfTI(scan_info$file[i], reorient = FALSE)
  values <- img_data(img)
  roi_values <- values[mask]
  roi_values <- roi_values[is.finite(roi_values)]
  scan_info$Amygdala_GM[i] <- mean(roi_values, na.rm = TRUE)
}

# Match demographic/sample information
sample_info <- sample_info %>%
  mutate(p2_mri_scanner = as.character(p2_mri_scanner),
    p3_mri_scanner = as.character(p3_mri_scanner),
    p5_mri_scanner = as.character(p5_mri_scanner))

results <- scan_info %>%
  left_join(sample_info %>%
      select(Subject_ID,Age_p2, Age_p3, Age_p5,sex, p2_mri_scanner, p3_mri_scanner, p5_mri_scanner, ELE),
    by = "Subject_ID")

# Select correct age and scanner for each session
results <- results %>% mutate(Age = case_when(
      Session == "P2" ~ as.numeric(Age_p2),
      Session == "P3" ~ as.numeric(Age_p3),
      Session == "P5" ~ as.numeric(Age_p5),
      TRUE ~ NA_real_),
    
    MRI_scanner = case_when(
      Session == "P2" ~ p2_mri_scanner,
      Session == "P3" ~ p3_mri_scanner,
      Session == "P5" ~ p5_mri_scanner,
      TRUE ~ NA_character_))

# Clean up columns
results <- results %>% select(Subject_ID, Session,Age,sex,MRI_scanner,ELE,Amygdala_GM,filename,file) %>%
  arrange(Subject_ID, Session)

# Check results
head(results)
table(results$Session)

# save output
output_file <- "/Users/megsheppard/Desktop/camcan/extract_ROI/camcan_amygdala_ROI_results.xlsx"
write_xlsx(results, output_file)
