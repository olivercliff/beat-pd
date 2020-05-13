%% Configure

max_timeseries = -1; % Number of time series to consider
N = 10000; % Length of each time series

dataset = 'REAL-PD';

% datatype = 'smartphone_accelerometer';
% datatype = 'smartwatch_accelerometer';
datatype = 'smartwatch_gyroscope';

%% Setup

if max_timeseries < 0
  ts_str = '';
else
  ts_str = sprintf('-S%d',max_timeseries);
end

if N < 0
  n_str = '';
else
  n_str = sprintf('-N%d',N);
end

real_database = ['./data/' dataset '/'];
datfile = sprintf([real_database dataset '-' datatype '%s%s.mat'], ts_str, n_str);
HCTSA_file = sprintf([real_database dataset '-' datatype '%s%s-HCTSA.mat'], ts_str, n_str);

hctsa_dir = '/home/oliver/Workspace/code/toolkits/hctsa/';
if ~isdir('Calculation')
  cwd = pwd;
  cd(hctsa_dir);
  startup
  cd(cwd);
end

%% Collate time series data
if ~exist(datfile,'file')
  out = input(['File "' datfile '" not found.\nShall I make it? y/n [n]: '],'s');
  if out ~= 'y'
    return;
  end 
  
  fprintf('Loading time-series data...\n');
  x = load([real_database dataset '_TimeSeries.mat']);
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
  keywords = cell(S,1);

  fprintf('Collating time series for HCTSA...\n');
  for s = 1:S
    ts = ts_set(s);
    
    T = size(data(ts).pca.(datatype),1);
    
    if T == 0
      continue;
    end

    if N > 0 && N < T
      sid = ceil(T/2-N/2);
      seq = sid:sid+N-1;
    else
      seq = 1:T;
    end
    timeSeriesData{s} = data(ts).pca.(datatype)(seq,1);
    labels{s} = data(ts).measurement_id;
    keywords{s} = sprintf('on_off:%s,dyskinesia:%s,tremor:%s',data(s).on_off,data(s).dyskinesia,data(s).tremor);
  end
  
  ids = ~cellfun(@isempty,timeSeriesData);
  timeSeriesData = timeSeriesData(ids);
  labels = labels(ids);
  keywords = keywords(ids);
  fprintf('Done.\n');

  save(datfile,'timeSeriesData','keywords','labels','-v7.3');
else
  out = input(['File ' datfile ' found. Shall I load it? y/n [n]: '],'s');
  if out ~= 'y'
    return;
  end
  load(datfile);
  S = length(timeSeriesData);
end

out = input(['Initialise HCTSA (for cluster) [filename: ' HCTSA_file ']? y/n [n]: '],'s');
if out == 'y'
  TS_init(datfile,[],[],0,HCTSA_file);
end