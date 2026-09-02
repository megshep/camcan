library(lme4)
library(splines)
library(openxlsx)
library(ggplot2)
library(dplyr)

data <- read.xlsx("camcan_amygdala_ROI_results.xlsx")

#defining some of the key variables for the models from the dataset
amy_vol <- data$Amygdala_GM
scanner <- as.numeric(data$MRI_scanner)
sex <- data$sex

#define the two models, one with the interaction term and one without the interaction term
model_spline <- lmer(amy_vol ~ bs(Age,knots = c(40, 50, 60, 70)) + ELE + scanner + sex + (1 | Subject_ID), data = data)
model_ELS <- lmer(amy_vol ~ bs(Age,knots = c(40, 50, 60, 70)) * ELE + scanner + sex + (1 | Subject_ID), data = data)

#test to see if the interaction significantly improves the models predictions
anova(model_spline, model_ELS)

# ELS values for the three trajectories, average, sd and high (mean±sd)
ELS_mean <- mean(data$ELE, na.rm = TRUE)
ELS_sd <- sd(data$ELE, na.rm = TRUE)
ELS_high <- ELS_mean + ELS_sd

# Generate predictions at the three ELS levels
plot_data <- ggpredict(model_spline, terms = c("Age [30:80]",paste0("ELE [0,",round(ELS_mean, 2), ",", round(ELS_high, 2),"]")))

# Label the ELS groups
plot_data$ELS <- factor(plot_data$group,levels = unique(plot_data$group),labels = c("No ELS","Average ELS","High ELS"))

# Plot the groups
ggplot(plot_data, aes(x = x, y = predicted,colour = ELS)) +
  geom_line(linewidth = 1.2) +
  labs(x = "Age", y = "Amygdala GM volume", colour = "ELS") +
  scale_colour_manual(values = c(
      "No ELS" = "#0072B2",
      "Average ELS" = "#009E73",
      "High ELS" = "#000000")) +
  theme_classic()
