function v = vec( x )
%VEC - Vectorize.
%    VEC(X), where X is a vector, matrix, or N-D array, returns a column vector
%    containing all of the elements of X; i.e., VEC(X)=X(:).

v = reshape( x, numel( x ), 1 );

% Copyright 2012 CVX Research, Inc.
% See the file COPYING.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
