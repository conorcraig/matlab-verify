function label = classifyReading(code, value)
%CLASSIFYREADING Long if/elseif chain: cyclomatic complexity above 10.
arguments
    code (1,1) double
    value (1,1) double
end
arguments (Output)
    label (1,1) string
end
if code == 1 && value > 0
    label = "pressure-high";
elseif code == 1
    label = "pressure-low";
elseif code == 2 && value > 0
    label = "flow-high";
elseif code == 2
    label = "flow-low";
elseif code == 3 && value > 0
    label = "temp-high";
elseif code == 3
    label = "temp-low";
elseif code == 4 || value < -100
    label = "fault";
elseif code == 5
    label = "idle";
else
    label = "unknown";
end
end
