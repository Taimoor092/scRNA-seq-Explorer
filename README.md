# scRNA-seq Explorer 🧬

A high-performance R Shiny application for the interactive exploration of single-cell RNA sequencing data. This tool allows researchers to visualize Seurat objects without writing code.

[Live Demo on shinyapps.io](YOUR_LINK_HERE)

## ⭐ Key Features
- **Dynamic Upload**: Supports `.rds` files containing Seurat objects.
- **Interactive Visualizations**: 
  - UMAP/t-SNE cluster viewing.
  - Real-time Gene Expression (FeaturePlots).
  - Distribution analysis via Violin Plots.
- **On-the-fly Analysis**: Calculate top cluster marker genes using `FindAllMarkers`.
- **Publication Ready**: Download plots as PNG directly from the UI.

## 🚀 Getting Started

### Prerequisites
You will need R installed. Then, install the required packages:

```R
install.packages(c("shiny", "ggplot2", "dplyr", "patchwork", "bslib"))
if (!require("BiocManager", quietly = TRUE)) install.packages("BiocManager")
BiocManager::install("Seurat")
