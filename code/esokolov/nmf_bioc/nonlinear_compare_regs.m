inten = inten_full(:, [1:250 1001:1002]) + 1;
inten_sliced = inten_full_sliced;
for i = 1:length(inten_sliced)
    inten_sliced{i} = inten_sliced{i}(:, 1:250) + 1;
end

inten_test = inten_full(:, 501:end) + 1;
inten_test_sliced = inten_full_sliced;
for i = 1:length(inten_test_sliced)
    inten_test_sliced{i} = inten_test_sliced{i}(:, 501:end) + 1;
end

maxIterCnt = 1000;

alpha = -0.5;
beta = -0.5;
fprintf('Alpha = %f, Beta = %f\n', alpha, beta);

fprintf('Factorizing I without regularization...');
[A_nr, B_nr, C_nr, Avect_nr, Bvect_nr, A_sliced_nr, B_sliced_nr, notConvergedCnt_nr] = nonlinear_calibrate_model(inten, inten_sliced, ...
    inten_full_idx, @(I) nonlinear_alpha_beta_linesearch(I, alpha, beta, maxIterCnt, 1e-6, 0, 0, 0, 1), false);
fprintf(' Done\n');

fprintf('Factorizing I with Q-regularization...');
[A_quad, B_quad, C_quad, Avect_quad, Bvect_quad, A_sliced_quad, B_sliced_quad, notConvergedCnt_quad] = nonlinear_calibrate_model(inten, inten_sliced, ...
    inten_full_idx, @(I) nonlinear_alpha_beta_linesearch(I, alpha, beta, maxIterCnt, 1e-6, 0, 0.01, 1e-10, 1), false);
fprintf(' Done\n');

fprintf('Factorizing I with V-regularization...');
[A_voron, B_voron, C_voron, Avect_voron, Bvect_voron, A_sliced_voron, B_sliced_voron, notConvergedCnt_voron] = nonlinear_calibrate_model(inten, inten_sliced, ...
    inten_full_idx, @(I) nonlinear_alpha_beta_reg_derivative(I, alpha, beta, maxIterCnt, 1e-6, 1e-4, 1), false);
fprintf(' Done\n');

fprintf('Factorizing I with V-regularization and other eps...');
[A_voron1, B_voron1, C_voron1, Avect_voron1, Bvect_voron1, A_sliced_voron1, B_sliced_voron1, notConvergedCnt_voron1] = nonlinear_calibrate_model(inten, inten_sliced, ...
    inten_full_idx, @(I) nonlinear_alpha_beta_reg_derivative(I, alpha, beta, maxIterCnt, 1e-6, 1e-5, 1), false);
fprintf(' Done\n');

fprintf('Factorizing I with V-regularization and other eps...');
[A_voron2, B_voron2, C_voron2, Avect_voron2, Bvect_voron2, A_sliced_voron2, B_sliced_voron2, notConvergedCnt_voron2] = nonlinear_calibrate_model(inten, inten_sliced, ...
    inten_full_idx, @(I) nonlinear_alpha_beta_reg_derivative(I, alpha, beta, maxIterCnt, 1e-6, 1e-6, 1), false);
fprintf(' Done\n');

fprintf('Factorizing I_test with fixed A (no regularization)...');
[C_test_nr, notConvergedCnt_nr_fixed] = nonlinear_find_concentrations(inten_test_sliced, A_sliced_nr, B_sliced_nr, ...
    @(I_arg, A_arg, B_arg) nonlinear_alpha_beta_fixedAB(I_arg, A_arg, B_arg, alpha, beta, maxIterCnt, 1e-6, 0, 1));
fprintf(' Done\n');

fprintf('Factorizing I_test with fixed A (Q_reg)...');
[C_test_quad, notConvergedCnt_quad_fixed] = nonlinear_find_concentrations(inten_test_sliced, A_sliced_quad, B_sliced_quad, ...
    @(I_arg, A_arg, B_arg) nonlinear_alpha_beta_fixedAB(I_arg, A_arg, B_arg, alpha, beta, maxIterCnt, 1e-6, 1e-10, 1));
fprintf(' Done\n');

fprintf('Factorizing I_test with fixed A (V_reg)...');
[C_test_voron, notConvergedCnt_voron_fixed] = nonlinear_find_concentrations(inten_test_sliced, A_sliced_voron, B_sliced_voron, ...
    @(I_arg, A_arg, B_arg) nonlinear_alpha_beta_reg_derivative_fixedAB(I_arg, A_arg, B_arg, alpha, beta, maxIterCnt, 1e-6, 1e-4, 1));
fprintf(' Done\n');

fprintf('Factorizing I_test with fixed A (V_reg with other eps)...');
[C_test_voron1, notConvergedCnt_voron_fixed1] = nonlinear_find_concentrations(inten_test_sliced, A_sliced_voron1, B_sliced_voron1, ...
    @(I_arg, A_arg, B_arg) nonlinear_alpha_beta_reg_derivative_fixedAB(I_arg, A_arg, B_arg, alpha, beta, maxIterCnt, 1e-6, 1e-5, 1));
fprintf(' Done\n');

fprintf('Factorizing I_test with fixed A (V_reg with other eps)...');
[C_test_voron2, notConvergedCnt_voron_fixed2] = nonlinear_find_concentrations(inten_test_sliced, A_sliced_voron2, B_sliced_voron2, ...
    @(I_arg, A_arg, B_arg) nonlinear_alpha_beta_reg_derivative_fixedAB(I_arg, A_arg, B_arg, alpha, beta, maxIterCnt, 1e-6, 1e-6, 1));
fprintf(' Done\n');

save('nln_calibrated.mat', 'A_nr', 'B_nr', 'C_nr', 'Avect_nr', 'Bvect_nr', 'A_sliced_nr', 'B_sliced_nr', 'C_test_nr', ...
    'A_quad', 'B_quad', 'C_quad', 'Avect_quad', 'Bvect_quad', 'A_sliced_quad', 'B_sliced_quad', 'C_test_quad', ...
    'A_voron', 'B_voron', 'C_voron', 'Avect_voron', 'Bvect_voron', 'A_sliced_voron', 'B_sliced_voron', 'C_test_voron');

qual_nr = sum(sum(huber_func(inten_test(:, 1:end-2) - langmuir_func(A_nr, B_nr, C_test_nr))));
qual_quad = sum(sum(huber_func(inten_test(:, 1:end-2) - langmuir_func(A_quad, B_quad, C_test_quad))));
qual_voron = sum(sum(huber_func(inten_test(:, 1:end-2) - langmuir_func(A_voron, B_voron, C_test_voron))));
qual_voron1 = sum(sum(huber_func(inten_test(:, 1:end-2) - langmuir_func(A_voron, B_voron, C_test_voron1))));
qual_voron2 = sum(sum(huber_func(inten_test(:, 1:end-2) - langmuir_func(A_voron, B_voron, C_test_voron2))));

qual_nr_native = nmf_alpha_beta_divergence(inten_test(:, 1:end-2), langmuir_func(A_nr, B_nr, C_test_nr), alpha, beta);
qual_quad_native = nmf_alpha_beta_divergence(inten_test(:, 1:end-2), langmuir_func(A_quad, B_quad, C_test_quad), alpha, beta);
qual_voron_native = nmf_alpha_beta_divergence(inten_test(:, 1:end-2), langmuir_func(A_voron, B_voron, C_test_voron), alpha, beta);
qual_voron1_native = nmf_alpha_beta_divergence(inten_test(:, 1:end-2), langmuir_func(A_voron1, B_voron1, C_test_voron1), alpha, beta);
qual_voron2_native = nmf_alpha_beta_divergence(inten_test(:, 1:end-2), langmuir_func(A_voron2, B_voron2, C_test_voron2), alpha, beta);


qual_nr_sliced = zeros(length(inten_full_sliced), 1);
qual_quad_sliced = zeros(length(inten_full_sliced), 1);
qual_voron_sliced = zeros(length(inten_full_sliced), 1);
for i = 1:length(inten_full_sliced)
    qual_nr_sliced(i) = sum(sum(huber_func(inten_test_sliced{i} - langmuir_func(A_sliced_nr{i}, B_sliced_nr{i}, C_test_nr(i, :)))));
    qual_quad_sliced(i) = sum(sum(huber_func(inten_test_sliced{i} - langmuir_func(A_sliced_quad{i}, B_sliced_quad{i}, C_test_quad(i, :)))));
    qual_voron_sliced(i) = sum(sum(huber_func(inten_test_sliced{i} - langmuir_func(A_sliced_voron{i}, B_sliced_voron{i}, C_test_voron(i, :)))));
end

quantiles = zeros(length(inten_full_sliced), 1);
for i = 1:length(inten_full_sliced)
    quantiles(i) = quantile(inten_test_sliced{i}(:), 0.95);
end