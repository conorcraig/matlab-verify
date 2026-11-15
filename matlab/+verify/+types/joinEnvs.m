function env = joinEnvs(envs)
%JOINENVS Join environments at a control-flow merge; a variable missing on any path becomes top.
arguments (Input)
    envs (1,:) cell
end
arguments (Output)
    env (1,1) struct
end
env = envs{1};
for k = 2:numel(envs)
    other = envs{k};
    names = union(string(fieldnames(env)), string(fieldnames(other)));
    merged = struct();
    for name = reshape(names, 1, [])
        if isfield(env, name) && isfield(other, name)
            merged.(name) = verify.types.joinTypes(env.(name), other.(name));
        else
            merged.(name) = verify.types.make();
        end
    end
    env = merged;
end
end
