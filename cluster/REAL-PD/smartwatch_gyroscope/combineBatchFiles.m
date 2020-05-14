hctsa_dir = '~/toolkits/hctsa/'

working_dir = pwd;
cd(hctsa_dir);
startup
cd(working_dir);

files = dir('./');

% Filter out any directory/file starting with '.'
for k = length(files):-1:1
    if strcmp(files(k).name(1),'.')
        files(k) = [];
    end
end

isDirectory = [files.isdir];
directories = files(isDirectory);
directoryNames = {directories.name};
numFiles = length(directoryNames);

saveFile = 'HCTSA_collated.mat';

out = input(sprintf('Save all subsets to %s? y/n [y]',saveFile), 's');

if out == 'n'
	return;
end

% Do the first one
copyfile(fullfile(directoryNames{1},'HCTSA_subset.mat'),saveFile);

for i = 2:numFiles
    newFile = fullfile(directoryNames{i},'HCTSA_subset.mat');
    if ~exist(newFile)
	fprintf('File %s does not exist. Skipping.\n',newFile);
	continue;
    end
    TS_combine(saveFile,newFile,true,false,'HCTSA_combined.mat'); 
    delete(saveFile);
    movefile('HCTSA_combined.mat',saveFile);
end
