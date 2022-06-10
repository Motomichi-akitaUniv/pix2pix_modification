function p2pModel = train(inData, outData, options)
% train     Train a pix2pix model.
%
%   A pix2pix model that attempts to learn how to convert images from
%   inData to outData is trained, following the approach described in
%   'Isola et al. Image-to-Image Translation with Conditional Adversarial 
%   Nets'.
%
% Args:
%   inData  - Training data input images
%   outData - Training data target images
%   options - Training options as a struct generated by p2p.trainingOptions
%
% Returns:
%   p2pModel - A struct containing trained newtorks and optimisiers
%
% See also: p2p.trainingOptions

% Copyright 2020 The MathWorks, Inc.
    
    if nargin < 3
        options = p2p.getDefaultOptions();
    end
    
    if (options.ExecutionEnvironment == "auto" && canUseGPU) || ...
            options.ExecutionEnvironment == "gpu"
        env = @gpuArray;
    else
        env = @(x) x;
    end
    
    if ~isempty(options.CheckpointPath)
        % Make a subfolder for storing checkpoints
        timestamp = strcat("p2p-", datestr(now, 'yyyymmdd-HHMMSS'));
        checkpointSubDir = fullfile(options.CheckpointPath, timestamp);
        mkdir(checkpointSubDir)
    end
    
    combinedChannels = options.InputChannels + options.OutputChannels;
    
    % model learns A to B mapping
    imageAndLabel = p2p.data.PairedImageDatastore(inData, outData, options.MiniBatchSize, ...
        "PreSize", options.PreSize, "CropSize", options.InputSize, "RandXReflection", options.RandXReflection);
    
    if options.Plots == "training-progress"
        examples = imageAndLabel.shuffle();
        nExamples = 9;
        examples.MiniBatchSize = nExamples;
        data = examples.read();
        thisInput = cat(4, data.A{:});
        exampleInputs = dlarray(env(thisInput), 'SSCB');
        trainingPlot = p2p.vis.TrainingPlot(exampleInputs);
    end
    
    if isempty(options.ResumeFrom)
        g = p2p.networks.generator(options.InputSize, options.InputChannels, options.OutputChannels, options.GDepth);
        d = p2p.networks.discriminator(options.InputSize, combinedChannels, options.DDepth);
        
        gOptimiser = p2p.util.AdamOptimiser(options.GLearnRate, options.GBeta1, options.GBeta2);
        dOptimiser = p2p.util.AdamOptimiser(options.DLearnRate, options.DBeta1, options.DBeta2);
        
        iteration = 0;
        startEpoch = 1;
    else
        data = load(options.ResumeFrom, 'p2pModel');
        g = data.p2pModel.g;
        d = data.p2pModel.d;
        gOptimiser = data.p2pModel.gOptimiser;
        dOptimiser = data.p2pModel.dOptimiser;
        
        iteration = gOptimiser.Iteration;
        startEpoch = floor(iteration/imageAndLabel.NumObservations)+1;
    end
    
    %% Training loop
    for epoch = startEpoch:options.MaxEpochs
        
        imageAndLabel = imageAndLabel.shuffle();
        
        while imageAndLabel.hasdata
            
            iteration = iteration + 1;
            
            data = imageAndLabel.read();
            thisInput = cat(4, data.A{:});
            thisTarget = cat(4, data.B{:});
            
            inputImage = dlarray(env(thisInput), 'SSCB');
            targetImage = dlarray(env(thisTarget), 'SSCB');
            
            [g, gLoss, d, dLoss, lossL1, ganLoss, ~] = ...
                dlfeval(@stepBoth, g, d, gOptimiser, dOptimiser, inputImage, targetImage, options);
            
            if mod(iteration, options.VerboseFrequency) == 0
                logArgs = {epoch, iteration,  ...
                    gLoss, lossL1, ganLoss, dLoss};
                fprintf('epoch: %d, it: %d, G: %f (L1: %f, GAN: %f), D: %f\n', ...
                    logArgs{:});
                if options.Plots == "training-progress"
                    trainingPlot.update(logArgs{:}, g);
                end
            end
        end
        
        p2pModel = struct('g', g, 'd', d, 'gOptimiser', gOptimiser, 'dOptimiser', dOptimiser);
        if ~isempty(options.CheckpointPath)
            checkpointFilename = sprintf('p2p_checkpoint_%s_%04d.mat', datestr(now, 'YYYY-mm-DDTHH-MM-ss'), epoch);
            p2pModel = gather(p2pModel);
            save(fullfile(checkpointSubDir, checkpointFilename), 'p2pModel')
        end
    end
end

function [g, gLoss, d, dLoss, lossL1, ganLoss, images] = stepBoth(g, d, gOpt, dOpt, inputImage, targetImage, options)
    
    % Make a fake image
    fakeImage = tanh(g.forward(inputImage));
    
    %% D update
    % Apply the discriminator
    realPredictions = sigmoid(d.forward(...
        cat(3, targetImage, inputImage) ...
        ));
    fakePredictions = sigmoid(d.forward(...
        cat(3, fakeImage, inputImage)...
        ));
    
    % calculate D losses
    labels = ones(size(fakePredictions), 'single');
    % crossentropy divides by nBatch, so we need to divide further
    dLoss = options.DRelLearnRate*(crossentropy(realPredictions, labels)/numel(fakePredictions(:,:,1,1)) + ...
        crossentropy(1-fakePredictions, labels)/numel(fakePredictions(:,:,1,1)));
    
    % get d gradients
    dGrads = dlgradient(dLoss, d.Learnables, "RetainData", true);
    dLoss = extractdata(dLoss);
    
    %% G update
    % to save time I just use the existing result from d
    
    % calculate g Losses
    ganLoss = crossentropy(fakePredictions, labels)/numel(fakePredictions(:,:,1,1));
    lossL1 = mean(abs(fakeImage - targetImage), 'all');
    gLoss = options.Lambda*lossL1 + ganLoss;
    
    % get g grads
    gGrads = dlgradient(gLoss, g.Learnables);
    
    % update g
    g.Learnables = dOpt.update(g.Learnables, gGrads);
    % update d
    d.Learnables = gOpt.update(d.Learnables, dGrads);
    % things for plotting
    gLoss = extractdata(gLoss);
    lossL1 = extractdata(lossL1);
    ganLoss = extractdata(ganLoss);
    
    images = {fakeImage, inputImage, targetImage};
end
