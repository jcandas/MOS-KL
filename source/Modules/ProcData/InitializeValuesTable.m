function VT = InitializeValuesTable(varargin)


%% Parse Name-Value Pairs
Names = varargin(1:2:end);
Values = varargin(2:2:end);
ValidNames = {'Balance', 'Kernel', 'Eigenspace', 'Algorithm', 'Label'};

isValidName = cellfun(@(x) ischar(x) || isstring(x), Names);
isValidValue = cellfun(@iscell, Values);

%assert( all(ismember(Names, ValidNames)), 'Invalid Name Argument');
assert(length(Names) == length(Values), 'Invalid Name-Value pair');
assert(all(isValidName), 'Names must be string or character arrays');
assert(all(isValidValue), 'Values must be cell arrays');

%% Compute ALL combinations of parameters
C = cell(size(Values));
[C{:}] = ndgrid(Values{:});
fun = @(i) [C{i}(:)];
D = arrayfun(fun, 1:length(Values), 'UniformOutput', false);
D = [D{:}];

VT = cell2table(D);
VT.Properties.VariableNames = Names;

%% Delete superfluous rows

del = false([height(VT), 1]);
if any(contains(Names, 'Eigenspace')) & any(contains(Names, 'Algorithm'))
del = del | ismember(VT.Algorithm, [0,1,4]) & strcmp(VT.Eigenspace, 'largest'); % Benchmark and MLS don't need eigenspace parameter
end

if any(contains(Names, 'Balance')) & any(contains(Names, 'Algorithm'))
del = del | ismember(VT.Algorithm, [1 4]) & VT.Balance == true; % Benchmark doesn't need unbalanced
end

if any(contains(Names, 'Kernel')) && any(contains(Names, 'Algorithm'))
del =  del | ismember(VT.Algorithm, [1 4]) & VT.Kernel == true; %Benchmark doesn't need kernel parameter
end

if any(contains(Names, 'Nesting')) && any(contains(Names, 'Algorithm'))
del =  del | ismember(VT.Algorithm, [1 4]) & ismember(VT.Nesting, [0,2]); %Benchmark doesn't need nesting parameter
end

%del = del | del2 | del3;

VT(del,:) = [];
end