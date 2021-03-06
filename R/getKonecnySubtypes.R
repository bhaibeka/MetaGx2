getKonecnySubtypes <- function(eset) {
  expression.matrix <- exprs(eset)
  # Rescale per gene
  expression.matrix <- t(scale(t(expression.matrix)))
  ## take only the first entry for ambiguous probes
  pn <- sub("geneid.", "", rownames(expression.matrix))
  pn <- sapply(strsplit(pn, ","), function (x) { return (x[[1]]) })
  rownames(expression.matrix) <- pn  
  
	## Load centroids defined in Konecny et al., 2014
  supplementary.data <- gdata::read.xls(system.file("extdata", "jnci_JNCI_14_0249_s05.xls", package="MetaGx"), sheet=4)
    
	## Classify using nearest centroid with Spearman's rho
  
  # Subset supplementary.data to consist of centroids with intersecting genes
  # For genes with multiple probesets, take the mean
  centroids <- supplementary.data[,c(2,4:7)]
  centroids[,2:5] <- sapply(centroids[,2:5], function(x) ave(x, centroids$EntrezGeneID, FUN=mean))
  centroids <- unique(centroids)
  rownames(centroids) <- centroids$EntrezGeneID
  centroids <- centroids[,-1]
  
  intersecting.entrez.ids <- intersect(rownames(expression.matrix), rownames(centroids))
  centroids[rownames(centroids) %in% intersecting.entrez.ids,]
  centroids <- centroids[as.character(intersecting.entrez.ids),]
  expression.matrix <- expression.matrix[as.character(intersecting.entrez.ids),]
  
  expression.matrix <- as.data.frame(expression.matrix)
  spearman.cc.vals <- sapply(centroids, function(x) sapply(expression.matrix, function(y) cor(x, y , method="spearman")))
  
  subclasses <- apply(spearman.cc.vals, 1, function(x) as.factor(colnames(spearman.cc.vals)[which.max(x)]))
  
  subclasses <- factor(subclasses, levels=colnames(centroids))
  
  eset$Konecny.subtypes <- subclasses
  
  return(list(Annotated.eset=eset, spearman.cc.vals=spearman.cc.vals))
}
