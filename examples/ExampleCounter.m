classdef ExampleCounter < handle
%EXAMPLECOUNTER Simple counter class used as a matlabutscript demo target.
%   Provides a constructor, increment / decrement / reset methods and a
%   read-only Count property so the auto-generated test class exercises
%   constructor, instance method and static method paths.

    properties (SetAccess = private)
        Count   (1,1) double = 0
        Limit   (1,1) double = Inf
    end

    methods
        function obj = ExampleCounter(initial, limit)
            arguments
                initial (1,1) double = 0
                limit   (1,1) double = Inf
            end
            obj.Count = initial;
            obj.Limit = limit;
        end

        function value = increment(obj, step)
            arguments
                obj
                step (1,1) double = 1
            end
            obj.Count = min(obj.Count + step, obj.Limit);
            value = obj.Count;
        end

        function value = decrement(obj, step)
            arguments
                obj
                step (1,1) double = 1
            end
            obj.Count = obj.Count - step;
            value = obj.Count;
        end

        function reset(obj)
            obj.Count = 0;
        end
    end

    methods (Static)
        function s = describe()
            s = "ExampleCounter — bounded integer counter for matlabutscript demos.";
        end
    end
end
