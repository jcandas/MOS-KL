function [Yout, LevelSizes] = BinarySVD2(X,Y)
%BinarySVD generates a random tall matrix and expresses it in the
%left singular basis of X
%
%BinarySVD(X) expresses X in the left singular basis of X
%
%BinarySVD(X,Y) expresses Y in the left singular basis of X
%BinarySVD(X, {Y1, Y2, ...}) expresses each matrix in {Y1, Y2,...} in the
%left singular basis of X. 
%Yout = {Yout1, Yout2,...} = {Y1, Y2,...} in left singular basis of X
%LevelSizes = dimension of each orthogonal subspace
close all

if nargin == 0
    X = rand(2^15 + 192, 524);
    X = X - mean(X);
    Y = {X};
elseif nargin == 1
    Y = {X};
elseif nargin == 2
    if isnumeric(Y), Y = {Y}; end
    Z = [{X}, Y];
    numrows = cellfun(@(x) size(x,1), Z);
    assert( all(numrows == numrows(1)), 'all matrices must have the same number of rows')
end

numcols = cellfun(@(x) size(x,2), Y);
Breaks = [0 cumsum(numcols)];
Z2 = horzcat(Y{:});





%% 
nargoutchk(0,2)

%% Construct an orthonormal basis for the column space of X
[PhiMA,S,V] = svd(X, 'econ');

Zout = PhiMA' * Z2;
LevelSizes = [];

%% Construct orthonormal basis for each node in the Binary Tree
BinaryTree = ConstructBinaryTree(X);
for q = BinaryTree(1).nLevels:-1:0
    isLevel = [BinaryTree.depth] == q;
    nodes = BinaryTree(isLevel);

    
    for a = 1:length(nodes)
       
        Ba = nodes(a);
            
    if q == BinaryTree(1).nLevels
        Ea = Ba.E;
    else
       children = getChildren(BinaryTree, Ba.index);
       Ea = [children(1).Phi , children(2).Phi];
    end
        Ma = PhiMA'*Ea;
        [~,Sa,Va] = svd(full(Ma), 'vector'); 
        tol = max(size(Ma)) * eps(Sa(1));
        rankMa = find(Sa > tol, 1, 'last');
        VaR = Va(:,1:rankMa); VaN = Va(:,rankMa+1:end);
        nodes(a).E = Ea;
        nodes(a).Psi = sparse(Ea*VaN); nodes(a).Phi = sparse(Ea*VaR);

        Zout = [Zout ; nodes(a).Psi' * Z2]; 
    end
    % t1 = toc; fprintf('Time: %0.3f \n', t1-t0);

    BinaryTree(isLevel) = nodes;
    %LevelSize = size([nodes.Psi], 2); not supported for GPU arrays
    LevelSize = sum( arrayfun(@(x) size(x.Psi,2), nodes));
    LevelSizes = [LevelSizes LevelSize];
    if q < BinaryTree(1).nLevels
        BinaryTree([BinaryTree.depth] == q + 1) = [];
    end


    %% Get rid of extraneous information

end

Yout = cell(size(Y));
for i = 1:length(Breaks)-1
    ib = Breaks(i)+1:Breaks(i+1);
    Yout{i} = Zout(:,ib);
end

if isscalar(Y), Yout = Yout{1}; end
    
end

%=====================
%% Auxillary Functions
%=====================
function BinaryTree = ConstructBinaryTree(X)
[F,r] = size(X);
ZF = 1:F;
maxLevels = 3;
thresh = 2*r;
%thresh = r + 50;

BinaryTree = struct('nLevels',0, ...
                    'depth', 0,...
                    'index','0',...
                    'E',[],...
                    'P',ZF,...
                    'Phi',[],...
                    'Psi',[]);


keepDividing = arrayfun( @(BT) length(BT.P) > 2*thresh, BinaryTree );
nLevels = 0;
depth = 0;
while any(keepDividing)
   

    isLeaf = [BinaryTree.depth] == nLevels;
    Leaves = BinaryTree(isLeaf);
    children = [];
    for a = 1:length(Leaves)
        Leaf = Leaves(a);
        child = Leaf;
        %Set nLevels
        child.nLevels = nLevels + 1;
        %Set depth
        child.depth = Leaf.depth + 1;
         %Set Leaf indices
        leftChild = child; rightChild = child;
        leftChild.index = [Leaf.index, '0']; rightChild.index = [Leaf.index, '1'];
        %Set Partition indices
        np = length(child.P); np2 = floor(np/2);
        leftChild.P = Leaf.P(1:np2); rightChild.P = Leaf.P(np2+1:end);
        children = [children, leftChild, rightChild];
        BinaryTree = [BinaryTree, leftChild, rightChild];
    end

    keepDividing = any(arrayfun( @(BT) length(BT.P) >= 2*thresh, children ));
     nLevels = nLevels + 1;
end

%% Set field E in the leaves
isLeaf = [BinaryTree.depth] == nLevels;
Leaves = BinaryTree(isLeaf);
I = speye(F);
for a = 1:length(Leaves)
    Leaves(a).E = I(:,Leaves(a).P);
end
BinaryTree(isLeaf) = Leaves;

%% Set nLevels 
for inode = 1:length(BinaryTree)
    BinaryTree(inode).nLevels = nLevels;
end

end

%=====================

function children = getChildren(BinaryTree, index)
    iL = [index, '0']; iR = [index, '1'];
    isChild = strcmp({BinaryTree.index}, iL) | strcmp({BinaryTree.index}, iR);
    children = BinaryTree(isChild);  
end