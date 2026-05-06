library(ggplot2)

pca <- read.table("results/pca.eigenvec", header=FALSE)
colnames(pca)[1:4] <- c("FID", "IID", "PC1", "PC2")

png("results/pca_plot.png")
ggplot(pca, aes(x=PC1, y=PC2)) +
  geom_point(alpha=0.5, color="steelblue") +
  theme_minimal() +
  labs(title="Population Stratification (PCA)", x="PC1", y="PC2")
dev.off()