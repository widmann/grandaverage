% pop_grandaverage - Grand average epoched EEGLAB EEG datasets
%
% Usage:
%   >> [EEG, com] = pop_grandaverage(); % pop-up window mode
%   >> [EEG, com] = pop_grandaverage({'dataset1.set' 'dataset2.set' ...
%                       'datasetn.set'}, 'key1', value1, 'key2', ...
%                       value2, 'keyn', valuen);
%   >> [EEG, com] = pop_grandaverage(ALLEEG); % pop-up window mode
%   >> [EEG, com] = pop_grandaverage(ALLEEG, 'key1', value1, 'key2', ...
%                       value2, 'keyn', valuen);
%
% Inputs:
%   ALLEEG        - vector of EEGLAB EEG structures OR cell array of
%                   strings with dataset filenames
%   'datasets'    - vector datasets to average
%
% Optional inputs:
%   'pathname'    - char array path name {default '.'}
%
% Outputs:
%   EEG           - EEGLAB EEG structure
%   com           - history string
%
% Author: Andreas Widmann, University of Leipzig, 2005

%123456789012345678901234567890123456789012345678901234567890123456789012

% Copyright (C) 2005 Andreas Widmann, University of Leipzig, widmann@uni-leipzig.de
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

% $Id$

function [EEG, com] = eeg_grandaverage(ALLEEG, varargin)

EEG = [];
com = '';

% Convert args to struct
args = struct(varargin{:});

if nargin < 1
    % Pop up file selection ui
    [args.filenames args.pathname] = uigetfile('*.set', 'Select datasets -- pop_grandaverage', 'Multiselect', 'on');
    if isnumeric(args.filenames) && args.filenames == 0, return, end
    if ischar(args.filenames)
        args.filenames = {args.filenames};
    end
elseif iscell(ALLEEG)
    args.filenames = ALLEEG;
    clear ALLEEG;
else
    % Pop up dataset selection ui
    if ~isfield(args, 'datasets')
        drawnow;
        uigeom = {[1] [1]};
        uilist = {{'style' 'text' 'string' 'Select datasets:'} ...
                  {'style' 'listbox' 'string' {ALLEEG(:).setname} 'max' length(ALLEEG)}};
        result = inputgui(uigeom, uilist, 'pophelp(''pop_grandaverage'')', 'Grand average loaded datasets -- pop_grandaverage()', [], 'normal', [1 length(ALLEEG)]);
        if length( result ) == 0, return, end

        args.datasets = result{1};
    end
    ALLEEG = ALLEEG(args.datasets);
end

EEG = eeg_emptyset;

% Load datasets
if isfield(args, 'filenames')
    if ~isfield(args, 'pathname')
        args.pathname = '.';
    end
    for file = 1:length(args.filenames)
        ALLEEG(file) = pop_loadset('filename', args.filenames{file}, 'filepath', args.pathname);
    end
end

% Grand average
for dataset = 1:length(ALLEEG)
    EEG.data = cat(3, EEG.data, mean(ALLEEG(dataset).data, 3));
    % Get type from first time locking event
    EEG.event(dataset).type = ALLEEG(dataset).event(find([ALLEEG(dataset).event.latency] == round((0 - ALLEEG(dataset).xmin) * ALLEEG(dataset).srate + 1))).type;
end

% pnts, nbchan, srate, xmin, xmax
for fieldname = {'pnts' 'nbchan' 'srate' 'xmin' 'xmax'}
    EEG.(fieldname{:}) = unique([ALLEEG.(fieldname{:})]);
    if length(EEG.(fieldname{:})) ~= 1
        error(['Field EEG.' fieldname{:} ' not consistent across datasets.']);
    end
end

% ref
EEG.ref = unique({ALLEEG.ref});
if length(EEG.ref) == 1
    EEG.ref = EEG.ref{:};
else
    error(['Field EEG.ref not consistent across datasets.']);
end

% trials
EEG.trials = size(EEG.data, 3);

% chanlocs
chanlocs = cat(1, ALLEEG.chanlocs); 
for chan = 1:EEG.nbchan
    EEG.chanlocs(chan).labels = unique({chanlocs(:, chan).labels});
    if length(EEG.chanlocs(chan).labels) == 1
        EEG.chanlocs(chan).labels = EEG.chanlocs(chan).labels{:};
    else
        error('Structure EEG.chanlocs.labels not consistent across datasets.');
    end
end

% event
tmp = num2cell(round((0 - EEG.xmin) * EEG.srate + 1) + [0:length(EEG.event) - 1] * EEG.pnts);
[EEG.event(:).latency] = deal(tmp{:});
tmp = num2cell([1:length(EEG.event)]);
[EEG.event(:).epoch] = deal(tmp{:});
[EEG.event(:).trials] = deal(ALLEEG.trials);
[EEG.event(:).setname] = deal(ALLEEG.setname);

EEG = eeg_checkset(EEG, 'eventconsistency');

% History string
if isfield(args, 'filenames')
    com = sprintf('EEG = %s({', mfilename);
    for file = 1:length(args.filenames) - 1
        com = [com sprintf('''%s'' ', args.filenames{file})];
    end
    com = [com sprintf('''%s''}', args.filenames{end})];
    args = rmfield(args, 'filenames');
else
    com = sprintf('EEG = %s(ALLEEG', mfilename);
end
for c = fieldnames(args)'
    if ischar(args.(c{:}))
        com = [com sprintf(', ''%s'', ''%s''', c{:}, args.(c{:}))];
    else
        com = [com sprintf(', ''%s'', %s', c{:}, mat2str(args.(c{:})))];
    end
end
com = [com ');'];
