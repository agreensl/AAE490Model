clear;close all;clc

% DESCRIPTION: Calculate available payload mass and total mass of a single
% drone based on a number of design parameters Also estimate masses of
% indivudial components of the propulsion system for a single drone 
% NOTE: Use this "simplified" script if the radius of the blade and all 
% other aerodynamic parameters is already known. This script removes the 
% radiusOpt function to make things more streamlined. 


% Vehicle Design Inputs
    mass_total = 60;     % Total vehicle mass including payload [kg] 

% Aerodynamic/rotor parameters
    numProp = 4;          % Total number of propeller/motor combinations (4 for quadcopter) 
    solidity = 0.32;                    % Blade Solidity
    k = 1.2;                        % Aerodynamic correction factor
    tipMach = 0.7;                      % Tip Mach Number, chosen to be fixed value
    Cd_blade_avg = 0.077;               % Average Drag Coefficient for blade
    blade_radius = 0.65;               % Blade radius [m]
    mass_blades = 8.00;                   % Estimated Mass of all blades [kg]
    A_body = 1;                     % [m^2] Estimated frontal area of vehicle
    Cd_body = 2;                    % Estimated drag coefficient of vehcile (rectangular box)

% Electronics Parameters
    V_batt = 43.7377;                   % Battery voltage [V]
    V_motor = 43.2;                     % Motor Voltage [V]
    mass_one_ESC = 0.25;                    % Approximate mass of electronic speed controller [kg]
    motor_eff = 0.85;                   % Efficency factor between mechancial power and electrical power (= P_mech/P_elec)
    
% Mission Profile Parameters
    A_cover = pi * 25000^2;     % Required total coverage area [m^2] 
    h_cruise = 300;             % Cruise altitude above the Martian surface [m]
    v_cruise = 30;              % Planned cruise velocity [m/s]
    sensor_fov = 54;            % Left to right field of view angle (full sweep) of the sensor [deg]
    num_drones = 6;             % Total number of drones used for surveying 
    num_days = 90;              % [sols] Number of Martian sols required to complete surveying area  
    drone_vert_rate = 10;       % [m/s]  Estimated ascent/descent rate of drone to/from cruise altitude
    accel_vert = 1;             % [m/s^2] vertical acceleration
    accel_forward = 2;          % [m/s^2] horizontal acceleration
    beta_cruise = 10;           % [deg]  Angle of tilt from horizontal of rotor disk in forward flight
    beta_accel = 15;            % [deg]  Angle of tilt from horizontal of rotor disk in forward flight

% Solar Flux Parameters 
    mission_lat = 18;           % [deg] Geographic latitude of the mission on Mars Surface (Range between -90 and 90 deg)
    solar_lon = 275;            % [deg] (NOT MARTIAN SOLS) Angular position of Mars around the Sun based on time of year (0 deg corresponds to northern vernal equinox)

% Constants
    a = 240;                        % speed of sound, m/s
    g_m = 3.71;                     % Gravity on mars, m/s^2
  
  
%%%%%%%%%%%%%%%%%%%%%%%% CALCULATIONS %%%%%%%%%%%%%%%%%%%%%%%%
% Preliminary Calculations
    weight_one_rotor =  mass_total * g_m /numProp;  % [N] weight that each rotor must support in hover 
    rho_cruise = rhoMars(h_cruise);        % air density on mars [kg/m^3]
    rho_vert = rhoMars(h_cruise/2);        % use average air density for climb/descent


% Calculate solar flux available with the given conditions  
    [ solar_flux, sun_time ] = solarFlux(mission_lat, solar_lon);     % Average solar flux on Martian surface (assumed constant) [W/m^2] and % Hours of useful sunlight on Martian surface [hr]
    
% Find required flight time
    t_accel_decel_forward = 2*v_cruise/accel_forward; % time to accelerate and decelerate to/from cruise velocity [s]
    t_accel_decel_vert = 4*drone_vert_rate/accel_vert; % time to accelerate and decelerate to/from vertical velocity (includes climb and descent) [s]
    distance_accel_vert = 0.5 * drone_vert_rate * t_accel_decel_vert; % distance travelled during vertical acceleration/deceleration (includes climb and descent) [m]
    t_cruise = cruiseTime(A_cover, h_cruise, v_cruise, sensor_fov, num_drones, num_days, t_accel_decel_forward);     % Required Flight Time [min]
    t_flight = t_cruise + t_accel_decel_forward/60 + t_accel_decel_vert/60 + 2*((h_cruise - 0.5*distance_accel_vert)/drone_vert_rate)/60;    % Add fixed number of minutes for climb/descent [min]
    t_flight_hr = t_flight/60;    % Convert flight time from [min] to [hr]

 % Power calculations
    % Calculate Power to Hover
    [fig_merit, P_hover, omega] = Power_Hover(weight_one_rotor, rho_cruise, blade_radius, k, a, tipMach, Cd_blade_avg, solidity);
    
    % Caluclate Power to Climb
    [P_climb, P_climb_accel, omega_climb, Time_climb_hr, t_climb_accel_hr] = Power_Climb(weight_one_rotor, rho_vert, blade_radius, a, tipMach, Cd_blade_avg, solidity, drone_vert_rate, h_cruise, A_body, Cd_body, accel_vert, numProp);

    % Calculate Power to Descend
    [P_descend, Time_descend_hr, t_descend_accel_hr] = Power_Descend(weight_one_rotor, rho_vert, blade_radius, a, tipMach, Cd_blade_avg, solidity, drone_vert_rate, h_cruise, A_body, Cd_body, numProp, accel_vert);

    % Calculate Power for Forward Flight
    [P_forward, P_forward_accel, t_forward_accel_hr] = Power_Forward_Flight(weight_one_rotor, rho_cruise, blade_radius, k, a, tipMach, Cd_blade_avg, solidity, beta_cruise, beta_accel, v_cruise, accel_forward);
    
    % Total Hover Power
    P_mech_total_hover = numProp * P_hover;                         % Multiply power to account for multiple rotors
    P_mech_one_motor_hover = P_mech_total_hover/numProp;
    P_elec_total_hover = P_mech_total_hover/motor_eff;              % Convert from mechanical to electrical power
    P_elec_one_motor_hover = P_mech_one_motor_hover/motor_eff;      % Convert from mechanical to electrical power
    
    % Total Climb Power
    P_mech_total_climb = numProp * P_climb;
    P_mech_one_motor_climb = P_mech_total_climb/numProp;
    P_elec_total_climb = P_mech_total_climb/motor_eff;              % Convert from mechanical to electrical power
    P_elec_one_motor_climb = P_mech_one_motor_climb/motor_eff;      % Convert from mechanical to electrical power
    
    % Total Climb Accel/Decel Power
    P_mech_total_climb_accel = numProp * P_climb_accel;
    P_mech_one_motor_climb_accel = P_climb_accel;
    P_elec_total_climb_accel = P_mech_total_climb_accel/motor_eff;              % Convert from mechanical to electrical power
    P_elec_one_motor_climb_accel = P_mech_one_motor_climb_accel/motor_eff;      % Convert from mechanical to electrical power
    
    % Total Descent Power
    P_mech_total_descend =  numProp * P_descend;
    P_mech_one_motor_descend = P_mech_total_descend/numProp;
    P_elec_total_descend = P_mech_total_descend/motor_eff;                      % Convert from mechanical to electrical power
    P_elec_one_motor_descend = P_mech_one_motor_descend/motor_eff;              % Convert from mechanical to electrical power
    
    % Total Descent Accel/Decel Power
    P_mech_total_descend_accel = numProp * P_hover;                             % Estimate max descent accel power as power required to hover
    P_mech_one_motor_descend_accel = P_mech_total_descend_accel/numProp;
    P_elec_total_descend_accel = P_mech_total_descend_accel/motor_eff;
    P_elec_one_motor_descend_accel = P_mech_one_motor_descend_accel/motor_eff;
    
    % Total Forward Flight Power
    P_mech_total_forward =  numProp * P_forward;
    P_mech_one_motor_forward = P_mech_total_forward/numProp;
    P_elec_total_forward = P_mech_total_forward/motor_eff;     % Convert from mechanical to electrical power
    P_elec_one_motor_forward = P_mech_one_motor_forward/motor_eff;     % Convert from mechanical to electrical power
    
    P_mech_total_forward_accel = numProp * P_forward_accel;
    P_mech_one_motor_forward_accel = P_mech_total_forward_accel/numProp;
    P_elec_total_forward_accel = P_mech_total_forward_accel/motor_eff; 
    P_elec_one_motor_forward_accel = P_mech_one_motor_forward_accel/motor_eff;
    
    torque = P_mech_total_climb/omega_climb;
    
    % NEED TOTAL or MAX?
    P_mech_total = max([P_mech_total_hover, P_mech_total_climb, P_mech_total_descend, P_mech_total_forward, P_mech_total_climb_accel, P_mech_total_descend_accel, P_mech_total_forward_accel]);
    P_elec_total = P_mech_total/motor_eff;
    I_draw = P_elec_total/V_motor;  % Current thru motor [Amps]
    Power_consumption_array = [P_elec_one_motor_hover, P_elec_one_motor_climb, P_elec_one_motor_climb_accel, P_elec_one_motor_descend, P_elec_one_motor_descend_accel, P_elec_one_motor_forward, P_elec_one_motor_forward_accel];
    Max_power_elec = max(Power_consumption_array);
    P_mech_one_motor = P_mech_total/numProp;    % Caculate mech. and elec. powers per motor [W]
    P_elec_one_motor = P_elec_total/numProp;
    
% Calculate battery capacity according to each stage in the flight
    cap_batt_climb = capacityBattery( P_elec_total_climb, V_batt, Time_climb_hr, I_draw );     % Estimated battery capacity [A*hr]
    cap_batt_climb_accel = capacityBattery( P_elec_total_climb_accel, V_batt, t_climb_accel_hr, I_draw );
    cap_batt_descend = capacityBattery( P_elec_total_descend, V_batt, Time_descend_hr, I_draw);     % Estimated battery capacity [A*hr]
    cap_batt_descend_accel = capacityBattery( P_elec_total_descend_accel, V_batt, t_descend_accel_hr, I_draw);
    cap_batt_forward = capacityBattery( P_elec_total_forward, V_batt, t_flight_hr, I_draw); 
    cap_batt_forward_accel = capacityBattery( P_elec_total_forward_accel, V_batt, t_forward_accel_hr, I_draw); 
    cap_batt = 1.2*(cap_batt_forward + cap_batt_climb + cap_batt_climb_accel + cap_batt_descend + cap_batt_descend_accel + cap_batt_forward_accel);
    
    mass_batt = massBattery(cap_batt, V_batt);                          % Mass of the battery required

   
   
    
% Select motor mass based on RimFire Brushless Outrunner Motor specs (https://www.greatplanes.com/motors/gpmg4505.php)
    if  P_elec_one_motor < 1800   
        mass_motor = (P_elec_one_motor*7e-5 + 0.2135) * 2;   % Rough correlation for motor mass 
                                                     % ^^^  Multiplied by 2 to achieve a more accurate estimation 
    elseif  P_elec_one_motor >= 1800 && P_elec_one_motor < 2500
        mass_motor = 0.634;    % [kg]   2500 W motor mass
    elseif  P_elec_one_motor >= 2500 && P_elec_one_motor < 5000    
        mass_motor = 1.25;     % [kg]   5000 W motor mass
    elseif  P_elec_one_motor >= 5000 && P_elec_one_motor < 6500 
        mass_motor = 1.48;     % [kg]   6500 W motor mass
    elseif  P_elec_one_motor >= 6500 
        warning(sprintf('Can not find a RimFire motor to produce this much power!\nMotor mass is estimated from rough correlation.'))
        mass_motor = (P_elec_one_motor*7e-5 + 0.2135) * 2;   % Rough correlation for motor mass 
                                                     % ^^^  Multiplied by 2 to achieve a more accurate estimation 
    end  
    mass_all_motors = mass_motor * numProp;     % [kg]
    mass_all_ESC = mass_one_ESC * numProp;     % [kg]
    
 % Find solar panel specs   
    energy_batt = cap_batt * V_batt;          % [W*hr]          
    P_panel = energy_batt / (sun_time);                  % [W]
    [ area_panel, mass_panel ] = sizeSolarPanel(P_panel, solar_flux);  % [kg]
    
    mass_panel = 1.5*mass_panel; % [kg] Apply factor of safety 
    area_panel = 1.4*area_panel; % [m^2] Apply factor of safety 


% Find battery specs
    [voluBat, num_series, num_parallel, total_cells, R] = voluBattery(V_batt,V_motor, P_elec_total, t_flight);
    
    V_batt_chk = I_draw*R + V_motor; %should be equal to V_batt, adjust V_batt to equal V_batt_chk
    
    excess_heat = P_elec_total - P_mech_total;

    mass_avail = mass_total - mass_batt - mass_blades - mass_all_motors - mass_all_ESC - mass_panel;        % Available mass left over after considering propulsion/power system 
    

%%%%%%%%%%%%%%%%%%%%%%%% OUTPUT %%%%%%%%%%%%%%%%%%%%%%%
fprintf('Total mass of single drone (Input): %.1f kg\n',mass_total)
fprintf('Mass available for structure, payload, and avionics: %.2f kg\n',mass_avail)
fprintf('Percent Mass available: %.2f%%\n', 100*(mass_avail/mass_total));
fprintf('Mass of all batteries: %.2f kg\n',mass_batt)
fprintf('Mass of all motors: %.2f kg\n',mass_all_motors)
fprintf('Mass of all rotor blades: %.2f kg\n',mass_blades)
fprintf('Mass of all solar panels: %.2f kg\n',mass_panel)
fprintf('Area of all solar panels: %.2f m^2\n',area_panel)
fprintf('Volume of Battery: %.5f m^3\n', voluBat);
fprintf('Number of battery cells in parallel: %.0f cells\n', num_parallel);
fprintf('Number of battery cells in series: %.0f cells\n', num_series);
fprintf('Radius of each rotor: %.3f m\n',blade_radius)
fprintf('Figure of Merit of Rotor: %.3f \n',fig_merit);
fprintf('Mechanical power required from one motor: %.0f W\n',P_mech_one_motor)
fprintf('Electrical power required by one motor: %.0f W\n',P_elec_one_motor)
fprintf('Max rotation rate required from motor: %.0f RPM\n',max([omega omega_climb]*60/(2*pi)))
fprintf('Required heat dissipation for all motors: %.0f W\n',excess_heat)
fprintf('Cruise time of each drone per day: %.2f min\n',t_cruise)
fprintf('Total flight time of each drone per day: %.2f min\n\n',t_flight)
