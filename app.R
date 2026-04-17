# app.R
library(shiny)
library(Seurat)
library(ggplot2)
library(patchwork)
library(dplyr)

# Increase maximum upload size to 500MB
options(shiny.maxRequestSize = 500 * 1024^2)

ui <- fluidPage(
  theme = bslib::bs_theme(bootswatch = "flatly"),
  titlePanel("scRNA-seq Interactive Explorer"),
  
  sidebarLayout(
    sidebarPanel(
      fileInput("file", "Upload Seurat Object (.rds)", accept = ".rds"),
      hr(),
      conditionalPanel(
        condition = "output.fileUploaded",
        selectInput("res_col", "Select Cluster Metadata:", choices = NULL),
        selectizeInput("gene", "Search Gene:", choices = NULL, multiple = FALSE),
        hr(),
        downloadButton("downloadPlot", "Download Current View")
      )
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("UMAP/Clusters", 
                 plotOutput("umapPlot", height = "500px")),
        tabPanel("Gene Expression", 
                 fluidRow(
                   column(6, plotOutput("featurePlot")),
                   column(6, plotOutput("violinPlot"))
                 )),
        tabPanel("Cluster Markers", 
                 helpText("Click to calculate top markers for the selected cluster."),
                 actionButton("calcMarkers", "Run Differential Expression"),
                 tableOutput("markerTable"))
      )
    )
  )
)

server <- function(input, output, session) {
  
  # Reactive value for the Seurat Object
  data <- reactive({
    req(input$file)
    readRDS(input$file$datapath)
  })
  
  # Check if file is uploaded to show UI elements
  output$fileUploaded <- reactive({
    return(!is.null(data()))
  })
  outputOptions(output, "fileUploaded", suspendWhenHidden = FALSE)
  
  # Update UI choices based on uploaded object
  observeEvent(data(), {
    obj <- data()
    updateSelectInput(session, "res_col", 
                      choices = colnames(obj@meta.data), 
                      selected = "seurat_clusters")
    updateSelectizeInput(session, "gene", 
                         choices = rownames(obj), 
                         server = TRUE)
  })
  
  # Plot 1: UMAP
  output$umapPlot <- renderPlot({
    req(data(), input$res_col)
    DimPlot(data(), group.by = input$res_col, label = TRUE) + 
      theme_minimal() + labs(title = "Dimensional Reduction")
  })
  
  # Plot 2: Feature Plot (Gene Expression)
  output$featurePlot <- renderPlot({
    req(input$gene)
    FeaturePlot(data(), features = input$gene) + 
      scale_colour_gradientn(colours = c("lightgrey", "blue", "red"))
  })
  
  # Plot 3: Violin Plot
  output$violinPlot <- renderPlot({
    req(input$gene, input$res_col)
    VlnPlot(data(), features = input$gene, group.by = input$res_col)
  })
  
  # Logic for Cluster Markers
  markers <- eventReactive(input$calcMarkers, {
    req(data())
    withProgress(message = 'Calculating markers...', value = 0, {
      FindAllMarkers(data(), only.pos = TRUE, min.pct = 0.25, logfc.threshold = 0.25) %>%
        group_by(cluster) %>%
        slice_max(n = 5, order_by = avg_log2FC)
    })
  })
  
  output$markerTable <- renderTable({
    markers()
  })
  
  # Download Handler
  output$downloadPlot <- downloadHandler(
    filename = function() { paste("scRNA_plot_", Sys.Date(), ".png", sep="") },
    content = function(file) {
      p1 <- DimPlot(data(), group.by = input$res_col)
      ggsave(file, plot = p1, device = "png", width = 8, height = 6)
    }
  )
}

shinyApp(ui, server)
