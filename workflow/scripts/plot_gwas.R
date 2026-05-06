library(qqman)

# Load association results
results <- read.table("results/association_results.assoc.logistic", header = TRUE)

# Generate Manhattan Plot
png("results/manhattan_plot.png", width = 800, height = 600)
manhattan(results, chr="CHR", bp="BP", p="P", snp="SNP", main="Manhattan Plot: BRCA Association")
dev.off()

# Generate Q-Q Plot
png("results/qq_plot.png", width = 600, height = 600)
qq(results$P, main = "Q-Q Plot of GWAS p-values")
dev.off()
