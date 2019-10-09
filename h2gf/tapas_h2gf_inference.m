function [inference] = tapas_h2gf_inference(inference, pars)
%% 
%
% aponteeduardo@gmail.com
% copyright (C) 2016
%

% Outer sampling loop
if ~isfield(inference, 'estimate_method')
    inference.estimate_method = @tapas_mcmc_blocked_estimate;
end

% Struct in which samples are collected
if ~isfield(inference, 'initilize_states')
    inference.initilize_states = @tapas_h2gf_init_states;
end

% Struct for the current sample
if ~isfield(inference, 'initilize_state')
    inference.initilize_state = @tapas_h2gf_init_state;
end

% Inner sampling loop across levels
if ~isfield(inference, 'sampling_methods')
    inference.sampling_methods = {
        % First level y is the data
        % Sample second level y
        @(d, m, i, s) tapas_mh_mc3_adaptive_ti_sample_node(d, m, i, s, 2), ...
        % Sample third level y
        @(d, m, i, s) tapas_sampler_dlinear_gibbs_node(d, m, i, s, 3) ... 
        };
end

% After going through inner sampling loop, do sampling diagnostics
if ~isfield(inference, 'metasampling_methods')
    inference.metasampling_methods = {@tapas_mcmc_meta_diagnostics, ...
        @tapas_mcmc_meta_adaptive, ...
        };
end

% Choose information from 'state' which will be stored in 'states'
if ~isfield(inference, 'get_stored_state')
    inference.get_stored_state = @tapas_h2gf_get_stored_state;
end

% Postprocessing (called after outer sampling loop is finished)
if ~isfield(inference, 'prepare_posterior')
    inference.prepare_posterior = @tapas_h2gf_prepare_posterior;
end

% Sample proposal and acceptance functions for Metropolis-Hastings
% (cells refer to levels)
if ~isfield(inference, 'mh_sampler')
    inference.mh_sampler = cell(4, 1);
end

% Only the second level has a Metropolis-Hastings step
if ~isfield(inference.mh_sampler{2}, 'propose_sample')
    % Propose
    inference.mh_sampler{2}.propose_sample = ...
        @tapas_mh_mc3_propose_gaussian_sample;
    % Accept/reject
    inference.mh_sampler{2}.ar_rule = ...
        @tapas_mh_mc3g_arc;
end

% COMMENT question: can we get rid of the pars argument and use inference
% for everything?
% Take the parameters from pars, and overwrite what ever might be inference.
inference.niter = pars.niter;
inference.nburnin = pars.nburnin;
inference.mc3it = pars.mc3it;
inference.thinning = pars.thinning;
inference.ndiag = pars.ndiag;
inference.rng_seed = pars.rng_seed;
inference.model_evidence_method = pars.model_evidence_method;

end
