function predictPhenotype(subchallenge,dataset,modality,can_override)
% Predict phenotypes (subchallenges) using a precomputed classifier MAT-file

%% Configure

parallelize = false;

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

N = 10000; % Should probably grab this from a sample TS but oh well..

%% Setup

hctsa_dir = '/home/oliver/Workspace/code/toolkits/hctsa/';
if ~exist('TS_compute','file')
  cwd = pwd;
  cd(hctsa_dir);
  startup
  cd(cwd);
end

prefix = [dataset modality '-' subchallenge '_'];
classifier_file = ['./cluster/' dataset '/' prefix 'classifier.mat'];
predictions_file = ['./cluster/' dataset '/' prefix 'predictions.mat'];

test_database = ['./data/' dataset '/'];

ts_dir = [test_database 'testing_data/'];

if ~isempty(modality)
    ts_dir = [ts_dir modality(2:end) '/'];
end

ts_csvs = dir([ts_dir '*.csv']);

output_csv = ['./submission/' prefix 'predictions.csv'];

S = length(ts_csvs);

%% Predict labels

ts_data = cell(S,1);
measurement_ids = cell(S,1);

out = 'y';
if exist(predictions_file,'file')
    if can_override
        out = input(sprintf('File %s already exists - override? [y/n] ',predictions_file),'s');
    else
        out = 'n';
    end
end

if out == 'y'
    fprintf('Loading time-series data...\n');
    for s = 1:S
      ccsv = ts_csvs(s).name;
      ctab = readtable([ts_dir ccsv]);

      if any(contains(ctab.Properties.VariableNames,'X'))
          xyz = [ctab.X, ctab.Y, ctab.Z];
      else
          xyz = [ctab.x, ctab.y, ctab.z];
      end
      [~,scores] = pca(xyz);

      T = size(scores,1);

      if N > 0 && N < T
          sid = ceil(T/2-N/2);
          seq = sid:sid+N-1;
      else
          seq = 1:T;
      end

      measurement_ids{s} = ts_csvs(s).name(1:end-4);
      ts_data{s} = scores(seq,1);
      fprintf('[%d/%d] %s (%i) loaded.\n', s, S, measurement_ids{s}, length(ts_data{s}));
    end
else
    x = load(predictions_file);
    ts_data = x.TimeSeries.Data;
    measurement_ids = x.TimeSeries.Name;
end

[tab,acc] = TS_predict(ts_data,measurement_ids,classifier_file,...
                    'predictionFilename',predictions_file,...
                    'classifierType','topFeature',...
                    'isParallel',parallelize);

output_tab = table(tab.labels,tab.predictGroups-1,acc.*ones(height(tab),1),'VariableNames',{'measurement_id','prediction','accuracy'});

fprintf('Saving predictions to %s...\n', output_csv);
writetable(output_tab,output_csv);
fprintf('Done.\n');