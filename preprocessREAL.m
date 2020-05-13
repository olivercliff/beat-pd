
real_database = './data/REAL-PD/';

label_files = [real_database 'data_labels/REAL-PD_Training_Data_IDs_Labels.csv'];

% Set up some data structures mapping the (hashed) measurement IDs to (numerically indexed) subject IDs
tab = readtable(label_files);

ts_dir = [real_database 'training_data/'];
ts_subdirs = dir([ts_dir 'smart*']);

S = length(tab.measurement_id);

data = repmat(struct('measurement_id','','subject_id',[],'on_off','','dyskinesia','','tremor','',...
                      'xyz',[],'pca',[],'timestamp',[]),S,1);

%% Load/store all TS data
fprintf('Reading %d time series files from %s...\n', ts_dir);
for s = 1:S
  
  fprintf('[%d/%d] adding TS %s', s, S, tab.measurement_id{s});
  
  data(s).measurement_id = tab.measurement_id{s};
  data(s).subject_id = tab.subject_id{s};
  data(s).on_off = tab.on_off{s};
  data(s).dyskinesia = tab.dyskinesia{s};
  data(s).tremor = tab.tremor{s};
  
  % Iterate through all modalities and store the time-series data
  for i = 1:length(ts_subdirs)
    csubdir = ts_subdirs(i).name;
    tsname = [ts_dir csubdir '/' tab.measurement_id{s} '.csv'];
    if exist(tsname,'file')
      ctab = readtable(tsname);
      data(s).timestamp.(csubdir) = ctab.t;
      data(s).xyz.(csubdir) = [ctab.x, ctab.y, ctab.z];
      fprintf(', found %s data (%i)', csubdir, length(data(s).timestamp.(csubdir)));
    else
      data(s).timestamp.(csubdir) = [];
      data(s).xyz.(csubdir) = [];
    end
  end
  fprintf('\n');
end

%% Dimensionality reduction
fprintf('Reducing dimensionality...\n');
for s = 1:S
  flds = fieldnames(data(s).xyz);
  for i = 1:length(flds)
    [~,scores,~,~,explained] = pca(data(s).xyz.(flds{i}));
    data(s).pca.(flds{i}) = scores;
  end
  fprintf('[%d/%d] file %s loaded.\n', s, S, data(s).measurement_id);
end

%% Save data
fprintf('Saving to file...\n');
save([real_database 'REAL-PD_TimeSeries.mat'],'data','-v7.3');
fprintf('Done.\n');