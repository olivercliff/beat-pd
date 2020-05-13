%% Configure

use_catch22 = true;
% use_catch22 = false;

parallelize = true;

max_timeseries = -1; % Number of time series to consider
N = 10000; % Length of each time series

dataset = 'REAL-PD';
% modality = '-smartphone_accelerometer';
% modality = '-smartwatch_accelerometer';
modality = '-smartwatch_gyroscope';

% dataset = 'CIS-PD';
% modality = '';

prefix_input = ['./data/' dataset '/' dataset modality];
prefix_output = ['./cluster/' dataset '/' dataset modality];

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

input_filename = sprintf([prefix_input,'%s%s.mat'], ts_str, n_str);

hctsa_dir = '/home/oliver/Workspace/code/toolkits/hctsa/';
if ~exist('TS_compute','file')
  cwd = pwd;
  cd(hctsa_dir);
  startup
  cd(cwd);
end

if ~exist(input_filename,'file')
  error('File %s not found. Run init%s.m.\n', input_filename, dataset(1:end-3));
end
fprintf('File %s found.\n', input_filename);

%% Compute TS features using either HCTSA (slow) or Catch22 (fast)

if use_catch22
    
  load(input_filename);
  S = length(timeSeriesData);
  
  catch22_dir = '/home/oliver/Workspace/code/toolkits/catch22/';
  % Recursively add all paths
  addpath(genpath(catch22_dir));

  features = nan(22,S);
  calc_times = nan(22,S);
  quality = zeros(22,S); % Zero = good

  mytic = tic;
  if parallelize
    parfor s = 1:S
        [features(:,s),calc_times(:,s)] = catch22(timeSeriesData{s});
        elapsed = toc(mytic);
        est = (elapsed/s)*(S-s);
        fprintf('[%i] Catch-22 completed. Time elapsed: %.2f.\n',s,elapsed);
    end
  else
      for s = 1:S
        [features(:,s),calc_times(:,s)] = catch22(timeSeriesData{s});
        elapsed = toc(mytic);
        est = (elapsed/s)*(S-s);
        fprintf('[%i/%d] Catch-22 completed. Time elapsed: %s. Estimated time to completion: %s\n',...
                    s,S,datestr(elapsed/86400, 'HH:MM:SS.FFF'),datestr(est/86400, 'HH:MM:SS.FFF'));
      end
  end
  
  % These ones failed (maybe we stopped it early)
  quality(isnan(features)) = 1;

  output_filename = [prefix_output '-Catch22.mat'];
  
  TS_init(input_filename,'INP_catch22_mops.txt','INP_catch22_ops.txt',1,output_filename);

  TS_LoadFeatures(features',calc_times',quality',output_filename);

else
  output_filename = [prefix_output '-HCTSA.mat'];
    
  TS_init(input_filename,[],[],1,output_filename);

  TS_compute(parallelize,[],[],[],output_filename,1);
end