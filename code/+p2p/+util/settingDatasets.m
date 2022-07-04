function [colorFolder, grayFolder] = settingDatasets(destination)
% function settingDatasets(destination)
% downloadFacades Saves a copy of the facades dataset images.
%
% Inputs:
%   destination - Location to save dataset to (default: "./datasets/facades")
% Returns:
%   aFolder - Location of label images
%   bFolder - Location of target images

% Copyright 2020 The MathWorks, Inc.
    
    %% 学習用データを格納するフォルダの生成
    % datasets_origin配下にあるデータセットを任意の名前で指定
    % datasetsName = "iaprtc12";
    datasetsName = "test";

    if nargin < 1
        destination = "./datasets/" + datasetsName;
    end
    
    colorFolder = fullfile(destination, "Color");
    grayFolder = fullfile(destination, "Gray");

    if ~isfolder(destination)
        fprintf('Generate Folders')
        mkdir(destination);
        mkdir(colorFolder);
        mkdir(grayFolder);
    end
    
    %% 各データセットを学習用にフォルダ分け
    % データセットのPATHを指定(絶対PATHの方がいいかも)
    datasetsPath = "datasets_origin/iaprtc12/";
    %datasetsPath = "datasets_test";
    % カラー写真
    copyfile(fullfile(datasetsPath, "images/04/", "*.jpg"), colorFolder);
    %copyfile(fullfile(datasetsPath, "Color/", "*.jpg"), colorFolder);
    
    % モノクロ写真
    copyfile(fullfile(datasetsPath, "images/04/", "*.jpg"), grayFolder);
    %copyfile(fullfile(datasetsPath, "Gray/", "*.jpg"), grayFolder);
    convertToGray(grayFolder)
            
    fprintf("done.\n")
    
end

function convertToGray(directory)
    % Converts all the images in the directory to GrayScale.
    fprintf('convert to gray ... ');
    ims = imageDatastore(directory);
    for iIm = 1:numel(ims.Files)
        filename = ims.Files{iIm};
        rgbIm = imread(filename);
        grayIm = rgb2gray(rgbIm);
        imwrite(grayIm, filename);
    end
    fprintf('end\n\n');
end