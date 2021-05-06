#!/usr/bin/env Rscript

# run this script with:
# Rscript --vanilla plot_meandiff_dabestr.R

library(dabestr)
library(dplyr)

my.data <- read.csv("comets_finalmod_jan29-21.csv", header = T)
my.data$category <- "olive"

multi.group <- 
  my.data %>%
  dabest(sample, olive_moment, 
         idx = list(c("Gdvir_con", "Gdvir_rad"), 
                    c("vir00_con", "vir00_rad"),
                    c("KH15_con", "KH15_rad"),
                    c("vir8_con", "vir8_rad"),
                    c("vir9_con", "vir9_rad"),
                    c("vir48_con", "vir48_rad"),
                    c("vir85_con", "vir85_rad")),
         paired = FALSE
  )

(multi.group.mean_diff <- multi.group %>% mean_diff()) 


pdf(file = "dabest_meandiff_comets_jan29.pdf", width = 15, height = 5)
plot(multi.group.mean_diff, color.column = category, axes.title.fontsize = 10)
dev.off()



