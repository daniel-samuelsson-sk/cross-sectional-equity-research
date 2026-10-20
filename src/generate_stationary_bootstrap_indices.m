function indices = generate_stationary_bootstrap_indices(T, B, L, seed)
%GENERATE_STATIONARY_BOOTSTRAP_INDICES
% Generate circular stationary-bootstrap index paths.
%
% indices = GENERATE_STATIONARY_BOOTSTRAP_INDICES(T, B, L, seed)
%
% Implements the stationary bootstrap of Politis and Romano (1994).
%
% Algorithm:
%
%   1. Set rng(seed,'twister') once before generating any paths.
%
%   2. For each bootstrap replicate:
%
%      a. At t = 1, choose the starting position uniformly from 1,...,T.
%
%      b. For t >= 2, start a new block with probability 1/L by
%         choosing a new position uniformly from 1,...,T.
%
%      c. Otherwise continue the current block using circular wrap:
%
%             pos = mod(pos,T) + 1
%
% B is the number of bootstrap replicates and L is the target mean
% block length.


%% Validate inputs

assert( ...
    isscalar(T) && ...
    isfinite(T) && ...
    T == floor(T) && ...
    T >= 2, ...
    'StationaryBootstrap:InvalidSampleLength', ...
    'T must be an integer greater than or equal to 2.');

assert( ...
    isscalar(B) && ...
    isfinite(B) && ...
    B == floor(B) && ...
    B >= 1, ...
    'StationaryBootstrap:InvalidReplicateCount', ...
    'B must be a positive integer.');

assert( ...
    isscalar(L) && ...
    isfinite(L) && ...
    L >= 1, ...
    'StationaryBootstrap:InvalidBlockLength', ...
    'L must be finite and greater than or equal to 1.');

assert( ...
    isscalar(seed) && ...
    isfinite(seed) && ...
    seed == floor(seed) && ...
    seed >= 0, ...
    'StationaryBootstrap:InvalidSeed', ...
    'seed must be a non-negative integer.');


%% Initialize random-number generator

rng(seed, 'twister');


%% Generate index paths

indices = ...
    zeros(B, T);

restart_probability = ...
    1 / L;


for b = 1:B

    %% First observation

    pos = ...
        randi(T);

    indices(b,1) = ...
        pos;


    %% Remaining observations

    for t = 2:T

        if rand < restart_probability

            pos = ...
                randi(T);

        else

            pos = ...
                mod(pos, T) + 1;

        end

        indices(b,t) = ...
            pos;

    end

end


%% Integrity checks

assert( ...
    all(indices(:) >= 1) && ...
    all(indices(:) <= T) && ...
    all(indices(:) == floor(indices(:))), ...
    'StationaryBootstrap:InvalidGeneratedIndex', ...
    'Generated bootstrap indices must be integers in the range 1,...,T.');

end