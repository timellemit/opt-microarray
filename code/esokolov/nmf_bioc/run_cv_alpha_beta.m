%alpha_range = -3:0.5:3;
%beta_range = -2:0.5:7;
alpha_range = -2:0.25:2;
beta_range = -2:0.25:4;

quality_arrays_mad = zeros(length(alpha_range), length(beta_range));
quality_arrays_ouliers = zeros(length(alpha_range), length(beta_range));
quality_probes_mad = zeros(length(alpha_range), length(beta_range));
quality_probes_ouliers = zeros(length(alpha_range), length(beta_range));
concentration_dists = zeros(length(alpha_range), length(beta_range));
goodness_of_fit_fro = zeros(length(alpha_range), length(beta_range));
goodness_of_fit_geman = zeros(length(alpha_range), length(beta_range));
overfitting_native = zeros(length(alpha_range), length(beta_range));
overfitting_fro = zeros(length(alpha_range), length(beta_range));
converged_cnt_arrays1 = zeros(length(alpha_range), length(beta_range));
converged_cnt_arrays2 = zeros(length(alpha_range), length(beta_range));
converged_cnt_probes1 = zeros(length(alpha_range), length(beta_range));
converged_cnt_probes2 = zeros(length(alpha_range), length(beta_range));
converged_cnt_full = zeros(length(alpha_range), length(beta_range));
converged_cnt_fixedA = zeros(length(alpha_range), length(beta_range));
divergence_value = zeros(length(alpha_range), length(beta_range));
zero_influence = zeros(length(alpha_range), length(beta_range));
outliers_influence = zeros(length(alpha_range), length(beta_range));
zero_influence_ratio = zeros(length(alpha_range), length(beta_range));
outliers_influence_ratio = zeros(length(alpha_range), length(beta_range));
norm_problems_cnt = zeros(length(alpha_range), length(beta_range));

%inten = inten_full;
%inten_sliced = inten_full_sliced;

inten = inten_full(:, [1:500 1001:1002]);
inten_sliced = inten_full_sliced;
for i = 1:length(inten_sliced)
    inten_sliced{i} = inten_sliced{i}(:, 1:500);
end

inten_test = inten_full(:, 501:end);
inten_test_sliced = inten_full_sliced;
for i = 1:length(inten_test_sliced)
    inten_test_sliced{i} = inten_test_sliced{i}(:, 501:end);
end

fprintf('Generating partitions...');
[partition_arrays, partition_probes, partition_probes_compl, partition_probes_sliced, partition_probes_sliced_compl] = ...
   generate_partitions(inten, inten_sliced, inten_full_idx);
fprintf(' Done\n');
%load('alpha_beta_partition.mat');

maxIterCnt = 500;

for i = 1:length(alpha_range)
    for j = 1:length(beta_range)
        alpha = alpha_range(i);
        beta = beta_range(j);
        fprintf('Alpha = %f, Beta = %f\n', alpha, beta);

        fprintf('Factorizing partitions of I...');
        [quality_arrays_mad(i, j), quality_arrays_ouliers(i, j), quality_probes_mad(i, j), quality_probes_ouliers(i, j), ...
            arrays_factors_smart, probes_factors_smart, converged_cnt_arrays1(i, j), converged_cnt_arrays2(i, j), ...
            converged_cnt_probes1(i, j), converged_cnt_probes2(i, j)] = ...
            get_quality_cv(inten, inten_sliced, inten_full_idx, ...
            @(I) nmf_alpha_beta(I, 1, alpha, beta, maxIterCnt, 1e-6), partition_arrays, partition_probes, partition_probes_compl, ...
            partition_probes_sliced, partition_probes_sliced_compl);
        fprintf(' Done\n');
        
        conc_gene_dist = zeros(size(probes_factors_smart{2}, 1), 1);
        for k = 1:length(conc_gene_dist)
            conc_gene_dist(k) = Cdist(probes_factors_smart{2}(k, :), probes_factors_smart{6}(k, :));
        end
        concentration_dists(i, j) = mad(conc_gene_dist);
        
        fprintf('Factorizing I...');
        [A, C, Avect, A_sliced, converged_cnt_full(i, j), norm_problems_cnt(i, j)] = calibrate_model_parallel(inten, inten_sliced, ...
            inten_full_idx, @(I) nmf_alpha_beta(I, 1, alpha, beta, maxIterCnt, 1e-6));
        fprintf(' Done\n');
        
        fprintf('Factorizing I_test with fixed A...');
        [C_test converged_cnt_fixedA(i, j)] = find_concentrations(inten_test_sliced, A_sliced, ...
            @(I_arg, A_arg) nmf_alpha_beta_fixedA(I_arg, A_arg, alpha, beta, maxIterCnt, 1e-6));
        fprintf(' Done\n');
        
        R = inten(:, 1:end-2) - A * C;
        goodness_of_fit_fro(i, j) = norm(R, 'fro');
        goodness_of_fit_geman(i, j) = 0.5 * sum(sum((R .^ 2) ./ (1 + R .^ 2)));
        
        overfitting_native(i, j) = nmf_alpha_beta_divergence(inten_test(:, 1:end-2), A * C_test, alpha, beta) / (size(inten_test, 2) - 2) - ...
            nmf_alpha_beta_divergence(inten(:, 1:end-2), A * C, alpha, beta) / (size(inten, 2) - 2);
        overfitting_fro(i, j) = norm(inten_test(:, 1:end-2) - A * C_test, 'fro') / (size(inten_test, 2) - 2) - ...
            norm(inten(:, 1:end-2) - A * C, 'fro') / (size(inten, 2) - 2);
        
        divergence_value(i, j) = nmf_alpha_beta_divergence(inten(:, 1:end-2), A * C, alpha, beta);
        
        inten_nonzero = inten(:, 1:end-2);
        AC_nonzero = A * C;
        AC_nonzero = AC_nonzero(inten_nonzero > 0);
        inten_nonzero = inten_nonzero(inten_nonzero > 0);
        zero_influence(i, j) = nmf_alpha_beta_divergence(inten(:, 1:end-2), A * C, alpha, beta) - ...
            nmf_alpha_beta_divergence(inten_nonzero, AC_nonzero, alpha, beta);
        zero_influence_ratio(i, j) = nmf_alpha_beta_divergence(inten(:, 1:end-2), A * C, alpha, beta) / ...
            nmf_alpha_beta_divergence(inten_nonzero, AC_nonzero, alpha, beta);
        
        outliers_influence(i, j) = nmf_alpha_beta_divergence(inten(:, 1:end-2), A * C, alpha, beta) - ...
            nmf_alpha_beta_divergence_robust(inten(:, 1:end-2), A * C, alpha, beta);
        outliers_influence_ratio(i, j) = nmf_alpha_beta_divergence(inten(:, 1:end-2), A * C, alpha, beta) / ...
            nmf_alpha_beta_divergence_robust(inten(:, 1:end-2), A * C, alpha, beta);

        fprintf('Mad(A1 - A2): %f\nMad(C1 - C2): %e\nMad(dist(C1, C2)): %e\nGoodness of fit (fro): %e\nGoodness of fit (Geman): %e\nOverfitting (alpha-beta): %e\nOverfitting (L2): %e\nDivergence: %e\nZeros influence: %e\nOutliers influence: %e\nZeros influence ratio: %e\nOutliers influence ratio: %e\nNorm problems: %d\n\n', ...
            quality_arrays_mad(i, j), quality_probes_mad(i, j), concentration_dists(i, j), goodness_of_fit_fro(i, j), ...
            goodness_of_fit_geman(i, j), overfitting_native(i, j), overfitting_fro(i, j), divergence_value(i, j), ...
            zero_influence(i, j), outliers_influence(i, j), zero_influence_ratio(i, j), outliers_influence_ratio(i, j), norm_problems_cnt(i, j));

        save(['alpha_beta_cv_second_' num2str(alpha - min(alpha_range)) '_' num2str(beta - min(beta_range))], 'goodness_of_fit_fro', 'quality_arrays_mad', ...
            'overfitting_native', 'overfitting_fro', 'concentration_dists', ...
            'quality_arrays_ouliers', 'quality_probes_mad', 'quality_probes_ouliers', ...
            'converged_cnt_arrays1', 'converged_cnt_arrays2', 'converged_cnt_probes1', 'converged_cnt_probes2', ...
            'converged_cnt_full', 'converged_cnt_fixedA', 'divergence_value', ...
            'zero_influence', 'outliers_influence', 'zero_influence_ratio', 'outliers_influence_ratio', 'norm_problems_cnt', 'goodness_of_fit_geman');%, ...
            %'arrays_factors_smart', 'probes_factors_smart');
    end
end