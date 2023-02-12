# D-virilis-fusion-chromosomes

This repository contains scripts intended for reproducibility of the work in the paper "Three recent sex chromosome-to-autosome fusions in a Drosophila virilis strain with high satellite DNA content".
Please contact Jullien Flynn at jmf422@cornell.edu with any questions. 

The R markdown and accompanied knitted html contain the main analyses presented in the paper. Input files required to run this R markdown are present in the folder "R_input_files".

The stand-alone script "plot_meandiff_dabestr.R" produces the plot that was modified for Figure 3.  

Finally, the folder "simulate_degradation" contains shell scripts that analyze SNPs from the sequencing data to estimate the age of the Y chromosome fusion. The script "simulate_neoY_Degradation_10x_RS2" is contained within, which simulates single nucleotide mutations, then sequencing reads off the mutated genome, and then analysis with GATK best practices.
