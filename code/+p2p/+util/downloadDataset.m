function downloadDataset(dataUrl)
% downloadFacades Saves a copy of the facades dataset images.
%
% Inputs:
%   destination - Location to save dataset to (default: "./datasets/facades")
% Returns:
%   aFolder - Location of label images
%   bFolder - Location of target images

% Copyright 2020 The MathWorks, Inc.

    [~,name,ext] = fileparts(dataUrl);

    destination = "./datasets_origin/" + name;

    if ~isfolder(destination)
        mkdir(destination);
    end

    fprintf("Downloading dataset...")
    switch ext
        case ".zip"
            tempZipFile = tempname;
            UnzippedFolder = destination;
            websave(tempZipFile, dataUrl);
            
            unzip(tempZipFile, UnzippedFolder);
        case ".tgz"
            untar(dataUrl,destination);
        otherwise
            fprintf('Unsupported filename extension');
    end

    fprintf("done.\n")
    
end