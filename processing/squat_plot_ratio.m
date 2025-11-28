clear; clc; close all

set(groot, 'DefaultTextInterpreter', 'latex');
set(groot, 'DefaultAxesTickLabelInterpreter', 'latex');
set(groot, 'DefaultLegendInterpreter', 'latex');

input_folder = pwd;  % 현재 폴더
output_folder = fullfile(input_folder, 'squat_graphs2');
if ~exist(output_folder, 'dir')
    mkdir(output_folder);  % 새 폴더가 없으면 생성
end

files = dir(fullfile(input_folder, '*.csv'));

% 색상 및 범례 설정
colors = lines(3);
legends = strings(1, length(files));

% 고정된 mean과 std 열 번호 설정
meanColumns = [2, 4, 6];  
stdColumns = [3, 5, 7];   

% 필터 설정
Fs = 1000;
Fc = 0.02;
hpFilt = designfilt('highpassiir', 'FilterOrder', 8, 'HalfPowerFrequency', Fc, 'SampleRate', Fs);

integrals_xy = zeros(length(files), 2);
distance_array = zeros(length(files), 1);

for i = 1:length(files)
    file_name = files(i).name;
    modified_name = strrep(file_name, 'squat_', '');  
    legends(i) = strcat(erase(files(i).name, '_vl_0kg.csv'), '_modified');
    
    data = readtable(files(i).name);
    phase = data.GaitPhase;

    ratios = zeros(1, 2);
    for j = 1:3  
        means = data{:, meanColumns(j)};
        stds = data{:, stdColumns(j)};
        means = filtfilt(hpFilt, means);
        integrals(j) = mean(means(550:650));

        temp_ratio = [50 62 70] - 5;
        if j == 2  
            ratios(1) = (integrals(2)-integrals(1)) / (temp_ratio(2)-temp_ratio(1));
        elseif j == 3  
            ratios(2) = (integrals(3)-integrals(2)) / (temp_ratio(3)-temp_ratio(2));
        end
    end

    fprintf('File: %s\n', modified_name);
    fprintf('Integral of means1: %.4f\n', integrals(1));
    fprintf('Integral of means2: %.4f\n', integrals(2));
    fprintf('Integral of means3: %.4f\n', integrals(3));
    fprintf('1 - (Integral of means1 / Integral of means2): %.4f\n', ratios(1));
    fprintf('1 - (Integral of means2 / Integral of means3): %.4f\n', ratios(2));
    % Calculate distance to y=x line using |y-x|/√2 formula
    distance_to_line = abs(ratios(2) - ratios(1)) / sqrt(2);
    fprintf('Distance to y=x line: %.4f\n', distance_to_line);
    distance_array(i) = distance_to_line; % 현재 파일의 거리 값 저장
    integrals_xy(i, :) = ratios;
    
end

% 모든 파일에 대한 비율 값 XY 평면에 플로팅
fig = figure('Position',[1337,463,300,300]);
hold on;
legendEntries = {}; 
legendMarkers = {}; 

custom_colors = struct();
custom_colors.red = [1,0,0];     
custom_colors.green = [0,1,0];   
custom_colors.blue = [0,0,1];    

for i = 1:length(files)
    if contains(files(i).name, 'rf')
        scatter_color = custom_colors.red;  
        if contains(files(i).name, '20')
            marktype = 'r^'; 
            markerFaceColor = 'none';
        elseif contains(files(i).name, '30')
            marktype = 'rs'; 
            markerFaceColor = 'none';
        elseif contains(files(i).name, '40')
            marktype = 'ro';  
            markerFaceColor = 'none'; % 속이 빈 원
        elseif contains(files(i).name, '50')
            marktype = 'r+';
            markerFaceColor = 'none';
        else
            marktype = 'ro';  
            markerFaceColor = 'r'; % 속이 채워진 원
        end
        marker = plot(nan, nan, '.', 'Color', scatter_color, 'MarkerSize', 15); 
        if ~ismember('Rectus Femoris', legendEntries)
            legendEntries{end+1} = 'Rectus Femoris';
            legendMarkers{end+1} = marker;
        end
    elseif contains(files(i).name, 'vl')
        scatter_color = custom_colors.green;  
        if contains(files(i).name, '30')
            marktype = 'rs'; 
            markerFaceColor = 'none';
        elseif contains(files(i).name, '40')
            marktype = 'ro';  
            markerFaceColor = 'none'; % 속이 빈 원
        elseif contains(files(i).name, '50')
            marktype = 'r+';
            markerFaceColor = 'none';
        else
            marktype = 'ro';  
            markerFaceColor = 'g'; % 속이 채워진 원
        end
        marker = plot(nan, nan, '.', 'Color', scatter_color, 'MarkerSize', 15); 
        if ~ismember('Vastus Lateralis', legendEntries)
            legendEntries{end+1} = 'Vastus Lateralis';
            legendMarkers{end+1} = marker;
        end
    elseif contains(files(i).name, 'vm')
        scatter_color = custom_colors.blue;  
        if contains(files(i).name, '20')
            marktype = 'r^'; 
            markerFaceColor = 'none';
        elseif contains(files(i).name, '30')
            marktype = 'rs'; 
            markerFaceColor = 'none';
        elseif contains(files(i).name, '40')
            marktype = 'ro';  
            markerFaceColor = 'none'; % 속이 빈 원
        else
            marktype = 'r+';
            markerFaceColor = 'none';
        end
        marker = plot(nan, nan, '.', 'Color', scatter_color, 'MarkerSize', 15); 
        if ~ismember('Vastus Medialis', legendEntries)
            legendEntries{end+1} = 'Vastus Medialis';
            legendMarkers{end+1} = marker;
        end
    else
        scatter_color = [0, 0, 0];  
        markerFaceColor = 'k';  
        marker = plot(nan, nan, '.', 'Color', scatter_color, 'MarkerSize', 15); 
        if ~ismember('Others', legendEntries)
            legendEntries{end+1} = 'Others';
            legendMarkers{end+1} = marker;
        end
    end
    plot(integrals_xy(i, 1), integrals_xy(i, 2), marktype, 'MarkerSize', 8, 'MarkerFaceColor', markerFaceColor, 'Color', scatter_color);
end

% Replace the ideal point plot with y=x line
x_vals = linspace(-1, 1, 100);
plot(x_vals, x_vals, 'k--', 'LineWidth', 1.5);  % Dashed black line for y=x

grid on;
xlabel('', 'Interpreter', 'latex');
ylabel('', 'Interpreter', 'latex');

xlim([-0.6, 0.6]);
ylim([-0.6, 0.6]); 
legendEntries{end+1} = 'Ideal Linear Response';
marker = plot(nan, nan, 'k--', 'LineWidth', 1.5);
legendMarkers{end+1} = marker;
legend([legendMarkers{:}], legendEntries, 'Interpreter', 'latex', 'Location', 'se');
hold off;

% 그래프 저장
% saveas(gcf, fullfile(output_folder, 'ratios_plot.png'));
