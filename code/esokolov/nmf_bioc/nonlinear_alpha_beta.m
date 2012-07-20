function [A B C isConverged] = nonlinear_alpha_beta(I, alpha, beta, maxIterCnt, eps, alpha_C, alpha_B, use_term_criteria)
    if (nargin < 8)
        use_term_criteria = true;
    end
        
    %[A B C] = nonlinear_init_als(I, eps);
    
    [A C] = nmf_alpha_beta(I, 1, alpha, beta, maxIterCnt, eps);
    
    %[A C] = nmf_normalize_prod(A, C);
    
    %A = rand(size(I, 1), 1);
    %C = rand(1, size(I, 2));
    %B = rand(size(I, 1), 1);
    
    B = zeros(size(A)) + eps;
    
    isConverged = 1;
    
    prevQuality = -1;
    for currIter = 1:maxIterCnt
        if (alpha == 0 && beta == 0)
            %F = (A * C) ./ (1 + B * C);
            A = exp((1 / size(I, 2)) * sum(log(I + eps) - log(bsxfun(@rdivide, C, 1 + B * C) + eps), 2));
            A = max(A, 0);
            
            F = (A * C) ./ (1 + B * C);
            C = C + 0.5 * (sum((1 ./ (eps + bsxfun(@plus, C, B * (C .^ 2)))) .* (log(I + eps) - log(F + eps)), 1) + alpha_C * C) ./ ...
                (sum((1 ./ (eps + bsxfun(@times, C .^ 2, (1 + B * C) .^ 2))) .* ((2 * B * C + 1) .* log((I + eps) ./ (F + eps)) + 1), 1) + alpha_C/2);            
            C = max(C, 0);
            
            F = (A * C) ./ (1 + B * C);
            B = B - 0.5 * (sum(bsxfun(@rdivide, C, 1 + B * C) .* (log(I + eps) - log(F + eps)), 2) + alpha_B * B) ./ ...
                (sum(bsxfun(@times, C .^ 2, (1 + B * C) .^ 2) .* (log(F + eps) - log(I + eps) + 1), 2) + alpha_B);
            B = max(B, 0);
        elseif (alpha == 0)
            F = (A * C) ./ (1 + B * C);
            A = A - 0.5 * ((1 ./ (A + eps)) .* sum(((F + eps) .^ beta) .* log((F + eps) ./ (I + eps)), 2)) ./ ...
                ((1 ./ (eps + A .^ 2)) .* sum(((F + eps) .^ beta) .* ((beta - 1) * log((F + eps) ./ (I + eps)) + 1), 2));
            A = max(A, 0);
            
            F = (A * C) ./ (1 + B * C);
            C = C - 0.5 * (sum(((F + eps) .^ (beta + 1)) .* log((F + eps) ./ (I + eps)) .* (1 ./ (eps + A * (C .^ 2))), 1) + alpha_C * C) ./ ...
                (sum((1 ./ (eps + bsxfun(@times, C .^ 2, (1 + B * C) .^ 2))) .* ((F + eps) .^ beta) .* ...
                (1 - (2 * B * C - beta + 1) .* log((F + eps) ./ (I + eps))), 1) + alpha_C/2);
            C = max(C, 0);
            
            F = (A * C) ./ (1 + B * C);
            B = B + 0.5 * (alpha_B * B + (1 ./ (A + eps)) .* sum(((F + eps) .^ (beta + 1)) .* log((F + eps) ./ (I + eps)), 2)) ./ ...
                (sum(bsxfun(@rdivide, C .^ 2, (1 + B * C) .^ 2) .* ((F + eps) .^ beta) .* ...
                ((beta + 1) * log((F + eps) ./ (I + eps)) + 1), 2) + alpha_B/2);
            B = max(B, 0);
        elseif (beta == 0)
            A = (sum(I .^ alpha, 2) ./ sum(bsxfun(@rdivide, C, 1 + B * C) .^ alpha, 2)) .^ (1 / alpha);
            A = max(A, 0);
            
            C = C - 0.5 * (sum(((((A * C) ./ (1 + B * C)) .^ alpha) - I .^ alpha) ./ ...
                bsxfun(@times, C, 1 + B * C), 1) + alpha_C * C) ./ ...
                (sum(((alpha - 1 - 2 * B * C) .* (((A * C) ./ (1 + B * C)) .^ alpha) + ...
                (1 + 2 * B * C) .* (I .^ alpha)) ./ ...
                bsxfun(@times, C .^ 2, (1 + B * C) .^ 2), 1) + alpha_C/2);
            C = max(C, 0);
            
            B = B - 0.5 * (sum(bsxfun(@times, C, I .^ alpha - ((A * C) ./ (1 + B * C)) .^ alpha) ./ ...
                (1 + B * C), 2) + alpha_B * B) ./ ...
                (sum(bsxfun(@times, C .^ 2, (alpha + 1) * ((A * C) ./ (1 + B * C)) .^ alpha - I .^ alpha) ./ ...
                ((1 + B * C) .^ 2), 2) + alpha_B/2);
            B = max(B, 0);
        elseif (alpha == -beta)
            A = ((1 / size(I, 2)) * sum(bsxfun(@rdivide, I .* (1 + B * C), C) .^ alpha, 2)) .^ (1 / alpha);
            A = max(A, 0);
            
            C = C - 0.5 * (sum((1 - ((I .* (1 + B * C)) ./ (A * C)) .^ alpha) ./ bsxfun(@times, C, 1 + B * C), 1) + alpha_C * C)./ ...
                (sum(((((I .* (1 + B * C)) ./ (A * C)) .^ alpha) .* (2 * B * C + alpha + 1) - 2 * B * C - 1) ./ ...
                bsxfun(@times, C .^ 2, (1 + B * C) .^ 2), 1) + alpha_C/2);
            C = max(C, 0);
            
            B = B - 0.5 * (sum((bsxfun(@rdivide, I, A) .^ alpha) .* (bsxfun(@rdivide, 1 + B * C, C) .^ (alpha - 1)) - ...
                bsxfun(@rdivide, C, 1 + B * C), 2) + alpha_B * B) ./ ...
                (sum((alpha - 1) * ((bsxfun(@rdivide, I, A) .^ alpha) .* (bsxfun(@rdivide, 1 + B * C, C) .^ (alpha - 2))) + ...
                bsxfun(@rdivide, C, 1 + B * C) .^ 2, 2) + alpha_B / 2);
            B = max(B, 0);
        else
            % optimizing A
            F = bsxfun(@rdivide, C, 1 + B * C);
            A = (sum((I .^ alpha) .* (F .^ beta), 2) ./ sum(F .^ (alpha + beta), 2)) .^ (1 / alpha);
            A = max(A, 0);

            % optimizing C
            F = (A * C) ./ (1 + B * C);
            C = C - 0.5 * (sum((1 ./ (A * (C .^ 2))) .* (F .^ (beta + 1)) .* (I .^ alpha - F .^ alpha), 1) + alpha_C * C) ./ ...
                (sum((1 ./ bsxfun(@times, C .^ 2, (1 + B * C) .^ 2)) .* (F .^ beta) .* ((F .^ alpha) .* (2 * B * C - alpha - beta + 1) - ...
                (I .^ alpha) .* (2 * B * C - beta + 1)), 1) + alpha_C/2);
            C = max(C, 0);

            % optimizing B
            F = (A * C) ./ (1 + B * C);
            B = B + 0.5 * ((1 ./ A) .* sum((F .^ (beta + 1)) .* (I .^ alpha - F .^ alpha), 2) + alpha_B * B) ./ ...
                (sum(bsxfun(@rdivide, C .^ 2, (1 + B * C) .^ 2) .* (F .^ beta) .* ((beta + 1) * (I .^ alpha) - ...
                (alpha + beta + 1) * (F .^ alpha)), 2) + alpha_B/2);
            B = max(B, 0);
        end
             
        
        % routines
        [A, B, C] = nonlinear_normalize_prod(A, B, C);
        
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
        
        if (use_term_criteria && nonlinear_check_stopping_criteria(I, Q, currQuality, prevQuality, eps))
            break;
        end
        prevQuality = currQuality;
        %if (currIter > 10000)
        %    break;
        %end
        fprintf('%d: %f\n', currIter, currQuality);
        %fprintf('%d: %e\n', currIter, C(525));
        
    end
    
    %isConverged = (currIter < maxIterCnt);
    
    A(isnan(A)) = 0;
    C(isnan(C)) = 0;
end

function [a1 a2] = fff(c, f_cost, f_grad)
    a1 = f_cost(c);
    a2 = f_grad(c);
end

function X_new = projected_grad(X, maxIterCnt, eps, cost_func, grad_func)
    sigma = 1/4;
    eta_dec = 0.5;
    eta_init = max(1000 * max(X), 1);
    
    prevCost = -1;
    for currIter = 1:maxIterCnt
        currCost = cost_func(X);
        currGrad = grad_func(X);
        
        if (sum(sum(abs(currGrad))) < eps)
            break;
        end
        if (currIter > 1 && prevCost - currCost < eps)
            break;
        end
        prevCost = currCost;
        
        eta = eta_init;
        while (eta > eps)
            X_new = max(X - eta * currGrad, 0);
            
            newCost = cost_func(X_new);
            
            armijo_cond = ((newCost - currCost) <= sigma * (currGrad(:)' * (X_new(:) - X(:))));
            if armijo_cond
                break;
            else
                eta = eta * eta_dec;
            end
        end
        
        X = X_new;
        
        break;
    end
    
    X_new = X;
end

function B_new = projected_grad_B(I, A, B, C, alpha, beta, maxIterCnt, eps)
    sigma = 1/4;
    eta_dec = 0.5;
    eta_init = max(1000 * max(B), 1);
    
    prevCost = -1;
    for currIter = 1:maxIterCnt
        currCost = nmf_alpha_beta_divergence(I, langmuir_func(A, B, C), alpha, beta);
        currGrad = nonlinear_alpha_beta_grad_B(I, A, B, C, alpha, beta);
        
        if (sum(sum(abs(currGrad))) < eps)
            break;
        end
        if (currIter > 1 && prevCost - currCost < eps)
            break;
        end
        prevCost = currCost;
        
        eta = eta_init;
        while (eta > eps)
            B_new = max(B - eta * currGrad, 0);
            
            newCost = nmf_alpha_beta_divergence(I, langmuir_func(A, B_new, C), alpha, beta);
            
            armijo_cond = ((newCost - currCost) <= sigma * (currGrad(:)' * (B_new(:) - B(:))));
            if armijo_cond
                break;
            else
                eta = eta * eta_dec;
            end
        end
        
        B = B_new;
        %prevCost = newCost;
        break;
    end
    
    B_new = B;
end

function grad = nonlinear_alpha_beta_grad_B_special(I, A, B, C)
    grad = -sum( ((A * C) ./ I - (1 + B * C)) .* bsxfun(@rdivide, C, (1 + B * C) .^ 2), 2);
end

function grad = nonlinear_alpha_beta_grad_C_special(I, A, B, C)
    grad = sum( (bsxfun(@rdivide, A, I) - bsxfun(@rdivide, 1 + B * C, C)) .* bsxfun(@rdivide, 1, (1 + B * C) .^ 2), 1);
end

% function grad = nonlinear_alpha_beta_grad_B(I, A, B, C, alpha, beta)
%     F = (A * C) ./ (1 + B * C);
%     D = (A * (C .^ 2)) ./ ((1 + B * C) .^ 2);
%     grad = sum(-(((I + eps) .^ alpha) .* ((F + eps) .^ (beta - 1)) .* D) + ...
%         ((F + eps) .^ (alpha + beta - 1) .* D), 2);
% end