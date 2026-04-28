function [result, sigma] = exampleMath(values, scale, useBias)
%EXAMPLEMATH Aggregate a numeric vector with an optional scale factor.
%   [RESULT, SIGMA] = EXAMPLEMATH(VALUES, SCALE, USEBIAS) returns the scaled
%   sum of VALUES along with its standard deviation. When USEBIAS is true a
%   small bias term is added to the result so the function exercises a
%   branch that the auto-generated unit test should still execute cleanly.
%
%   This file is provided as a demonstration target for matlabutscript and
%   carries no operational significance.
%
%   Example:
%       [r, s] = exampleMath([1 2 3 4 5], 2.0, true);

    arguments
        values  (1,:) double {mustBeNonempty}
        scale   (1,1) double = 1.0
        useBias (1,1) logical = false
    end

    result = sum(values) * scale;
    sigma  = std(values);

    if useBias
        result = result + 1e-3;
    end
end
