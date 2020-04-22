
cis_database = './data/CIS-PD/';

label_files = [cis_database 'data_labels/CIS-PD_Training_Data_IDs_Labels.csv'];

% Set up some data structures mapping the (hashed) measurement IDs to (numerically indexed) subject IDs
tab = readtable(label_files);

ts_dir = [cis_database '/training_data/'];
ts_csvs = dir([ts_dir '*.csv']);

S = length(ts_csvs);

data = repmat(struct('measurement_id','','subject_id',[],'on_off','','dyskinesia','','tremor','',...
                      'xyz',[],'pca',[],'timestamp',[]),S,1);

fprintf('Reading %d time series files from %s...\n', ts_dir);
for i = 1:S
  ccsv = ts_csvs(i).name;
  ctab = readtable([ts_dir ccsv]);
  
  data(i).measurement_id = ccsv(1:end-4);
  id = find(strcmp(tab.measurement_id,data(i).measurement_id));
  
  data(i).subject_id = tab.subject_id(id);
  data(i).on_off = tab.on_off{id};
  data(i).dyskinesia = tab.dyskinesia{id};
  data(i).tremor = tab.tremor{id};
  data(i).timestamp = ctab.Timestamp;
  data(i).xyz = [ctab.X, ctab.Y, ctab.Z];
  fprintf('[%d/%d] file %s loaded.\n', i, S, ccsv);
end

for i = 1:S
  [~,scores,~,~,explained] = pca(data(i).xyz);
  data(i).pca = scores;
end

fprintf('Saving to file...\n');
save([cis_database 'CIS-PD_TimeSeries.mat'],'data','-v7.3');
fprintf('Done.\n');