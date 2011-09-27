function q = minus(l, r)
% -   Minus.
% (Quaternion overloading of standard Matlab function.)

% Copyright � 2005 Stephen J. Sangwine and Nicolas Le Bihan.
% See the file : Copyright.m for further details.

error(nargchk(2, 2, nargin)), error(nargoutchk(0, 1, nargout)) 

q = plus(l, -r); % We use uminus to negate the right argument.
