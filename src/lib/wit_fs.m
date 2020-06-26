function [capacity, infoWaveform, powerWaveform, infoRatio, powerRatio] = wit_fs(channel, txPower, noisePower)
    % Function:
    %   - optimize the waveform to maximize user rate
    %
    % Input:
    %   - channel (h) [nSubbands * nTxs * nRxs]: channel frequency response
    %   - txPower (P): transmit power constraint
    %   - noisePower (\sigma_n^2): average noise power
    %
    % Output:
    %   - capacity (R): channel capacity
    %   - infoWaveform (w_I) [nSubbands]: weight on information carriers
    %   - powerWaveform (w_P) [nSubbands]: weight on power carriers
    %   - infoRatio (\bar{\rho}): information splitting ratio
    %   - powerRatio (\rho): power splitting ratio
    %
    % Comment:
    %   - no IRS or frequency-selective IRS such that optimal channel is in closed form
    %   - construct information waveform by water-filling algorithm and matched filter
    %
    % Author & Date: Yang (i@snowztail.com) - 21 Jun 20



    % p_n^{(0)}
    [capacity, subbandPower] = channel_capacity(channel, txPower, noisePower);
    % \rho
    powerRatio = 0;
    % \bar{\rho}
    infoRatio = 1 - powerRatio;
    % \boldsymbol{W}_I^{(0)}
    infoWaveform = sqrt(subbandPower) .* exp(1i * angle(conj(channel)));
    % \boldsymbol{W}_P
    powerWaveform = zeros(size(channel));

end