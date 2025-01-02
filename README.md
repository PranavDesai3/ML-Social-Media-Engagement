# Decoding User Dynamics: Leveraging Machine Learning for Strategic Insights in Social Media Engagement

## Table of Contents
1. [Introduction](#introduction)
2. [Features](#features)
3. [Installation](#installation)
4. [Usage](#usage)
5. [Methodologies](#methodologies)
   - [Unsupervised Learning](#unsupervised-learning)
   - [Supervised Learning](#supervised-learning)
6. [Results](#results)
7. [Screenshots and Visualizations](#screenshots-and-visualizations)
8. [Limitations](#limitations)
9. [Future Enhancements](#future-enhancements)
10. [Contributing](#contributing)

---

## Introduction
This project analyzes user engagement on a social media platform using advanced machine learning techniques. By employing clustering and supervised learning methods, we categorize users into distinct groups based on their behaviors and propose actionable insights for improving engagement.

## Features
- Exploratory Data Analysis to understand user behavior.
- Dimensionality reduction using Principal Component Analysis (PCA).
- Clustering using K-Means to identify user groups.
- Classification with K-Nearest Neighbors (KNN) to predict user engagement categories.
- Comprehensive evaluation metrics to assess model performance.

## Installation
1. Clone this repository:
git clone https://github.com/PranavDesai3/ML-Social-Media-Engagement.git
2. Navigate to the project directory:
cd ML-Social-Media-Engagement
3. Install the necessary R packages:
install.packages(c("ggplot2", "dplyr", "caret", "factoextra", "mlr3", "mlr3verse", "mlr3learners", "cluster", "corrplot"))

## Usage
1. Place your dataset in the data folder with the name Data_DMML.csv.
2. Run the R script:
source('clustering_and_supervised_modelling.R')
3. View results in the console or generated plots.

## Methodologies
Unsupervised Learning
  1. Clustering Technique: K-Means
  2. Feature Engineering: Combined correlated attributes (InDegree, OutDegree, TotalPosts) into a single metric: SocialMediaActivityIndex.
  3. Optimal Clusters: Determined using Elbow and Silhouette methods.

Supervised Learning
  1. Classification Model: K-Nearest Neighbors (KNN)
  2. Evaluation Metrics: Accuracy, Precision, Recall, F1 Score, and Specificity.

## Results
Identified three user clusters:
  1. Highly Engaged Content Creators
  2. Inquisitive Networkers
  3.   Casual Participants
KNN classifier achieved high accuracy (92%) with the optimal k=10.

## Limitations
  1. Sensitivity to outliers in clustering.
  2. Computational expense of KNN on large datasets.
  3. Lack of demographic and temporal data for deeper insights.

## Future Enhancements
  1. Integrate additional features like demographics and time-series data.
  2. Explore advanced clustering techniques like DBSCAN for non-spherical clusters.
  3. Optimize KNN performance using faster distance computation methods.

## Contributing
We welcome contributions! Please follow these steps:
  1. Fork the repository.
  2. Create a new branch for your feature:
      -git checkout -b feature-name
  3. Commit your changes:
      -git commit -m "Add feature-name"
  4. Push to your branch:
      -git push origin feature-name
  5. Create a pull request.




