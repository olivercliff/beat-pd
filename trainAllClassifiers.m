clear

datasets = {'REAL-PD','CIS-PD'};
modality{1} = {'-smartphone_accelerometer',...
                 '-smartwatch_accelerometer',...
                 '-smartwatch_gyroscope'};

modality{2} = {''};

subchallenges = {'on_off','dyskinesia','tremor'};

for s = 1:length(subchallenges)
    csub = subchallenges{s};
    for d = 1:length(datasets)
        cdatset = datasets{d};
        for m = 1:length(modality{d})
            cmod = modality{d}{m};
            fprintf('Training classifiers for dataset:%s, modality:%s, subchallenge:%s...\n',...
                        cdatset, cmod, csub);
                        
            trainClassifier(csub,cdatset,cmod,false);
            fprintf('Done.\n');
        end
    end
end