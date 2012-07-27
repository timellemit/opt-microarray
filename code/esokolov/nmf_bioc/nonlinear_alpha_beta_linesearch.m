function [A B C isConverged qual_hist C_max_hist B_max_hist A_max_hist] = nonlinear_alpha_beta_linesearch(I, alpha, beta, maxIterCnt, eps, ...
        alpha_A, alpha_B, alpha_C, use_term_criteria)
    if (nargin < 8)
        use_term_criteria = true;
    end
        
    %[A B C] = nonlinear_init_als(I, eps);
    
    [A C] = nmf_alpha_beta(I, 1, alpha, beta, maxIterCnt, eps);
    
    %[A C] = nmf_normalize_prod(A, C);
    
    %A = rand(size(I, 1), 1) * 10;
    %C = rand(1, size(I, 2)) * 1000;
    %B = rand(size(I, 1), 1);
    
    B = zeros(size(A)) + eps;
    
    isConverged = 1;
    
    Aprev = A;
    Bprev = B;
    Cprev = C;
    
    %C_mean_hist = zeros(maxIterCnt, 1);
    C_max_hist = zeros(maxIterCnt, 1);
    qual_hist = zeros(maxIterCnt, 1);
    B_max_hist = zeros(maxIterCnt, 1);
    A_max_hist = zeros(maxIterCnt, 1);
    
    C_prev_iter = C;
    
    prevQuality = -1;
    for currIter = 1:maxIterCnt
        if (alpha == 0 && beta == 0)
            %F = (A * C) ./ (1 + B * C);
            A = exp((1 / size(I, 2)) * sum(log(I + eps) - log(bsxfun(@rdivide, C, 1 + B * C) + eps), 2));
            A = max(A, eps);
            
            F = (A * C) ./ (1 + B * C);
            C = C +  (sum((1 ./ (eps + bsxfun(@plus, C, B * (C .^ 2)))) .* (log(I + eps) - log(F + eps)), 1) + alpha_C * C) ./ ...
                (sum((1 ./ (eps + bsxfun(@times, C .^ 2, (1 + B * C) .^ 2))) .* ((2 * B * C + 1) .* log((I + eps) ./ (F + eps)) + 1), 1) + alpha_C/2);            
            C = max(C, eps);
            
            F = (A * C) ./ (1 + B * C);
            B = B -  (sum(bsxfun(@rdivide, C, 1 + B * C) .* (log(I + eps) - log(F + eps)), 2) + alpha_B * B) ./ ...
                (sum(bsxfun(@times, C .^ 2, (1 + B * C) .^ 2) .* (log(F + eps) - log(I + eps) + 1), 2) + alpha_B);
            B = max(B, eps);
        elseif (alpha == 0)
            F = (A * C) ./ (1 + B * C);
            A = A - ((1 ./ (A + eps)) .* sum(((F + eps) .^ beta) .* log((F + eps) ./ (I + eps)), 2)) ./ ...
                ((1 ./ (eps + A .^ 2)) .* sum(((F + eps) .^ beta) .* ((beta - 1) * log((F + eps) ./ (I + eps)) + 1), 2));
            A = max(A, eps);
            
            F = (A * C) ./ (1 + B * C);
            C = C -  (sum(((F + eps) .^ (beta + 1)) .* log((F + eps) ./ (I + eps)) .* (1 ./ (eps + A * (C .^ 2))), 1) + alpha_C * C) ./ ...
                (sum((1 ./ (eps + bsxfun(@times, C .^ 2, (1 + B * C) .^ 2))) .* ((F + eps) .^ beta) .* ...
                (1 - (2 * B * C - beta + 1) .* log((F + eps) ./ (I + eps))), 1) + alpha_C/2);
            C = max(C, eps);
            
            F = (A * C) ./ (1 + B * C);
            B = B +  (alpha_B * B + (1 ./ (A + eps)) .* sum(((F + eps) .^ (beta + 1)) .* log((F + eps) ./ (I + eps)), 2)) ./ ...
                (sum(bsxfun(@rdivide, C .^ 2, (1 + B * C) .^ 2) .* ((F + eps) .^ beta) .* ...
                ((beta + 1) * log((F + eps) ./ (I + eps)) + 1), 2) + alpha_B/2);
            B = max(B, eps);
        elseif (beta == 0)
            A = (sum((I + eps) .^ alpha, 2) ./ sum((eps + bsxfun(@rdivide, C, 1 + B * C)) .^ alpha, 2)) .^ (1 / alpha);
            A = max(A, eps);
            
            C = C -  (sum((((eps + (A * C) ./ (1 + B * C)) .^ alpha) - (eps + I) .^ alpha) ./ ...
                bsxfun(@times, C, 1 + B * C), 1) + alpha_C * C) ./ ...
                (sum(((alpha - 1 - 2 * B * C) .* ((eps + (A * C) ./ (1 + B * C)) .^ alpha) + ...
                (1 + 2 * B * C) .* ((I + eps) .^ alpha)) ./ ...
                bsxfun(@times, C .^ 2, (1 + B * C) .^ 2), 1) + alpha_C/2);
            C = max(C, eps);
            
            B = B -  (sum(bsxfun(@times, C, (I + eps) .^ alpha - (eps + (A * C) ./ (1 + B * C)) .^ alpha) ./ ...
                (1 + B * C), 2) + alpha_B * B) ./ ...
                (sum(bsxfun(@times, C .^ 2, (alpha + 1) * (eps + (A * C) ./ (1 + B * C)) .^ alpha - (I + eps) .^ alpha) ./ ...
                ((1 + B * C) .^ 2), 2) + alpha_B/2);
            B = max(B, eps);
        elseif (alpha == -beta)
            %A = ((1 / size(I, 2)) * sum((bsxfun(@rdivide, I .* (1 + B * C), C) + eps) .^ alpha, 2)) .^ (1 / alpha);
            direction = -(2 * alpha_A * A + size(I, 2) ./ (alpha * A) - ...
                (1 ./ (alpha * A .^ (alpha + 1))) .* sum(bsxfun(@rdivide, I .* (1 + B * C), C) .^ alpha, 2)) ./ ...
                (2 * alpha_A - size(I, 2) ./ (alpha * (A .^ 2)) + ((alpha + 1) ./ (alpha * (A .^ (alpha + 2)))) .* ...
                sum(bsxfun(@rdivide, I .* (1 + B * C), C) .^ alpha, 2));
            %direction(A == 0 & direction < 0) = 0;
            A = A + direction;
            A = max(A, eps);
            
            direction = - (sum((1 - (eps + (I .* (1 + B * C)) ./ (A * C)) .^ alpha) ./ (eps + bsxfun(@times, C, 1 + B * C)), 1) + alpha_C * C)./ ...
                (sum(((((I .* (1 + B * C)) ./ (A * C) + eps) .^ alpha) .* (2 * B * C + alpha + 1) - 2 * B * C - 1) ./ ...
                bsxfun(@times, C .^ 2, (1 + B * C) .^ 2), 1) + alpha_C);
            %direction(C == eps & direction < 0) = 0;
            C = C + direction;
            C = max(C, eps);
            
            direction = - (sum(((eps + bsxfun(@rdivide, I, A)) .^ alpha) .* ((eps + bsxfun(@rdivide, 1 + B * C, C)) .^ (alpha - 1)) - ...
                bsxfun(@rdivide, C, 1 + B * C), 2) + alpha_B * B) ./ ...
                (sum((alpha - 1) * (((eps + bsxfun(@rdivide, I, A)) .^ alpha) .* ((eps + bsxfun(@rdivide, 1 + B * C, C)) .^ (alpha - 2))) + ...
                bsxfun(@rdivide, C, 1 + B * C) .^ 2, 2) + alpha_B);
            %direction(B == eps & direction < 0) = 0;
            B = B + direction;
            B = max(B, eps);
        else
            % optimizing A
            %F = bsxfun(@rdivide, C, 1 + B * C);
            %A = (sum(((I + eps) .^ alpha) .* ((F + eps) .^ beta), 2) ./ sum((F + eps) .^ (alpha + beta), 2)) .^ (1 / alpha);
            F = (A * C) ./ (1 + B * C);
            A = A - (alpha_A * A + (1/alpha) * (1 ./ (A + eps)) .* sum(((F + eps) .^ beta) .* ((F + eps) .^ alpha - (I + eps) .^ alpha), 2)) ./ ...
                (alpha_A + (1 / alpha) * ((1 ./ (A + eps)) .^ 2) .* ...
                sum(((F + eps) .^ beta) .* ((alpha + beta - 1) * ((F + eps) .^ alpha) - (beta - 1) * ((I + eps) .^ alpha)), 2));
            A = max(A, eps);

            % optimizing C
            F = (A * C) ./ (1 + B * C);
            C = C - (sum((1 ./ (eps + A * (C .^ 2))) .* ((F + eps) .^ (beta + 1)) .* ((I + eps) .^ alpha - (F + eps) .^ alpha), 1) + alpha_C * C) ./ ...
                (sum((1 ./ (eps + bsxfun(@times, C .^ 2, (1 + B * C) .^ 2))) .* ((F + eps) .^ beta) .* (((F + eps) .^ alpha) .* (2 * B * C - alpha - beta + 1) - ...
                ((I + eps) .^ alpha) .* (2 * B * C - beta + 1)), 1) + alpha_C);
            C = max(C, eps);

            % optimizing B
            F = (A * C) ./ (1 + B * C);
            B = B + ((1 ./ (A + eps)) .* sum(((F + eps) .^ (beta + 1)) .* ((I + eps) .^ alpha - (F + eps) .^ alpha), 2) + alpha_B * B) ./ ...
                (sum(bsxfun(@rdivide, C .^ 2, (1 + B * C) .^ 2) .* ((F + eps) .^ beta) .* ((beta + 1) * ((I + eps) .^ alpha) - ...
                (alpha + beta + 1) * ((F + eps) .^ alpha)), 2) + alpha_B);
            B = max(B, eps);
        end
        
        %if mod(currIter, 1) == 0
        if false
            x0 = [Aprev' Bprev' Cprev];
            direction = [(A - Aprev)' (B - Bprev)' (C - Cprev)];
            ls_res = fminbnd(@(x) line_func(x, x0, direction, I, alpha, beta, alpha_C, alpha_B), 0, 10, optimset('FunValCheck', 'on'));

            X = x0 + ls_res * direction;
            A = X(1:size(I, 1))';
            B = X((size(I, 1)+1):(2*size(I, 1)))';
            C = X((2*size(I, 1) + 1):end);

            A = max(A, 0);
            B = max(B, 0);
            C = max(C, 0);

            Aprev = A;
            Bprev = B;
            Cprev = C;
        end
        
        % routines
        if (alpha_A == 0 && alpha_B == 0 && alpha_C == 0)
            [A, B, C] = nonlinear_normalize_prod(A, B, C);
        end
        
        Q = langmuir_func(A, B, C);
        currQuality = nmf_alpha_beta_divergence(I, Q, alpha, beta);
        
        %if (currIter > 1 && currQuality > prevQuality)
        %    isConverged = false;
        %    break;
        %end
        
        %if (currQuality > prevQuality && sum(C == 0) > 0)
        %    fprintf('%d\n', find(C == 0));
        %    I = I(:, setdiff(1:size(I, 2), find(C == 0)));
        %    [A B C] = nonlinear_alpha_beta(I, alpha, beta, maxIterCnt, eps, opt_method_C, opt_method_B, use_term_criteria);
        %    break;
        %end
        
        if (use_term_criteria && nonlinear_check_stopping_criteria(I, Q, currQuality, prevQuality, 1e-6))
        %if (use_term_criteria && currIter > 1 && nonlinear_check_stopping_criteria_C(C, C_prev_iter, 1e-6))
            break;
        end
        prevQuality = currQuality;
        %if (currIter > 10000)
        %    break;
        %end
        
        %C_mean_hist(currIter) = mean(abs(C - C_prev_iter));
        %C_max_hist(currIter) = max(abs(C - C_prev_iter));
        C_max_hist(currIter) = mean(C);
        qual_hist(currIter) = currQuality;
        B_max_hist(currIter) = mean(B);
        A_max_hist(currIter) = mean(A);
        
        %fprintf('%d: %f\t%f\t%f\t%e\t%e\n', currIter, currQuality, mean(abs(C - C_prev_iter)), max(abs(C - C_prev_iter)), max(C), max(B));
        %fprintf('%d: %e\n', currIter, C(912));
        
        C_prev_iter = C;        
    end
    
    %isConverged = (currIter < maxIterCnt);
    
    %C_mean_hist = C_mean_hist(1:currIter);
    C_max_hist = C_max_hist(1:currIter);
    B_max_hist = B_max_hist(1:currIter);
    A_max_hist = A_max_hist(1:currIter);
    
    A(isnan(A)) = 0;
    C(isnan(C)) = 0;
end

function f = line_func(x, x0, direction, I, alpha, beta, alpha_C, alpha_B)
    X = x0 + x * direction;
    A = X(1:size(I, 1))';
    B = X((size(I, 1)+1):(2*size(I, 1)))';
    C = X((2*size(I, 1) + 1):end);
    
    if (sum(A < 0) > 0 || sum(B < 0) > 0 || sum(C < 0) > 0)
        f = x * 1e200;
    else    
        f = nmf_alpha_beta_divergence(I, langmuir_func(A, B, C), alpha, beta) + alpha_C * sum(C .^ 2) + alpha_B * sum(B .^ 2);
    end
end
