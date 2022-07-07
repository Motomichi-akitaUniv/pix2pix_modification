%% shファイルで指定するファイル

%% 学習実行部分
% ファイルPATHをMATLABに追加
install();
% データのセット
[colar, gray] = p2p.util.settingDatasets();
% 学習のパラメータ → 要変更
options = p2p.trainingOptions( ...
    'DBeta1', 0.5000, ...
    'DBeta2', 0.9990, ...
    'DDepth', 4, ...
    'DLearnRate', 2.0000e-04, ...
    'DRelLearnRate', 0.5000, ...
    'GBeta1', 0.5000, ...
    'GBeta2', 0.9990, ...
    'GDepth', 8, ...
    'GLearnRate', 2.0000e-04, ...
    'InputChannels', 3, ...
    'InputSize', [256 256], ...
    'MaxEpochs', 200, ...
    'MiniBatchSize', 1, ...
    'OutputChannels', 3);
% 学習からモデル生成
p2pModel = p2p.train(gray, colar, options);
% 学習の実行結果をresultフォルダに保存
resultFoldername = sprintf('p2p_result_%s', datestr(now, 'YYYY-mm-DDTHH-MM-ss'));
mkdir('result', resultFoldername);
saveas(gcf,fullfile('result', resultFoldername, 'p2p_result'), 'png');
copyfile("settings.text", fullfile('result', resultFoldername, 'settings.txt'));

%% 学習後のモデルから画像を生成
% 元のカラー画像
origin = imread("datasets/test/Color/4001.jpg");
origin = imresize(origin, [256, 256], "Method", "nearest");
imwrite(origin, fullfile('result', resultFoldername, "origin.png"));
% 入力されたグレー画像
input = imread("datasets/test/Gray/4001.jpg");
input = imresize(input, [256, 256], "Method", "nearest");
imwrite(input, fullfile('result', resultFoldername, "input.png"));
% モデルによりカラー変換されたinput画像
output = p2p.translate(p2pModel, input);
imwrite(output, fullfile('result', resultFoldername, "output.png"));
