% eeg_param() - Perform basic ERP parametrization operations
%
% Usage:
%   >> amp = eeg_param(EEG);
%   >> [amp lat isLoc] = eeg_param(EEG, 'key1', value1, 'key2', ...
%                                  value2, 'keyn', valuen);
%
% Inputs:
%   EEG       - EEGLAB EEG structure
%
% Optional inputs:
%   'timewin' - line vector time window or matrix time windows with
%               windows in lines {default: epoch length}
%   'param'   - string 'mean', 'min', or 'max' {default: 'mean'}
%
% Outputs:
%   amp       - matrix time window mean/min/max amplitude
%
% Optional outputs:
%   lat       - matrix time window min/max latency
%   isLoc     - logical matrix min/max is local (i.e. not at window
%               borders)
%
% Example:
%   >> [amp lat isLoc] = eeg_param(EEG, [win1start win1end; ...
%                                        win2start win2end], 'min')
%
% Author: Andreas Widmann, University of Leipzig, 2006

%123456789012345678901234567890123456789012345678901234567890123456789012

% Copyright (C) 2006 Andreas Widmann, University of Leipzig, widmann@uni-leipzig.de
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

function [amp lat isLoc] = eeg_param(EEG, varargin)

% Defaults
if nargin < 1
    error('Not enough input arguments.');
end
Arg = struct(varargin{:});

% Time windows
if ~isfield(Arg, 'timewin') || isempty(Arg.timewin)
    Arg.timewin = [EEG.xmin EEG.xmax];
end
pntArray = round(eeg_lat2point(Arg.timewin, ones(size(Arg.timewin)), EEG.srate, [EEG.xmin EEG.xmax]));

% Parametrization
if ~isfield(Arg, 'param') || isempty(Arg.param)
    Arg.param = 'mean';
end


switch Arg.param

    case 'mean'
        if nargout > 1
            error('Too many ouput arguments.')
        end
        amp = zeros(EEG.nbchan, size(Arg.timewin, 1), EEG.trials, class(EEG.data));
        for iWin = 1:size(Arg.timewin, 1)
            amp(:, iWin, :) = mean(EEG.data(:, pntArray(iWin, 1):pntArray(iWin, 2), :), 2);
        end

    case {'min' 'max'}
        func = str2func(Arg.param);
        amp = zeros(EEG.nbchan, size(Arg.timewin, 1), EEG.trials, class(EEG.data));
        lat = zeros(EEG.nbchan, size(Arg.timewin, 1), EEG.trials);
        isLoc = false(EEG.nbchan, size(Arg.timewin, 1), EEG.trials);
        for iWin = 1:size(Arg.timewin, 1)
            [amp(:, iWin, :) lat(:, iWin, :)] = func(EEG.data(:, pntArray(iWin, 1):pntArray(iWin, 2), :), [], 2);
            lat(:, iWin, :) = lat(:, iWin, :) + pntArray(iWin, 1) - 1;
            if nargout > 2
                isLoc(:, iWin, :) = pntArray(iWin, 1) < lat(:, iWin, :) & lat(:, iWin, :) < pntArray(iWin, 2);
            end
        end
        lat = eeg_point2lat(lat, ones(size(lat)), EEG.srate, [EEG.xmin EEG.xmax]);

    otherwise
        error('Unknown parameter.')

end
