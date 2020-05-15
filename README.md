# Sydney Neurophysics BEAT-PD DREAM Challenge Entry

Oliver M. Cliff and Ben D. Fulcher
School of Physics, University of Sydney

## Before starting

**Get the toolkits and data**

1. Clone my forks of the [_hctsa_](https://github.com/olivercliff/hctsa) and [_catch22_](https://github.com/olivercliff/catch22).
2. Download the data, see [Accessing the Data](https://www.synapse.org/#!Synapse:syn20825169/wiki/600903).
3. Organise the data: place testing files in *data/CIS-PD/testing_data* and *data/REAL-PD/testing_data*

If only making predictions, you can stop here and just call `predictAllPhenotypes.m` to and `makeSubmissionCSVs.m`. If you want to (re-)learn the features, see below.

**Running _hctsa_**

*Before running any code, make sure all paths are set correctly.*

1. Run `preprocessCIS.m` and `preprocessREAL.m` for iterating through all CSV files and extracting them into `.mat` files (make sure you check options).
2. Run `initCIS.m` and `initREAL.m` to initialise _hctsa_ files (make sure you check options).
3. If using a cluster, there is some useful code in the *cluster* subfolder.
4. Else you can use `runhctsaLocal.m` to with either the _catch22_ code or the full _hctsa_ (see options).
5. Run `trainClassifier.m` (or `trainAllClassifiers.m`) to get the classifiers for each dataset and sensor.
6. See above for making predictions.

## Challenge Overview

### Summary Sentence

Our method was to use [_hctsa_](https://github.com/benfulcher/hctsa), a toolkit for running highly-comparative time-series analysis, to detect discriminative features and build classifiers for each dataset (REAL-PD/CIS-PD) and modality (accelerometer/gyro).

### Background/Introduction

_hctsa_ is a software package for running highly comparative time-series analysis using Matlab. The software provides a code framework that enables the extraction of thousands of diverse time-series features from a time series (or time-series dataset). It also provides a range of tools for visualizing and analyzing the resulting time-series feature matrix, including:

* Normalizing and clustering the data,
* Producing low-dimensional representations of the data,
* Identifying and interpreting discriminating features between different classes of time series,
* Learning multivariate classification models.

By first reducing the dimensionality of the time-series data to univariate measurements, we were able to use the suite of normalization tools and classifiers in this toolkit to detect important features. The best-performing classifier was then used for prediction of the testing data.

### Methods

Our high-level approach is as follows (more detail below):
1. Reduce the 3-dimensional time-series dataset to a single time series through PCA,
2. Reduce the length of the time series to 10000 samples,
3. Compute all features from a selected feature ensemble (either _hctsa_ or _catch22_),
4. Build classifiers for each feature, and the joint (multivariate) set of features,
5. Predict the class for every input time series with the best classifier,
6. Collate all predictions, using only the best classifier if there is overlap.

_hctsa_ operates on univariate time-series data, so we first reduce the multivariate time-series data (e.g., the XYZ axes of accelerometers) to a single time series. For this we chose to use principal component analysis (PCA) and take the first principle component as a representative univariate time series for each measurement.

hctsa provides a rich set of time-series features for each of the thousands of training data from both datasets (CIS-PD/REAL-PD) and modalities (gyroscope/accelerometer from both smartphone/smartwatch). However, computing all 7700 time series is quite time-consuming, especially for the lengthy datasets provided (with >50000 samples). So, for each time series, we reduced the length to more manageable (10000) samples by taking the 5000 time indices before, and 5000 time indices after, the middle index.

Now, even with the reduced time-series length of ~10000 samples, computing all 7700 measures remains computationally expensive. To perform the computation for the CIS-PD dataset, we were able to use the high-performance computing cluster in the School of Physics, The University of Sydney, by submitting jobs of five times series at a time and re-combining all features into a larger feature-set. Unfortunately, due to the time constraints (i.e., us coming into the competition late), we could not do this same procedure for the REAL-PD dataset. Instead, this was achieved by using [catch22](https://github.com/chlubba/catch22), the CAnonical Time-series CHaracteristics toolkit, which is a collection of 22 (canonical) _hctsa_ time-series features coded in C.

Following these procedures, we had stored many thousands of features for each dataset and modality. Our next step was to normalize (_z_-score) the features matrices, and remove any features or time series that were not computed (this is most features for the REAL-PD dataset, since _catch22_ was used). Following normalization, we learned a joint classifier (all available features to the phenotype) and individual classifiers for each feature. The top feature classifiers *always* performed better than the joint feature classifier, so this was used. Using this approach gives us the individual time-series feature that was computed by either _hctsa_ or _catch22_ that is the most discriminative for the training data, and this feature could be different for every dataset and modality.

By using these optimal classifiers, we can make predictions of the test data for every dataset and modality. Then, to produce the CSV submission, we simply iterate through every prediction, and, if there are multiple modalities for one time series, we use the best classifier (i.e., feature) as earlier recorded.

>The version of hctsa toolkit, [currently accessible on GitHub](https://github.com/benfulcher/hctsa), does not yet have the functionality to predict unseen data---the features are stored but the classifier are not. As a work-around, we modified the current version of the code to facilitate storing the classifiers and predicting the classes (*keywords*, in hctsa-speak) of unseen time series. This is currently only available on our project webpage, and not in the repository.

### Conclusion/Discussion

The time-series analysis techniques that were selected in the end were different for every dataset and modality, and performed statistically better than chance, however not by a substantial margin. Moreover, surprisingly, the joint ensemble of all features did not perform as well as individual high-performing features.
Our reported balanced classification accuracy (balanced for non-uniform class distribution, using _hctsa_) for the training data was as follows:

**CIS-PD**
- OnOff: **25%** for **5 classes** with **feature** : *false-nearest neighbors statistic*
- Dyskinesia: **36.4%** for **5 classes** with **feature**: *scale-dependent estimates of multifractal scaling in a time series.*
- Tremor: **34.7%** for **5 classes** with **feature**: *change of transition probabilities change with alphabet size*

**REAL-PD**, *smartphone accelerometer*
- OnOff: **57.8%** for **2 classes** with **feature**: *heart rate variability (HRV) statistics.*
- Dyskinesia: **48%** for **3 classes** with **feature**: *simple local time-series forecasting.*
- Tremor: **39.9%** for **3 classes** with **feature**: *heart rate variability (HRV) statistics.*

**REAL-PD**, *smartwatch accelerometer*
- OnOff: **55.7%** for **2 classes** with **feature** : *motifs in a coarse-graining of a time series to a 3-letter alphabet*
- Dyskinesia: **47.2%** for **3 classes** with **feature**: *first minimum sample autocorrelation*
- Tremor: **32.6%** for **4 classes** with **feature**: *first sample autocorrelation to drop below 1/e*

**REAL-PD**, *smartwatch gyroscope*
- OnOff: **57.6%** for **2 classes** with **feature**: *motifs in a coarse-graining of a time series to a 3-letter alphabet*
- Dyskinesia: **42.1%** for **3 classes** with **feature**: *motifs in a coarse-graining of a time series to a 3-letter alphabet*
- Tremor: **34.3%** for **4 classes** with **feature**: *mode of a data vector with 10 bins*

Interestingly, each classifier for the CIS-PD dataset chose only classes 0 and 4 for every time series. This appears to suggest that the intermediate phenotypes are much more difficult to classify.

We assume this method needs some more preprocessing of the time series in order to obtain meaningfully predictive classifiers.

### References

* BEAT-PD DREAM Challenge (syn20825169)
* B.D. Fulcher and N.S. Jones. hctsa: A computational framework for automated time-series phenotyping using massive feature extraction. Cell Systems 5, 527 (2017).
* B.D. Fulcher, M.A. Little, N.S. Jones. Highly comparative time-series analysis: the empirical structure of time series and their methods. J. Roy. Soc. Interface 10, 83 (2013).
* C.H. Lubba, S.S. Sethi, P. Knaute, S.R. Schultz, B.D. Fulcher, N.S. Jones. catch22: CAnonical Time-series CHaracteristics. Data Mining and Knowledge Discovery (2019).

### Authors Statement
OC wrote the code and Wiki; BF advised.
