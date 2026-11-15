function addHandlers(m, keys, handler)
%ADDHANDLERS Register HANDLER under each key in the containers.Map M.
arguments (Input)
    m (:,1) containers.Map
    keys (1,:) cell
    handler (1,1) function_handle
end
for k = 1:numel(keys)
    m(keys{k}) = handler;
end
end
