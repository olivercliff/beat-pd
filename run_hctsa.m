
subchallenge = 'on_off';
% subchallenge = 'dyskinesia';
% subchallenge = 'tremor';

max_timeseries = 100;

if max_timeseries < 0
  hctsa_matfile = ['CIS-PD-' subchallenge '-all_timeseries.mat'];
else
  hctsa_matfile = sprintf(['CIS-PD-' subchallenge '-%d_timeseries.mat'],max_timeseries);
end

hctsa_dir = '~/Workspace/code/toolkits/hctsa/';

if ~isdir('Calculation')
  addpath ../../utils
  addpath ../moving_average/
  cwd = pwd;
  cd(hctsa_dir);
  startup
  cd(cwd);
end

cis_database = './data/CIS-PD/';

if ~exist(hctsa_matfile,'file')
  fprintf('File %s not found. I''ll make it now.\n', hctsa_matfile);
  
  fprintf('Loading time series data...\n');
  x = load([cis_database 'CIS-PD_TimeSeries.mat']);
  fprintf('Done.\n');

  data = x.data;

  if max_timeseries < 0
    S = length(data);
    ts_set = 1:S;
  else
    S = max_timeseries;
    ts_set = randsample(1:length(data),S);
  end
  

  timeSeriesData = cell(S,1);
  labels = cell(S,1);

  fprintf('Collating time series for HCTSA...\n');
  for s = 1:S
    ts = ts_set(s);
    
    T = size(data(ts).pca,1);

    % Start with relatively short time series (1000x1)
    seq = round(T/2)-499:round(T/2)+500;
    timeSeriesData{s} = data(ts).pca(seq,1);
    labels{s} = data(ts).measurement_id;
  end

  % Which subchallenge are we doing?
  keywords = {data(ts_set).(subchallenge)}';
  fprintf('Done.\n');

  save(hctsa_matfile,'timeSeriesData','keywords','labels','-v7.3');
else
  fprintf('File %s found.\n', hctsa_matfile);
  load(hctsa_matfile);
end

TS_init(hctsa_matfile);
% TS_init(matfile,'INP_mops.txt','INP_ops_1k.txt');

TS_compute;

% Label all time series by whatever the option set is
TS_LabelGroups([],unique(keywords));

% Set how to normalize the data:
whatNormalization = 'zscore'; % 'zscore', 'scaledRobustSigmoid'

% Normalize the data, filtering out features with any special values:
TS_normalize(whatNormalization,[0.5,1],[],true);
% Load data in as a structure:
unnormalizedData = load('HCTSA.mat');
% Load normalized data in a structure:
normalizedData = load('HCTSA_N.mat');

%-------------------------------------------------------------------------------
%% How accurately can day versus night be classified using all features:
whatClassifier = 'svm_linear';
% TS_classify(normalizedData,whatClassifier,'numPCs',0);

TS_classify(normalizedData,whatClassifier,'numPCs',20);

%-------------------------------------------------------------------------------
%% Generate a low-dimensional feature-based representation of the dataset:
numAnnotate = 6; % number of time series to annotate to the plot
whatAlgorithm = 'tSNE';
userSelects = false; % whether the user can click on time series to manually annotate
timeSeriesLength = 600; % length of time-series segments to annotate
annotateParams = struct('n',numAnnotate,'textAnnotation','none',...
                        'userInput',userSelects,'maxL',timeSeriesLength);
TS_PlotLowDim(normalizedData,whatAlgorithm,true,'',annotateParams);