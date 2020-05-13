function trainClassifier(subchallenge,dataset,modality,can_override)
% Run classifier using a precomputed HCTSA MAT-file

%% Configure

subchallenges = {'on_off','dyskinesia','tremor'};

datasets = {'CIS-PD','REAL-PD'};

modalities = {'',...
                '-smartphone_accelerometer',...
                '-smartwatch_accelerometer',...
                '-smartwatch_gyroscope' };

if nargin < 4
    can_override = true;
    if nargin < 3
        modality = '';
        if nargin < 2
            dataset = 'CIS-PD';
            if nargin < 1
                subchallenge = 'on_off';
            end
        end
    end
end

assert(any(contains(subchallenges,subchallenge)));
assert(any(contains(datasets,dataset)));
assert(any(contains(modalities,modality)));

%% Setup

subdir = ['./cluster/' dataset '/'];
input_prefix = [subdir dataset modality '_'];
prefix = [subdir dataset modality '-' subchallenge '_'];

classifier_filename = [prefix 'classifier.mat'];

if exist(classifier_filename,'file')
    fprintf('File %s already exists',classifier_filename);
    if can_override
        out = input(' -- override? [y/n] ','s');
        if out ~= 'y'
            return;
        end
    else
        fprintf('. Parameter set to no override allowed. Exiting.\n');
        return;
    end
end

copyfile([input_prefix 'HCTSA.mat'], [prefix 'HCTSA.mat']);

use_na = false;

hctsa_dir = '/home/oliver/Workspace/code/toolkits/hctsa/';
if ~exist('TS_compute','file')
  cwd = pwd;
  cd(hctsa_dir);
  startup
  cd(cwd);
end

% Label all time series by whatever the option set is
matfile = [prefix 'HCTSA.mat'];

x = load(matfile);

groups = cell(6,1);
foundGps = true(5,1);
for i = 0:4
  groups{i+1} = sprintf('%s:%i',subchallenge,i);
  if ~any(contains(x.TimeSeries.Keywords,groups{i+1}))
      foundGps(i+1) = false;
  end
end
groups{end} = [subchallenge ':NA'];

if ~use_na
  groups = groups(1:end-1);
end

groups = groups(foundGps);

%% For classification

contains(x.TimeSeries.Keywords,groups);

TS_LabelGroups(matfile,groups,true,true);

% Set how to normalize the data:
whatNormalization = 'zscore'; % 'zscore', 'scaledRobustSigmoid'
if exist([matfile(1:end-4) '_filtered.mat'],'file')
    matfile = [matfile(1:end-4) '_filtered.mat'];
end

% Normalize the data, filtering out features with any special values:
TS_normalize(whatNormalization,[0.1,1],matfile,true);
if exist([matfile(1:end-4) '_N.mat'],'file')
    matfile = [matfile(1:end-4) '_N.mat'];
end

% Load normalized data in a structure:
normalizedData = load(matfile);

%-------------------------------------------------------------------------------
%% How accurately can we classify the states:

whatClassifier = 'svm_linear';
TS_classify(normalizedData,whatClassifier,'numPCs',0,'numNulls',0,...
                'classifierFilename',classifier_filename,'numFolds',2);

% %-------------------------------------------------------------------------------
% %% Generate a low-dimensional feature-based representation of the dataset:
% 
% numAnnotate = 6; % number of time series to annotate to the plot
% whatAlgorithm = 'pca';
% userSelects = false; % whether the user can click on time series to manually annotate
% timeSeriesLength = 300; % length of time-series segments to annotate
% 
% annotateParams = struct('n',numAnnotate,'textAnnotation','none',...
%                         'userInput',userSelects,'maxL',timeSeriesLength);
%                       
% TS_PlotLowDim(normalizedData,whatAlgorithm,true,'',annotateParams);

%-------------------------------------------------------------------------------
%% What individual features best discriminate the phenotypes
% Uses a linear classication accuracy between classes 
% Produces 1) a pairwise correlation plot between the top features
%          2) class distributions of the top features, with their stats
%          3) a histogram of the accuracy of all features

numFeatures = 40; % number of features to include in the pairwise correlation plot
numFeaturesDistr = 32; % number of features to show class distributions for
whatStatistic = 'fast_linear'; % classification statistic

TS_TopFeatures(normalizedData,whatStatistic,'numFeatures',numFeatures,...
                'numFeaturesDistr',numFeaturesDistr,...
                'whatPlots',{'histogram','distributions','cluster'},...
                'classifierFilename',classifier_filename);