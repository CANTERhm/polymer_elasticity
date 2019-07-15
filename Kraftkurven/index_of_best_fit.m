function index = index_of_best_fit(xvec,yvec,ref_force,peak_num,intervall,tolerance,peak_thresh,varargin)
    % Diese Funktion berechnet den Index des Wertes eines Vektors data, der
    % am nächsten zu dem Wert ref_force liegt 
    
    %%% intervall (index_of_best_fit)
    % intervall ist gewissermaßen die Geschwindigkeit des Algorithmus. Je
    % größer intervall gewählt wird, desto mehr indices werden beim durchsuchen
    % des Data-Vektors übersprungen
    % default: intervall = 1;

    %%% tolerance (index_of_best_fit
    % tolerance bezeichnet die Toleranz, um welchen Faktor dy_next kleiner sein
    % muss als dy_last, damit index_of_best_fit gefunden wurde
    % default: tolerance = 5e-1;
    
    %%% peak_thresh (peakdet)
    % Schwellwert für Peak; Je höher dieser Wert ist, desto klarer muss der
    % Peak aus dem Untergurnd heraus treten
    % default: peak_thresh = 1.5e-1;
    
    p = inputParser;
    addRequired(p,'xvec');
    addRequired(p,'yvec');
    addRequired(p,'ref_force');
    addRequired(p,'peak_num');
    addRequired(p,'intervall');
    addRequired(p,'tolerance');
    addRequired(p,'peak_thresh');
    addParameter(p,'PeakPositions',[]);
    parse(p,xvec,yvec,ref_force,peak_num,intervall,tolerance,peak_thresh,varargin{:});

    % Finde Peaks in angegebenen data-Vektor; siehe Peakdet-Funktion, 
    % für mehr Details
    
    if isempty(p.Results.PeakPositions)
        [~, mintab] = peakdet(yvec,peak_thresh);
        if ~isempty(mintab)
            indices = mintab(:,1);
        end
    else
        mintab = p.Results.PeakPositions;
        indices = zeros(length(mintab(:,1)),1);
        for i = 1:length(mintab(:,1))
            indices(i,1) = find(xvec == mintab(i,1));
        end
    end

    % Anzahl der Peaks in der Kraft-Kurve
    peak_count = size(mintab,1);

    if peak_count ~= 0
        % Prüfe ob gewählter peak innerhalb der peakanzahl liegt
        if peak_num >= peak_count
            peak_num = peak_count;
        elseif strcmp(peak_num,'last') || isnan(peak_num) || peak_num == 0
            peak_num = peak_count;
        elseif peak_num < 0
            error('input argument "peak_num" must be a real positive integer or "last" or 0');
        end

%         % Index des gewählten Peaks im X-Vektor
%         peak_index = mintab(peak_num,1);
%         if ~isinteger(peak_index)
%             peak_index = find(xvec == mintab(peak_num,1));
%         end
        peak_index = indices(peak_num,1);
        
        % Gehe nun den data-Vektor vom Peak aus zurück richtung Null und suche nach
        % dem Index des Wertes, welcher ref_force am nächsten liegt
        last = peak_index; % Wert des vorherigen index
        next = peak_index-intervall; % Wert des nächsten index
        
        dy_last = abs(yvec(last)-ref_force); % Abweichung zur ref_force des vorherigen Index
        dy_next = abs(yvec(next)-ref_force); % Abweichung zur ref_force des nächsten Index
        
        if ~strcmp(ref_force,'rupture')
            while dy_next+dy_next*tolerance < dy_last 
               if next ~= 0
                   % Abweichung des vorherigen index-wertes zur ref_forc
                   dy_last = abs(yvec(last)-ref_force);

                   % Abweichung des nächsten index-wertes zur ref_force
                   dy_next = abs(yvec(next)-ref_force);

                   % Berechnung der nächsten Indices
                   last = last-intervall;
                   next = next-intervall;
               else
                   warning('index_of_best_fit: couldn`t find ref_force >> return NaN')
                   index = NaN;
                   return
               end
            end
        else
            index = peak_index;
            return 
        end % if ~strcmp(ref_force,'rupture')
        index = next;
    else 
        warning('peakdet: couldn`t find a peak >> RETURN NaN');
        index = NaN;
    end % if peak_count ~= 0
end

