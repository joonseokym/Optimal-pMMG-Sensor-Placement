clear; clc; close all;
set(groot,'defaulttextinterpreter','latex');  
set(groot, 'defaultAxesTickLabelInterpreter','latex');  
set(groot, 'defaultLegendInterpreter','latex');


% Step 1: Set up paths
input_folder = 'walkdata';  % 현재 폴더
output_folder = 'graphs';  % 새 폴더 경로
if ~exist(output_folder, 'dir')
    mkdir(output_folder);  % 새 폴더가 없으면 생성
end

% Step 2: Get list of CSV files in the folder
csv_files = dir(fullfile(input_folder, '*vl60_2.csv'));  % 현재 폴더에서 모든 .csv 파일 찾기

% 색상 설정 (예: 색상을 자동으로 생성)
% colors = lines(length(csv_files));  % 'lines'는 색상 팔레트를 생성

colors = lines(2);
% fig = figure('Position', [100 100 1200 600]); hold on; % pMMG plot

for file_idx = 1:length(csv_files)
    % Step 3: Load each CSV file
    file_name = csv_files(file_idx).name;
    data = readmatrix(fullfile(input_folder, file_name));

    % Step 4: Extract Data Columns
    X = data(:, 2);  % Features for standardization and PCA
    target_raw = data(:, end);  % Last 5 columns as target variables

    % Step 5: Standardize the Features
    X_mean = mean(X, 1);  % Mean of each column
    X_std = std(X, 0, 1);  % Standard deviation of each column
    X_std_norm = (X - X_mean) ./ X_std;  % Standardized features

    % Standardize the target variables (each column independently)
    target_mean = mean(target_raw, 1);  % Mean of target columns
    target_std = std(target_raw, 0, 1);  % Standard deviation of target columns
    target = (target_raw - target_mean) ./ target_std;  % Standardized targets
    % target = target_raw;

    % Step 6: Adjust color array size to match the number of features and targets
    num_features = size(X_std_norm, 2);  % Number of features
    num_targets = size(target, 2);  % Number of target variables
    colors = lines(num_features + num_targets);  % Generate enough colors for all features and targets

    % Step 6: Create Plot for Standardized Features and Targets
    figure('Position',[100 100 400 280]);
    hold on;
    legends = cell(1, num_features + num_targets);
    x = linspace(0, 100, size(X_std_norm, 1));  % x축

    % Plot all standardized features
    for i = 1:num_features
        subplot(1,2,1);
        plot(x, X_std_norm(:, i), 'Color', colors(i, :), 'LineWidth', 1.5);
        hold on
        xlabel('Gait Phase (\%)');
        ylabel('Standardized Torque');
        ylim([-2, 3]);
        grid on
        legends{i} = sprintf('Feature %d', i);
        legend('pMMG pressure','Location','se');

        % --- 최솟값 및 x 위치 구하기 ---
        range_idx = find(x >= 40 & x <= 50);  % x=40~50 구간의 인덱스
        [min_val, min_idx_local] = min(X_std_norm(range_idx, i));  % 로컬 인덱스에서 최소값 찾기
        min_idx = range_idx(min_idx_local);  % 전체에서의 인덱스
        fprintf('Feature %d: Min Value = %.3f at x = %.1f\n', i, min_val, x(min_idx));
        plot(x(min_idx), min_val, 'o', 'MarkerSize', 8, 'MarkerEdgeColor', colors(i,:), 'LineWidth', 1.5);  % 표시
    end

    % Plot the standardized targets
    for j = 1:num_targets
        subplot(1,2,2);
        plot(x, target(:, j), 'Color', colors(num_features + j, :), 'LineWidth', 1.5);
        hold on
        ylim([-2, 3]);
        grid on
        legends{num_features + j} = sprintf('Target %d', j);
        legend('knee torque','Location','se');

        % --- 최솟값 및 x 위치 구하기 ---
        range_idx = find(x >= 40 & x <= 50);
        [min_val, min_idx_local] = min(target(range_idx, j));
        min_idx = range_idx(min_idx_local);
        fprintf('Target %d: Min Value = %.3f at x = %.1f\n', j, min_val, x(min_idx));
        plot(x(min_idx), min_val, 'o', 'MarkerSize', 8, 'MarkerEdgeColor', colors(num_features + j,:), 'LineWidth', 1.5);
    end

    xlabel('Gait Phase (\%)');

    % Save the plot
    % output_file = fullfile(output_folder, sprintf('standardized_features_target_%s.png', file_name(1:end-4)));
    % saveas(gcf, output_file);
end