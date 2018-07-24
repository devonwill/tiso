% get_reaction_forces.m
% Copyright Andrew P. Sabelhaus 2018

function [px, py, pz] = get_reaction_forces(coordinates, pinned, m, g)
% get_reaction_forces calculates the external reaction forces on a
% tensegrity structure under the influence of gravity.
%
% This function makes a variety of assumptions about the tensegrity in
% question and its problem setup. Do not use it unless you've ensured those
% assumptions hold (example - distribution of mass, etc.) See various
% papers by Friesen, Sabelhaus, etc. for more discussion.
%   
% Inputs:
%   coordiantes = 3 x n matrix of the coordinates of each node.
%   pinned = n x 1 vector, boolean, with 1 = reaction forces exist at that
%       node (i.e., it is pinned) or with = 0 free floating.
%   m = n x 1 vector of the mass of each individual node
%   g = gravitational constant.
%
% Outputs:
%   px = n x 1 vector of reaction forces in the x direction at each node
%   py = same, for y
%   pz = same, for z
%

% Steps:
%   1) problem setup
%   2) calculate the position of the center of mass of the whole structure
%   3) calculate the moment contribution of each reaction force
%   4) solve sum F = 0 and sum M = 0 via linear algebra
%   5) expand the solution back into the corresponding coordinates of the
%   nodes.

%% 1) 

% number of nodes
n = size(coordinates, 2);

% number of nodes that have reaction forces. Since 'pinned' is ones and
% zeros, can just count the number of ones.
s = sum(pinned);

% quick checks
if size(m) ~= n
    error('Error, mass vector should have same number of elements as the number of nodes.');
end

if s > n
    error('Error, the vector of pinned nodes is inconsistent with total number of nodes.');
end

% total mass is 
m_tot = sum(m);

% need to remove the no-reaction-forces elements from the 'coordinates'
% matrix to make computations easier down below.
% the result should now be 3 x s, reduced from 3 x n
coords_s = zeros(3, s);
% TO-DO: efficiency improvements. We can't rely on "remove the zeroed-out
% nodes" because there may be a force applied at a node with coordinates
% (0, 0, 0). So, keep a counter instead.
next_node = 1;
for i=1:n
    if pinned(i)
        coords_s(:, next_node) = coordinates(:, i);
        next_node = next_node + 1;
    end
end


%% 2)

% center of mass is at the sum of each coordinate * m_i divided by n.

% specifying the mass positions using linear algebra would need a tensor
% and I'm too busy to figure that out right now
mass_positions = zeros(size(coordinates));
for i=1:n
    mass_positions(:,i) = m(i) * coordinates(:,i);
end

% center of mass (com) is sum over each row, divide by n.
% com is 3 x 1.
com = sum(mass_positions, 2) ./ n;

%% 3)

% We're going to sum moments about the origin.

% As a note on matrix dimensions, we're looking at s reaction forces in 3
% dimensions each, so when solving A R = b, R is 3s x 1, b is 3 x 1, so A
% must be 3 x 3s.

% The moment due to the center of mass (having already evaluated the cross
% product) is nmg * COM in y or x respectively (there are n point masses)
mom_com = [ - n * m_tot * g * com(2);
            - n * m_tot * g * com(1);
              0];
        
% The left-hand side consists of the vectors from each force to the COM.
% Evaluating the cross product, we get the moment due to a force
% F = [Fx; Fy; Fz] at point [x; y; z] by the matrix equation A F, where
% A = [ 0,  -z, y;
%       z,  0,  -x;
%       -y, x,  0];
%
% Since we're treating the reaction forces as R = [Fx1, Fx2, ... Fxs, Fy1,
% ...], we'll do the sum of moments for example in x for all forces as
% [ 0_s, -z_1 ... -zs, y1 ... ys]

% left-hand side size is 3 x 3s
% insert individual components. coords_s(1, i) is x-coord for node i =
% 1...s (the ones with reaction forces.)

mom_reactions_coeff = [  zeros(1, s),    -coords_s(3, :),   coords_s(2,:);
                         coords_s(3,:),   zeros(1, s),     -coords_s(1,:);
                        -coords_s(2,:),   coords_s(1,:),    zeros(1,s)];

%% 4)

% Set up the total problem. we need to do the force balance (pretty
% trivial) to stack with the moment balance

force_com = [ 0; 0; -n * m_tot * g]; % 3 x 1
% sum the forces along each dimension. Similar to the moments except no
% coordinates.
% also is size 3 x 3s
force_reactions_coeff = [ ones(1, s),   zeros(1, s),    zeros(1, s);
                          zeros(1, s),  ones(1, s),     zeros(1, s);
                          zeros(1, s),  zeros(1, s),    ones(1, s)];

% Then, the left-hand-side and right-hand-side matrices are
A = [force_reactions_coeff; mom_reactions_coeff];
b = [force_com; mom_com];

% FINALLY, solve:

% TO-DO: could actually formulate this as a minimization problem since it's
% statically indeterminate (e.g. nonzero null space, there are *many* more
% rows than columns since 3s > 6 for almost all applications because at
% least two nodes would be pinned), so could minimize the 2-norm of force.
% Currently unknown if this has any effect on the inverse kinematics
% solution.
                    
end







