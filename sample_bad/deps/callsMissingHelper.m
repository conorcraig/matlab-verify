function cleaned = callsMissingHelper(values)
%CALLSMISSINGHELPER Calls a function that exists nowhere.
arguments
    values (:,1) double
end
arguments (Output)
    cleaned (:,1) double
end
cleaned = removeSpikesHelper(values);
end
