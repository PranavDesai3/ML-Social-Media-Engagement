#------- install necessary packages and load libraries ------------------------#
install.packages('caret')
install.packages('factoextra')

library(tidyverse)
library(dplyr)
library(caret)
library(factoextra)
#------------------------------------------------------------------------------#

#--------------------- Data Evaluation ----------------------------------------#
#reading the data from file
data <- read.csv('Data_DMML.csv')

cor(data)
#There is high correlation between InDegree, OutDegree and TotalPosts attributes

#checking for null values
sum(is.na(data)) #no null values found in data

skim(data)
summary(data)
#------------------------------------------------------------------------------#

#---------- Standardising data for clustering ---------------------------------#
# Prepare the data for scaling (excluding the ID column)
data_for_scaling <- data[,-1]

scaled_data <- scale(data_for_scaling)
summary(scaled_data)

#------------------------------------------------------------------------------#

#-------------- PCA -----------------------------------------------------------#
# Perform PCA
pca_result <- prcomp(data_for_scaling, center = TRUE, scale. = TRUE)

# Determine the number of principal components to retain
# This can be done using a scree plot
fviz_eig(pca_result)

# Assuming we decide to retain '4' components, use them for K-means clustering
# Extract the principal components
#data_pca <- as.data.frame(pca_result$x[, 1:4])

print(summary(pca_result))  # Check the proportion of variance explained

# Decide on the number of principal components to retain
# Here we will choose components that explain, e.g., at least 80% of the variance
cum_var_explained <- cumsum(pca_result$sdev^2 / sum(pca_result$sdev^2))
num_components <- which(cum_var_explained >= 0.80)[1]
data_pca <- as.data.frame(pca_result$x[, 1:num_components])
#------------------ Finding Optimal number of clusters ------------------------#
# Determine the optimal number of clusters using the elbow method
set.seed(123) # For reproducibility

fviz_nbclust(data_pca, kmeans, method = "wss")
fviz_nbclust(data_pca, kmeans, method = "silhouette")

#------------------------------------------------------------------------------#

# Determine optimal number of clusters
# Here we will try multiple values for `centers` and `nstart`
# and choose the one with the best average silhouette score
set.seed(123)
silhouette_scores <- sapply(2:10, function(k) {
  km <- kmeans(data_pca, centers = k, nstart = 500)
  silhouette_score <- silhouette(km$cluster, dist(data_pca))
  mean(silhouette_score[, 3])
})

optimal_k <- which.max(silhouette_scores)
print(paste("Optimal number of clusters: ", optimal_k))


#-------------------- Running K-Means -----------------------------------------#
# Run K-means clustering
set.seed(123) # For reproducibility
kmeans_result <- kmeans(data_pca, centers = 2, iter.max = 100, nstart = 100) #WSS starts to level off, which could be around 3 clusters

# Check the results
print(kmeans_result)
print(kmeans_result$size)

# Visualize the clusters
fviz_cluster(kmeans_result, geom = "point", data = data_pca)

# Add the cluster assignments to your dataframe
scaled_data$cluster <- kmeans_result$cluster

# Convert cluster assignments to a factor for modeling
data_for_scaling$cluster <- as.factor(data_for_scaling$cluster)
#------------------------------------------------------------------------------#

