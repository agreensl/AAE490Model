function [ t_crusie_min ] = cruiseTime(A_cover, h_cruise, v_cruise, image_fov,  num_drones, num_days)
%cruiseTime.m 
%
% Description: 
%   Calculate the required crusie velocity of a single drone to cover a
%   certain fixed area with a given mission profile and sensor properties
%
% Inputs: 
%   A_cover - Required abount of surface that needs to be covered by all drones [m^2]
%   h_cruise - Cruise altitude above the surface [m]
%   v_cruise - Desired criuse velocity [m/s], 
%   image_fov - Left to right field of view (full sweep) angle of the sensor [deg]   
%   num_drones - Total number of drones used to cover the area   
%   num_days - Total number of sols where flights occur 
%
% Outputs:
%   t_crusie_min - Required cruise time per Martian sol to completely cover given area [min]
% 
% ASSUMPTIONS:
%   Constant cruise velociy 
%   Constant cruise altituce above the surface
%   Full utilization of field of view angle from sensors 
%   No backtracking, overlap, or repeat coverage of sensor passes 
% 

image_w = 2 * h_cruise * tand(image_fov/2); % Field of view width on the ground [m]

t_crusie_sec = A_cover/(image_w * v_cruise * num_drones * num_days);    % [sec] Number of seconds each drone must fly per day 
 
t_crusie_min = t_crusie_sec / 60;   % convert output to [min]

end
