clear; clc; close all
set(groot,'defaulttextinterpreter','latex');  
set(groot, 'defaultAxesTickLabelInterpreter','latex');  
set(groot, 'defaultLegendInterpreter','latex');

% --- 폴더 경로 설정 ---
folder_path = 'finalplot/squat/vm/20kg'; % 데이터 파일 경로
files = dir(fullfile(folder_path, '*0kg.csv'));

% --- RGB 색상 설정 ---
myColors = [
    194,230,153
    120,198,121
    49,163,84
    0,104,55
    0,60, 20
] / 255; 

% --- 파일 개수 및 색상 매칭 ---
numFiles = length(files);
if numFiles <= 5
    colors = myColors(1:numFiles, :);
else
    colors = zeros(numFiles, 3);
    for idx = 1:numFiles
        colors(idx, :) = myColors(mod(idx-1, 4) + 1, :);
    end
end

% --- 범례 초기화 ---
legends = strings(1, numFiles); 

% --- Figure 설정 ---
fig_combined = figure('Position', [850,452,443,148]); 
hold on; 

% --- 필터 설계 (high-pass, cutoff 0.02 Hz, Fs 1000 Hz) ---
Fs = 1000; 
Fc = 0.02;
hpFilt = designfilt('highpassiir', 'FilterOrder', 8, 'HalfPowerFrequency', Fc, 'SampleRate', Fs);

% --- 데이터 저장 초기화 ---
all_pmmg_mean = {};
all_theta_mean = {};

for i = 1:numFiles
    file_path = fullfile(folder_path, files(i).name);
    data = readtable(file_path);

    % 데이터 추출
    t = data.timestamp;
    theta = data.angle_interp;
    pmmg = data.pMMG;

    % pMMG 필터링
    pmmg_filtered = filtfilt(hpFilt, pmmg);

    % 힐 스트라이크 정보 읽기 (1, 2 교차 사용)
    if mod(i, 2) == 1
        data1 = readtable(fullfile(folder_path, "1_heelstrike_index.csv"));
    else
        data1 = readtable(fullfile(folder_path, "2_heelstrike_index.csv"));
    end
    heelstrike_index = data1.HeelstrikeIndex;
    N = length(t);
    heelstrike = zeros(N, 1);
    heelstrike(heelstrike_index) = 1;

    % 보행 주기별 데이터 자르고 보간
    pmmg_cropped = crop_by_heelstrike(pmmg_filtered, heelstrike);
    theta_cropped = crop_by_heelstrike(theta, heelstrike);

    % 평균 계산 후 유효 범위 필터링 (80~150도)
    pmmg_mean = mean(pmmg_cropped, 2);
    theta_mean = mean(theta_cropped, 2);

    valid_indices = (theta_mean >= 80 & theta_mean <= 150);
    all_pmmg_mean{i} = pmmg_mean(valid_indices);
    all_theta_mean{i} = theta_mean(valid_indices);
end

% --- knee torque 데이터 로드 ---
file1 = readtable('kneetorque_squat_norm.csv');
file2 = readtable('kneeangle_squat_norm.csv');

x1 = file1{:, 1}; 
y1 = file1{:, 2}; 
x2 = file2{:, 1};

[x1_unique, ~, idx_unique] = unique(x1);
y1_unique = accumarray(idx_unique, y1, [], @mean);
new_col = zeros(size(x2));

for i = 1:length(x2)
    idx = find(x1_unique == x2(i), 1);
    if ~isempty(idx)
        new_col(i) = y1_unique(idx);
    else
        new_col(i) = interp1(x1_unique, y1_unique, x2(i), 'linear', 'extrap');
    end
end

table2_new = file2;
table2_new.NewColumn = new_col;

% --- 80~150도 범위 필터링 ---
valid_indices = (table2_new{:, 2} >= 80 & table2_new{:, 2} <= 150);
table2_new = table2_new(valid_indices, :);

% --- Z-Normalization ---
znorm = @(data) (data - mean(data, 1)) ./ std(data, 0, 1);

all_pmmg_mean_norm = cellfun(znorm, all_pmmg_mean, 'UniformOutput', false);
table2_torque_norm = znorm(table2_new.NewColumn);

% --- Poly2 피팅 ---
fit_models_pmmg = cell(1, length(all_theta_mean));
x_fits_pmmg = cell(1, length(all_theta_mean));
y_fits_pmmg = cell(1, length(all_theta_mean));
for i = 1:length(all_theta_mean)
    fit_models_pmmg{i} = fit(all_theta_mean{i}, all_pmmg_mean_norm{i}, 'poly2');
    x_fits_pmmg{i} = linspace(min(all_theta_mean{i}), max(all_theta_mean{i}), 1000);
    y_fits_pmmg{i} = feval(fit_models_pmmg{i}, x_fits_pmmg{i});
end

fit_model = fit(table2_new{:, 2}, table2_torque_norm, 'poly2');
x_fit = linspace(min(table2_new{:, 2}), max(table2_new{:, 2}), 1000);
y_fit = feval(fit_model, x_fit);

% --- Combined Plot (피팅 곡선) ---
figure(fig_combined); clf; hold on;
for i = 1:length(all_theta_mean)
    plot(x_fits_pmmg{i}, y_fits_pmmg{i}, 'Color', colors(i, :), 'LineWidth', 1.5);
    legends(i) = erase(files(i).name, '_vl_0kg.csv');
    legends(i) = strcat(legends(i), '\%');
end
plot(x_fit, y_fit, '-r', 'LineWidth', 1.5, 'DisplayName', 'Knee torque');
legends(length(all_theta_mean)+1) = 'knee torque';

legend(legends, 'Interpreter', 'latex', 'Location', 'ne');
xlabel('Knee Joint Angle (Deg)', 'Interpreter', 'latex'); 
grid on;
xlim([81, 150]);

% --- rRMSE 계산 (범위 기반) ---
fprintf('rRMSE values between fitted pMMG curves and knee torque fitted curve (Range-based normalization):\n');
rrmse_values = zeros(1, length(all_pmmg_mean_norm));
std_values = zeros(1, length(all_pmmg_mean_norm));

for i = 1:length(all_pmmg_mean_norm)
    x_common = max([min(x_fits_pmmg{i}), min(x_fit)]):0.1:min([max(x_fits_pmmg{i}), max(x_fit)]);
    y_pmmg_interp = interp1(x_fits_pmmg{i}, y_fits_pmmg{i}, x_common, 'linear', 'extrap');
    y_torque_interp = interp1(x_fit, y_fit, x_common, 'linear', 'extrap');
    
    diff = y_pmmg_interp - y_torque_interp;
    rmse = sqrt(mean(diff.^2));
    std_dev = std(diff);
    
    % --- 수정된 rRMSE 계산법: (max-min)으로 나눔 ---
    range_torque = max(y_torque_interp) - min(y_torque_interp);
    rrmse = rmse / range_torque;
    
    rrmse_values(i) = rrmse;
    std_values(i) = std_dev;
    
    fprintf('Dataset %d (%s): rRMSE = %.4f, Std Dev = %.4f\n', i, erase(files(i).name, '.csv'), rrmse, std_dev);
end

fprintf('\nSummary of rRMSE and Standard Deviation values:\n');
for i = 1:length(rrmse_values)
    fprintf('File: %s, rRMSE: %.4f\n', erase(files(i).name, '.csv'), rrmse_values(i));
end

% --- Private Functions ---
function cropped_data = crop_by_heelstrike(data, heelstrike)
    N = length(data);
    cropped_data = [];
    heelstrike_index = find(heelstrike == 1);
    for i = 1:2:length(heelstrike_index) - 1
        start_idx = heelstrike_index(i);
        end_idx = heelstrike_index(i + 1);
        segment_data = data(start_idx:end_idx);
        tempinterp = interp1((1:length(segment_data))', segment_data, linspace(1, length(segment_data), 1000)');
        cropped_data = [cropped_data tempinterp];
    end
end