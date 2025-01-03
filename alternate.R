#------- install necessary packages and load libraries ------------------------#
library(ggplot2)
library(Hmisc)
library(tidyverse)
library(dplyr)
library(caret)
library(factoextra)
library(cluster)
library(reshape2)
library(skimr)
library(mlr3)
library(mlr3verse)
library(kknn)
library(mlr3learners)
library(randomForest)
#------------------------------------------------------------------------------#

#--------------------- Data Evaluation ----------------------------------------#
#reading the data from file
data <- read.csv('Data_DMML.csv')

Hmisc::describe(data)
#We can observe from the summary generated by above function that there are no missing values in any of the attributes.
#MeanWordCount attributes shows a lot of high values which are very well seperated from each other (1234    1271.33 1828    2008    3118) in the highest category which could indicate that some users might be more more verbal with their posts. It could also mean that the user might have less number of posts but uploaded those with a long captions that inceased the MeanWordCount. We could potentially remove these outliers when clustering. 
#PercentQuestions and PercentURLs - from the definition of it, it looks like this attributes provides little to no information that is relevant to the users activity. We might think of ignoring these during clustering

cor_mat <- cor(data)

corrplot::corrplot(cor_mat, method = 'ellipse', type = 'upper')
#There is high correlation between InDegree, OutDegree and TotalPosts attributes.
#The high correlation between these 3 attributes can pose an issue when forming the clusters
#Hence we will combine these 3 into one single attribute called 'SocialMediaActivityIndex'.
#Since all 3 parameters are of almost equal importance we cannot give them different individual weightage.
#We will assign 33% weightage to each InDegree and OutDegree attribute and the remaining 34% to the TotalPost attribute.

# Calculate the 99th percentile for the specified variables
p99_WordCount <- quantile(data$MeanWordCount, 0.99)
p99_PostsPerThread <- quantile(data$MeanPostsPerThread, 0.99)
p99_PostsPerSubForum <- quantile(data$MeanPostsPerSubForum, 0.99)

# Remove rows based on the 99th percentile threshold for all specified attributes
data <- data %>%
  filter(MeanWordCount <= p99_WordCount,
         MeanPostsPerThread <= p99_PostsPerThread,
         MeanPostsPerSubForum <= p99_PostsPerSubForum)

Hmisc::describe(data)
#------------------------------------------------------------------------------#

#---------------------- Data Transformation -----------------------------------#
#Creating combined feature
data_for_clustering <- data %>%
  mutate(NetworkActivityIndex = (0.20 * data[, "InDegree"] + 
                                   0.20 * data[, "OutDegree"] + 
                                   0.20 * data[, "TotalPosts"] +
                                   0.20 * data[,"LikeRate"] +
                                   0.20 * data[, "AccountAge"])) %>%
  mutate(InteractionStyle = (0.5 * data[, "PercentQuestions"] +
                              0.5 * data[, "InitiationRatio"])) %>%
  mutate(DiscussionDominance = (0.33 * data[, "MeanPostsPerThread"] +
                                  0.33 * data[, "MeanPostsPerSubForum"] +
                                  0.34 * data[, "MeanWordCount"])) %>%
  select(-InDegree, -OutDegree, -TotalPosts, -ID, -PercentQuestions, -InitiationRatio, -MeanWordCount, -LikeRate, -MeanPostsPerThread, -MeanPostsPerSubForum, -AccountAge)

Hmisc::describe(data_for_clustering)
cor_mat <- cor(data_for_clustering)
corrplot::corrplot(cor_mat, method = 'ellipse', type = 'upper')
#------------------------------------------------------------------------------#

#---------- Standardising data for clustering ---------------------------------#
# Prepare the data for scaling (excluding the ID column)

scaled_data <- scale(data_for_clustering)
Hmisc::describe(scaled_data)

#------------------------------------------------------------------------------#

#-------------- PCA -----------------------------------------------------------#
# Perform PCA
pca_result <- prcomp(scaled_data, center = TRUE, scale. = FALSE)

# Determine the number of principal components to retain
# This can be done using a scree plot
fviz_eig(pca_result)

# Assuming we decide to retain '4' components, use them for K-means clustering
# Extract the principal components
data_pca <- as.data.frame(pca_result$x[, 1:4])
#------------------ Finding Optimal number of clusters ------------------------#
# Determine the optimal number of clusters using the elbow method
set.seed(123) # For reproducibility

fviz_nbclust(scaled_data, kmeans, method = "wss")
fviz_nbclust(scaled_data, kmeans, method = "silhouette")

#------------------------------------------------------------------------------#

#-------------------- Running K-Means -----------------------------------------#
# Run K-means clustering
set.seed(123) # For reproducibility
kmeans_result_two_clusters <- kmeans(scaled_data, centers =4, nstart = 50, iter.max = 100) #Silhouette suggests 2 as the optimal number of clusters


kmeans_result_three_clusters <- kmeans(scaled_data, centers =5, nstart = 50, iter.max = 100) #WSS starts to level off, which could be around 3 clusters

# Check the results for 2 clusters scenario
print(kmeans_result_two_clusters)
print(kmeans_result_two_clusters$size)

#check the results for 3 clusters scenario
print(kmeans_result_three_clusters)
print(kmeans_result_three_clusters$size)

# Visualize the clusters for 2 cluster scenario
fviz_cluster(kmeans_result_two_clusters, geom = "point", data = scaled_data)

# Visualize the clusters for 3 cluster scenario
fviz_cluster(kmeans_result_three_clusters, geom = "point", data = scaled_data)


#Based on what you choose to keep, add the cluster result of that to the data.

# Add the cluster assignments to your dataframe
data$cluster <- kmeans_result$cluster
data_for_clustering$cluster <- kmeans_result$cluster

# Convert cluster assignments to a factor for modeling
data$cluster <- as.factor(data$cluster)
data_for_clustering$cluster <- as.factor(data_for_clustering$cluster)

#----------------- Result Evaluation ------------------------------------------#

sil_scores <- silhouette(kmeans_result_two_clusters$cluster, dist(data_for_clustering))
mean_silhouette_score <- mean(sil_scores[, "sil_width"])
fviz_silhouette(sil_scores)
# Summary of silhouette analysis
si.sum <- summary(sil_scores)
# Average silhouette width of each cluster
si.sum$clus.avg.widths


# Objects with negative silhouette
neg_sil_index <- which(sil_scores[, 'sil_width'] < 0)
sil_scores[neg_sil_index, , drop = FALSE]

#------------------------------------------------------------------------------#
Hmisc::describe(data)
aggregate(data = data_for_clustering, LikeRate ~ cluster, mean)
aggregate(data = data_for_clustering, NetworkActivityIndex ~ cluster, mean)
aggregate(data = data_for_clustering, AccountAge ~ cluster, mean)

#------------------------------------------------------------------------------#
centers <- melt(data.frame(cluster = 
                             rownames(kmeans_result$centers), kmeans_result$centers))
centers

#------------------------------------------------------------------------------#

ggplot(centers, aes(x = reorder(variable, value), y = value)) +
  geom_bar(aes(fill = value > 0), width=0.8, stat = "identity") +
  facet_wrap(~ cluster, nrow=1) +
  coord_flip() +
  theme_bw() +
  theme(panel.border = element_rect(colour = "black", fill=NA), 
        legend.position="none") +
  labs(x = NULL)
#------------------------------------------------------------------------------#
#Visualize clusters within convex space
fviz_cluster(kmeans_result, data = scaled_data, 
             ellipse.type = "convex", palette = "jco", 
             ggtheme = theme_minimal())

#------------------------------------------------------------------------------#
ggplot(data_for_clustering, aes(NetworkActivityIndex,AccountAge)) +
  geom_point(aes(color = as.factor(cluster)))+
  geom_smooth(method = "lm")+
  labs(y = "Age of the user acount in months", x="User's Social Media Activity", title = "Social Media Activity VS Age of User Account", color = "cluster")

#------------------------------------------------------------------------------#

#---------------------- Random Forest -----------------------------------------#
# Preparing data
set.seed(123)  # For reproducibility
training_indices <- createDataPartition(data$cluster, p = .8, list = FALSE)
training_data <- data[training_indices, ]
testing_data <- data[-training_indices, ]

# Training the Random Forest model
rf_model <- randomForest(cluster ~ ., data=training_data, ntree=500, mtry=2, importance=TRUE)

# Predicting and evaluating the model
predictions <- predict(rf_model, testing_data)
confusionMatrix(predictions, testing_data$cluster)

# Feature importance
importance(rf_model)

#------------------------------------------------------------------------------#

#--------------------- MLR3: KNN ----------------------------------------------#

data$cluster <- as.factor(data$cluster) #making sure this is a factor for our prediction

#lets create our task, using iris, and setting our target as Species
task <- as_task_classif(data,
                        target='cluster') 

task # it is always good to print this and check it, is this what we want


#make sure to look - is Species in the TARGET or feature list
#make sure it is in the TARGET 

set.seed(123) #critical, never forget to do this
#as if you dont, each time you run this, you'll get diff train/test splits
train_set = sample(task$row_ids, 0.7 * task$nrow)
test_set = setdiff(task$row_ids, train_set)

#lets choose our learner - knn
learner = lrn("classif.kknn")
learner #again print this, and check

# note, it picked k=7 for us, we can change this in the learner

learner = lrn("classif.kknn", k=19)
learner #you can see k has changed and this is the one we'll use 

# training
learner$train(task, row_ids = train_set)

#lets use the model to predict (training set!!)
pred_train = learner$predict(task, row_ids=train_set) # predicting 
pred_train$confusion #print the conf matrix

measures = msrs(c('classif.acc', 'classif.ce')) #accuracy and class error
pred_train$score(measures) #print the scores 

# use the model to predict on the TEST dataset 
pred_test = learner$predict(task, row_ids=test_set) #predicting
pred_test$confusion #get the confusion matrix 

measures = msrs(c('classif.acc', 'classif.ce')) #acc and error
pred_test$score(measures) #print 
