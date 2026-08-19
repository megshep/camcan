library(dplyr)
library(tidyr)
library(rstatix)

df <- read.xlsx('sample_information.xlsx')

#ses3 ages are character format, so convert first
df$Age_p3 <- as.numeric(df$Age_p3)

# Convert to long format
ages_long <- df %>% pivot_longer(
    cols = starts_with("Age"),
    names_to = "Timepoint",
    values_to = "Age") %>%
  filter(!is.na(Age))

# Define age bins
breaks <- c(20, 30, 40, 50, 60, 70, 80, 90, 100)
labels <- c("20-30", "30-40", "40-50", "50-60",
            "60-70", "70-80", "80-90", "90-100")

# Count participants in each age range
age_counts <- ages_long %>% mutate(
    AgeRange = cut(
      Age,
      breaks = breaks,
      labels = labels,
      right = FALSE,      # 20–<30, 30–<40, etc.
      include.lowest = TRUE)) %>%  count(AgeRange)

print(age_counts)


# Calculate count, mean, and SD for each age range
age_summary <- ages_long %>% mutate(
    AgeRange = cut(
      Age,
      breaks = breaks,
      labels = labels,
      right = FALSE,
      include.lowest = TRUE)) %>%
  group_by(AgeRange) %>%
  summarise(
    n = n(),
    Mean = mean(Age, na.rm = TRUE),
    SD = sd(Age, na.rm = TRUE),
    .groups = "drop")

print(age_summary)
