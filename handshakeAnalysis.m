%% Initialize variables.
filename = 'D:\Downloads\feeds (2).csv';
delimiter = ',';

%% Read columns of data as text:
% For more information, see the TEXTSCAN documentation.
formatSpec = '%s%s%s%s%s%s%s%s%s%s%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to the format.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'TextType', 'string',  'ReturnOnError', false);

%% Close the text file.
fclose(fileID);

%% Convert the contents of columns containing numeric text to numbers.
% Replace non-numeric text with NaN.
raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
for col=1:length(dataArray)-1
    raw(1:length(dataArray{col}),col) = mat2cell(dataArray{col}, ones(length(dataArray{col}), 1));
end
numericData = NaN(size(dataArray{1},1),size(dataArray,2));

for col=[2,4,5,6,7,9,10]
    % Converts text in the input cell array to numbers. Replaced non-numeric
    % text with NaN.
    rawData = dataArray{col};
    for row=1:size(rawData, 1)
        % Create a regular expression to detect and remove non-numeric prefixes and
        % suffixes.
        regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
        try
            result = regexp(rawData(row), regexstr, 'names');
            numbers = result.numbers;
            
            % Detected commas in non-thousand locations.
            invalidThousandsSeparator = false;
            if numbers.contains(',')
                thousandsRegExp = '^\d+?(\,\d{3})*\.{0,1}\d*$';
                if isempty(regexp(numbers, thousandsRegExp, 'once'))
                    numbers = NaN;
                    invalidThousandsSeparator = true;
                end
            end
            % Convert numeric text to numbers.
            if ~invalidThousandsSeparator
                numbers = textscan(char(strrep(numbers, ',', '')), '%f');
                numericData(row, col) = numbers{1};
                raw{row, col} = numbers{1};
            end
        catch
            raw{row, col} = rawData{row};
        end
    end
end


%% Split data into numeric and string columns.
rawNumericColumns = raw(:, [2,4,5,6,7,9,10]);
rawStringColumns = string(raw(:, [1,3,8]));


%% Replace non-numeric cells with NaN
R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),rawNumericColumns); % Find non-numeric cells
rawNumericColumns(R) = {NaN}; % Replace non-numeric cells

%% Make sure any text containing <undefined> is properly converted to an <undefined> categorical
for catIdx = [1,2,3]
    idx = (rawStringColumns(:, catIdx) == "<undefined>");
    rawStringColumns(idx, catIdx) = "";
end

%% Create output variable
feeds2 = table;
feeds2.created_at = categorical(rawStringColumns(:, 1));
feeds2.entry_id = cell2mat(rawNumericColumns(:, 1));
feeds2.field1 = categorical(rawStringColumns(:, 2));
feeds2.field2 = cell2mat(rawNumericColumns(:, 2));
feeds2.field3 = cell2mat(rawNumericColumns(:, 3));
feeds2.field4 = cell2mat(rawNumericColumns(:, 4));
feeds2.field5 = cell2mat(rawNumericColumns(:, 5));
feeds2.field6 = categorical(rawStringColumns(:, 3));
feeds2.field7 = cell2mat(rawNumericColumns(:, 6));
feeds2.field8 = cell2mat(rawNumericColumns(:, 7));

s = 3800;

id1 = (1:100);
x1 = feeds2.field4(s+1:s+100);
y1 = feeds2.field5(s+1:s+100);
z1 = feeds2.field6(s+1:s+100);

id2 = feeds2.entry_id(s+101:s+200);
x2 = feeds2.field4(s+101:s+200);
y2 = feeds2.field4(s+101:s+200);
z2 = feeds2.field4(s+101:s+200);

%% Clear temporary variables
clearvars filename delimiter formatSpec fileID dataArray ans raw col numericData rawData row regexstr result numbers invalidThousandsSeparator thousandsRegExp rawNumericColumns rawStringColumns R catIdx idx;
hold off;




%% coeff
[coeffY,lagY] = xcorr(y1,y2,'coeff');	
display(max(abs(coeffY)),'max(abs(coeffY))');
[~,I] = max(abs(coeffY));
diffY = lagY(I);
display(diffY,'diffY');


%% plot
if diffY > 0
    sizeY = size(y1(diffY:100));
    y=(1:sizeY);
    y1 = y1(diffY:100);
else
    sizeY = size(y1(1:100+diffY));
    y=(1:sizeY);
    y1 = y1(1:100+diffY);
end

y2 = y2(y);

plot(y,y1,'r','LineWidth',1);
hold on;
plot(y,y2,'b','LineWidth',1);

%% filter
%iir = designfilt('lowpassiir','FilterOrder',5, 'HalfPowerFrequency',0.2,'SampleRate',1);
%xfiltfilt = filtfilt(iir,y2);

fir = designfilt('lowpassfir','FilterOrder',5, 'CutoffFrequency',0.2,'SampleRate',1);
y1filt = filtfilt(fir,y1);
y2filt = filtfilt(fir,y2);

plot(y,y1filt,'m','LineWidth',2);
hold on;
plot(y,y2filt,'c','LineWidth',2);

%% peaks

limitUp = (max(y1)+mean(y1))*0.3;
limitDown = (min(y1)+mean(y1))*0.3;
%display(limitUp,'limitUp');
%display(limitDown,'limitDown');
[pks,locs] = findpeaks(y1filt,'minPeakHeight',limitUp,'Annotate','extents','WidthReference','halfheight');
plot(y(locs),pks,'ok');
[pksN,locsN] = findpeaks(-y1filt,'minPeakHeight',-limitDown);
plot(y(locsN),-pksN,'om');


limitUp = (max(y2)+mean(y2))*0.3;
limitDown = (min(y2)+mean(y2))*0.3;
[pks2,locs2] = findpeaks(y2filt,'minPeakHeight',limitUp);
plot(y(locs2),pks2,'ok');
[pks2N,locs2N] = findpeaks(-y2filt,'minPeakHeight',limitDown);
plot(y(locs2N),-pks2N,'om');

xlabel('sample')
ylabel('Amplitude')
%plot(id(locs2),pks2);

%axis tight
hold off;

display(id1(locs),'id1(locs)');
display(id1(locs2),'id1(locs2)');

%display(id1(locsN),'id1(locsN)');
%display(id1(locs2N),'id1(locs2N)');

counterL=0;
counterH=0;

for i=1:size(locs)-1
    for ii=1:size(locs2)-1
        if abs(locs(i)-locs2(ii)) < 3
            counterL = counterL + 1;
        end
        if abs(locs(i)-locs2(ii)) < 6
            counterH = counterH + 1;
        end
    end
end
for i=1:size(locsN)-1
    for ii=1:size(locs2N)-1
        if abs(locsN(i)-locs2N(ii)) < 3
            counterL = counterL + 1;
        end
        if abs(locsN(i)-locs2N(ii)) < 6
            counterH = counterH + 1;
        end
    end
end
display(counterL,'counterL');
display(counterH,'counterH');

%[coeffX,lagX] = xcorr(x1,x2,'coeff');	


%[coeffZ,lagZ] = xcorr(z1,z2,'coeff'); 
%[coeffV,lagY] = xcorr(v1,v2,'coeff');

%display(max(abs(coeffX)),'max(abs(coeffX))');
%display(max(abs(coeffY)),'max(abs(coeffY))');
%display(max(abs(coeffZ)),'max(abs(coeffZ))');
%display(max(abs(coeffV)),'max(abs(coeffV))');

%plot(id(locs2N),coeffX);
%hold on;

