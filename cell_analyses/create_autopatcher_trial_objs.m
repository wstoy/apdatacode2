%% Creating autopatcher_trial files from experimental data
% 4/29/13


%%

%% Directories:
% expDirectory should be where all the experiment... folders are
% folderName is the experiment_XXXX PM_PC folder
% Need to be in /matlabCode for everything to work

clear all
close all

folderLocation = '../Out';

expFolderName = '2013-04-25 in vivo';
folder_prefix = 'experiment';

expDirectory = [folderLocation '/' expFolderName '/'];
mkdir([expDirectory 'combinedAnalysis/']);

%Depth List will be structued like this:
%depthList.folderName = [N x 1] array of expFolderNames (e.g.
%'2013-03-18 in vivo')
% depthList.depths [N x 1] array of electrode depths

%%

load('../combinedAnalysis/all_recorded_trials.mat')

doTrial = 1; % whether the current folder should be parsed. 1 - yes. 0 - no
if isDuplicateDate(expFolderName, all_recorded_trials);
    in = input([expFolderName ' already exists in all_recorded_trials. [skip] or write? '], 's');
    switch in
        case 'write'
            doTrial = 1; % do current trial
        otherwise
            doTrial = 0; % if skip - do not parse current folder.
    end
end

if doTrial
    % List of all trials
    expList = dir([expDirectory '/' folder_prefix '*']);

    trials_w_recordings = {}; % list of objects w/ recordings

    for i = 1:length(expList)
        fileName = [expDirectory 'mat_' expList(i).name];
        folderName = [expDirectory expList(i).name];
        disp(['FOLDER: ' folderName])

        if strcmp(expList(i).name, 'experiment_65444 PM_PC')
            disp('hi')
        end
        [ct, nh, gt, wc, d, res, id, r_file, ct_file, v_of, m_r_files,...
            vc_folders, ic_folders, w_s_folder]...
            = load_experiment_data(expDirectory, expList, i);

        trial = autopatch_trial;
        trial.pipette_resistances = ct;
        trial.hunting_resistances = nh;
        trial.gigaseal_resistances = gt;
        
        trial.date = d;
        trial.outcome = res;
        trial.initDepth = id;
        trial.currentTraceFile = ct_file;
        trial.whisker_recording = r_file;
        trial.breakin_current = wc;
        trial.voltage_offset = v_of;
        trial.memtest_rec_files = m_r_files;
        trial.vclamp_rec_names = vc_folders;
        trial.iclamp_rec_names = ic_folders;
        trial.whisker_stim_folder = w_s_folder;
        
        % set max gigasealing resistance
        setmaxR(trial);
        % Set cell stats
        memtest_setRaRmCmIh(trial) % set stats

        plotResistances(trial)
        plotCurrentTrace(trial)

        % If there is a current clamp recording -> find RMP
        setRMP_fromRecording(trial); % trial, number of samples to average over

        % if either there is a recording file or there is a non-empty whisker
        % stim folder -> whisker recording found
        if ~isempty(r_file) || ~isempty(dir([w_s_folder '/whisker*']))
            disp('rec found')

            setHoldingTime(trial, folderName)

            trials_w_recordings = [trials_w_recordings trial];

            all_recorded_trials = [all_recorded_trials trial];
        end

        save(fileName, 'trial');
        close all
    end

    save('../combinedAnalysis/all_recorded_trials.mat', 'all_recorded_trials')
    save([expDirectory '/recording_db.mat'], 'trials_w_recordings') % list of files that have recordings
end

disp('DONE');