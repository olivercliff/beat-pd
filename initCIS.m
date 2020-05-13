%% Configure

max_timeseries = -1; % Number of time series to consider
N = 10000; % Length of each time series

dataset = 'CIS-PD';

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

datfile = sprintf([dataset ,'%s%s.mat'], ts_str, n_str);

if ~exist('TS_compute','file')
  fprintf('Run startup.m from HCTSA directory.\n');
  return;
end

cis_database = ['./data/' dataset '/'];

%% Collate time series data
if ~exist(datfile,'file')
  fprintf('File %s not found. I''ll make it now.\n', datfile);
  
  fprintf('Loading time-series data...\n');
  x = load([cis_database dataset '_TimeSeries.mat']);
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
    
    T = size(data(ts).pca,1);

    if N > 0 && N < T
      sid = ceil(T/2-N/2);
      seq = sid:sid+N-1;
    else
      seq = 1:T;
    end
    timeSeriesData{s} = data(ts).pca(seq,1);
    labels{s} = data(ts).measurement_id;
    keywords{s} = sprintf('on_off:%s,dyskinesia:%s,tremor:%s',data(s).on_off,data(s).dyskinesia,data(s).tremor);
  end
  fprintf('Done.\n');

  save(datfile,'timeSeriesData','keywords','labels','-v7.3');
else
  fprintf('File %s found.\n', datfile);
  load(datfile);
  S = length(timeSeriesData);
end

out = input('Initialise HCTSA.mat (for cluster)? y/n [n]:','s');
if out == 'y'
  TS_init(datfile);
end