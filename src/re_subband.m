clear; clc; setup; config_subband; load('data/tap.mat');

% * R-E region vs number of subbands
directReSample = cell(length(Variable.nSubbands), 1);
ffReSample = cell(length(Variable.nSubbands), 1);
for iSubband = 1 : length(Variable.nSubbands)
    % * Update channels
    nSubbands = Variable.nSubbands(iSubband);
    [subbandFrequency] = subband_frequency(centerFrequency, bandwidth, nSubbands);
    [directChannel] = frequency_response(nSubbands, subbandFrequency, fadingMode, nReflectors, directDistance, directTapGain, directTapDelay, "direct");
    [incidentChannel] = frequency_response(nSubbands, subbandFrequency, fadingMode, nReflectors, incidentDistance, incidentTapGain, incidentTapDelay, "incident");
    [reflectiveChannel] = frequency_response(nSubbands, subbandFrequency, fadingMode, nReflectors, reflectiveDistance, reflectiveTapGain, reflectiveTapDelay, "reflective");

    %% ! No-IRS: R-E region vs number of subbands
    % * Initialize algorithm by WIT
    [capacity, infoWaveform, powerWaveform, infoRatio, powerRatio] = wit_no_irs(directChannel, txPower, noisePower);
    rateConstraint = capacity : -capacity / (nSamples - 1) : 0;

    % * Achievable R-E region without IRS
    directReSample{iSubband} = zeros(3, nSamples);
    for iSample = 1 : nSamples
        isConverged = false;
        current_ = 0;
        while ~isConverged
            [infoWaveform, powerWaveform] = waveform_sdr(beta2, beta4, txPower, nCandidates, rateConstraint(iSample), tolerance, infoRatio, powerRatio, noisePower, directChannel, infoWaveform, powerWaveform);
            [infoRatio, powerRatio] = split_ratio(infoWaveform, noisePower, rateConstraint(iSample), directChannel);
            [rate, current] = re_sample(beta2, beta4, directChannel, noisePower, infoWaveform, powerWaveform, infoRatio, powerRatio);
            isConverged = abs(current - current_) / current <= tolerance || current == 0;
            current_ = current;
        end
        directReSample{iSubband}(:, iSample) = [rate; current; powerRatio];
    end

    %% ! IRS: R-E region
    % * Initialize algorithm by WIT
    [capacity, irs, infoWaveform, powerWaveform, infoRatio, powerRatio] = wit_ff(irsGain, tolerance, directChannel, incidentChannel, reflectiveChannel, txPower, nCandidates, noisePower);
    rateConstraint = capacity : -capacity / (nSamples - 1) : 0;
    [compositeChannel, concatVector, concatMatrix] = composite_channel(directChannel, incidentChannel, reflectiveChannel, irs);

    % * Achievable R-E region by FF-IRS
    ffReSample{iSubband} = zeros(3, nSamples);
    for iSample = 1 : nSamples
        isConverged = false;
        current_ = 0;
        while ~isConverged
            [irs] = irs_ff(beta2, beta4, nCandidates, rateConstraint(iSample), tolerance, infoWaveform, powerWaveform, infoRatio, powerRatio, concatVector, noisePower, concatMatrix, irs);
            [compositeChannel] = composite_channel(directChannel, incidentChannel, reflectiveChannel, irs);
            [infoWaveform, powerWaveform] = waveform_sdr(beta2, beta4, txPower, nCandidates, rateConstraint(iSample), tolerance, infoRatio, powerRatio, noisePower, compositeChannel, infoWaveform, powerWaveform);
            [infoRatio, powerRatio] = split_ratio(infoWaveform, noisePower, rateConstraint(iSample), compositeChannel);
            [rate, current] = re_sample(beta2, beta4, compositeChannel, noisePower, infoWaveform, powerWaveform, infoRatio, powerRatio);
            isConverged = abs(current - current_) / current <= tolerance || current == 0;
            current_ = current;
        end
        ffReSample{iSubband}(:, iSample) = [rate; current; powerRatio];
    end
end
