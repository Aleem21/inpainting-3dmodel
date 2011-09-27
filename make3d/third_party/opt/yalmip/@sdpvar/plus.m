function y = plus(X,Y)
%PLUS (overloaded)

% Author Johan L�fberg
% $Id: plus.m,v 1.20 2006/07/26 20:17:58 joloef Exp $

X_is_spdvar = isa(X,'sdpvar');
Y_is_spdvar = isa(Y,'sdpvar');

% Convert block objects
if ~X_is_spdvar
    if isa(X,'blkvar')
        X = sdpvar(X);
        X_is_spdvar = isa(X,'sdpvar');
    elseif ~isa(X,'double')
        error(['Cannot add SDPVAR object and ' upper(class(X)) ' object']);
    end
end

if ~Y_is_spdvar
    if isa(Y,'blkvar')
        Y = sdpvar(Y);
        Y_is_spdvar = isa(Y,'sdpvar');;
    elseif ~isa(Y,'double')
         error(['Cannot add SDPVAR object and ' upper(class(Y)) ' object']);
    end
end


switch 2*X_is_spdvar+Y_is_spdvar
    case 1
        if isempty(X)
            try
                y = full(X - reshape(Y.basis(:,1),Y.dim(1),Y.dim(2)));
            catch
                error(lasterr);
            end
            return
        end

        y = Y;
        n_Y = Y.dim(1);
        m_Y = Y.dim(2);
        [n_X,m_X] = size(X);
        x_isscalar = (n_X*m_X==1);
        y_isscalar = (n_Y*m_Y==1);
        any_scalar = x_isscalar | y_isscalar;
        
        if x_isscalar & y_isscalar            
             y.basis(1) = y.basis(1)+X;
             % Reset info about conic terms
             y.conicinfo = [0 0];
             return
         end
         
        if any_scalar | ([n_Y m_Y]==[n_X m_X])
            if y_isscalar
                y.basis = repmat(y.basis,n_X*m_X,1);
                y.dim(1) = n_X;
                y.dim(2) = m_X;
            end
            y.basis(:,1) = y.basis(:,1)+X(:);
        else
            error('Matrix dimensions must agree.');
        end
        % Reset info about conic terms
        y.conicinfo = [0 0];

    case 2

        if isempty(Y)
            try
                y = full(reshape(X.basis(:,1),X.dim(1),X.dim(2))-Y);
            catch
                error(lasterr);
            end
            return
        end

        y = X;
        n_X = X.dim(1);
        m_X = X.dim(2);
        [n_Y,m_Y] = size(Y);
        x_isscalar = (n_X*m_X==1);
        y_isscalar = (n_Y*m_Y==1);
        any_scalar = x_isscalar | y_isscalar;
        
         % Special special case...
         if x_isscalar & y_isscalar
             y.basis(1) = y.basis(1)+Y;
             % Reset info about conic terms
             y.conicinfo = [0 0];
             return
         end
         
        if any_scalar | ([n_Y m_Y]==[n_X m_X])
            if x_isscalar
                y.basis = repmat(y.basis,n_Y*m_Y,1);
                y.dim(1) = n_Y;
                y.dim(2) = m_Y;
            end
            y.basis(:,1) = y.basis(:,1)+Y(:);
        else
            error('Matrix dimensions must agree.');
        end
        % Reset info about conic terms
        y.conicinfo = [0 0];

    case 3

        n_X = X.dim(1);
        m_X = X.dim(2);
        n_Y = Y.dim(1);
        m_Y = Y.dim(2);
        x_isscalar = (n_X*m_X==1);
        y_isscalar = (n_Y*m_Y==1);
        any_scalar = x_isscalar | y_isscalar;

        if (~((n_X==n_Y) & (m_X==m_Y))) & ~any_scalar
            error('Matrix dimensions must agree.')
        end

        all_lmi_variables = uniquestripped([X.lmi_variables Y.lmi_variables]);
        y = X;
        X.basis = [];
        y.lmi_variables = all_lmi_variables;

        % ismembc faster (buggy?)
        in_X = find(ismembc(all_lmi_variables,X.lmi_variables));
        in_Y = find(ismembc(all_lmi_variables,Y.lmi_variables));
        % in_X = find(ismember(all_lmi_variables,X.lmi_variables));
        % in_Y = find(ismember(all_lmi_variables,Y.lmi_variables));

        if isequal(X.lmi_variables,Y.lmi_variables) & n_Y==n_X & m_Y==m_X
            y.basis = y.basis + Y.basis;
             if length(X.lmi_variables)==1
                 if all(y.basis(:,2)==0)
                     y = full(y.basis(1));
                 else
                     % Reset info about conic terms
                     y.conicinfo = [0 0];
                 end
                return
            end
        else
            if 1
                [ix,jx,sx] = find(y.basis);y.basis = [];
                [iy,jy,sy] = find(Y.basis);Y.basis = [];
                mapX = [1 1+in_X];
                mapY = [1 1+in_Y];
                basis_X = sparse(ix,mapX(jx),sx,n_X*m_X,1+length(all_lmi_variables));ix=[];jx=[];sx=[];
                basis_Y = sparse(iy,mapY(jy),sy,n_Y*m_Y,1+length(all_lmi_variables));iy=[];jy=[];sy=[];
            else
                % MATLAB sparse fails on this for huge problems at a certain size
                basis_X = spalloc(n_X*m_X,1+length(all_lmi_variables),nnz(X.basis));
                basis_Y = spalloc(n_Y*m_Y,1+length(all_lmi_variables),nnz(Y.basis));
                basis_X(:,[1 1+in_X])=y.basis;y.basis = [];
                basis_Y(:,[1 1+in_Y])=Y.basis;Y.basis = [];
            end

            % Fix addition of matrix+scalar
            if n_X*m_X<n_Y*m_Y
                y.dim(1) = n_Y;
                y.dim(2) = m_Y;
                basis_X = repmat(basis_X,n_Y*m_Y,1);
            end
            if n_Y*m_Y<n_X*m_X
                y.dim(1) = n_X;
                y.dim(2) = m_X;
                basis_Y = repmat(basis_Y,n_X*m_X,1);
            end
            % OK, solution is...
            y.basis = basis_X;basis_X = [];
            y.basis = y.basis+basis_Y;basis_Y = [];
        end
        % Reset info about conic terms
        y.conicinfo = [0 0];
        y = clean(y);

    otherwise
end


