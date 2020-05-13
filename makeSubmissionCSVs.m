% Make CSVs for submitting the challenge

clear

parallelize = false;
    
datasets = {'REAL-PD','CIS-PD'};
modality{1} = {'-smartphone_accelerometer',...
                 '-smartwatch_accelerometer',...
                 '-smartwatch_gyroscope'};

modality{2} = {''};

subchallenge = {'on_off','dyskinesia','tremor'};
synapse_wording = {'OnOff','Dyskinesia','Tremor'};

for s = 1:length(subchallenge)
    
    csc = subchallenge{s};
    
    submission_template = sprintf('BEAT-PD_SC%i_%s_Submission_Template.csv',...
                                    s, synapse_wording{s});
                                
    our_submission_file = sprintf('BEAT-PD_SC%i_%s_Submission_SydneyNeurophysics.csv',...
                                    s, synapse_wording{s});
    
    template_tab = readtable(['./submission/' submission_template]);
    predictions_tab = template_tab;
    
    accuracy = zeros(height(predictions_tab),1);

    for d = 1:length(datasets)
        cdatset = datasets{d};
        for m = 1:length(modality{d})
            cmod = modality{d}{m};
            
            pred_file = sprintf('./submission/%s%s-%s_predictions.csv',cdatset,cmod,csc);
            
            ctab = readtable(pred_file,'delimiter',',');
            
            in_ids = false(height(ctab),1);
            out_ids = false(height(predictions_tab),1);
            for i = 1:height(ctab)
                id = contains(template_tab.measurement_id,ctab.measurement_id{i});
                
                if any(id) && ctab.accuracy(i) > accuracy(id)
                    in_ids(i) = true;
                    out_ids(id) = true;
                    accuracy(id) = ctab.accuracy(i);
                end
            end
            
            predictions_tab.prediction(out_ids) = cellstr(num2str(ctab.prediction(in_ids)));

            nan_left = sum(contains(predictions_tab.prediction,'NA'));
            fprintf('Added %d predictions from %s (%i predictions remaining)\n',sum(in_ids),pred_file, nan_left);
        end
    end
    
    fprintf('Done. Subchallenge %s contains %i NaN values.\n', csc, nan_left);
    
    writetable(predictions_tab,['./submission/' our_submission_file]);
end