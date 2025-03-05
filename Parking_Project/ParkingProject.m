scenario = drivingScenario;
scenario.SampleTime = 0.2;

% Define the roads and parking lot as before
roadCenters = [69.2 11.7 0; -1.1 11.5 0];
marking = [laneMarking("Solid")
           laneMarking("DoubleSolid", Color=[1 0.9 0])
           laneMarking("Solid")];
laneSpecification = lanespec(2, Width=5.925, Marking=marking);
road(scenario, roadCenters, Lanes=laneSpecification, Name="Road");

roadCenters = [12.4 7.7 0; 12.4 -15.8 0];
road(scenario, roadCenters, Name="Road1");

roadCenters = [50 7.7 0; 50 -15.8 0];
road(scenario, roadCenters, Name="Road2");

lot = parkingLot(scenario, [3 -5; 60 -5; 60 -45; 3 -45]);

% Create the parking spaces
cars = parkingSpace;
accessible = parkingSpace(Type="Accessible");
accessibleLane = parkingSpace(Type="NoParking", MarkingColor=[1 1 1], Width=1.5);
fireLane = parkingSpace(Type="NoParking", Length=2, Width=40);

% Insert the parking spaces and keep track of the indices
insertParkingSpaces(lot, cars, 13, Edge=2, Offset=3); % Top edge
insertParkingSpaces(lot, cars, 13, Edge=4, Offset=3); % Bottom edge
insertParkingSpaces(lot, cars ,9,Rows=2,Position=[42 -12]);
insertParkingSpaces(lot, cars ,9,Rows=2,Position=[23 -12]);
insertParkingSpaces(lot, fireLane, 1, Edge=3, Offset=8); % Right edge

% Define positions of parking spaces for each section
parkingSpacePositions = struct( ...
    'top', [55.5, -9.6, 0; 55.5, -12.3, 0; 55.5, -15, 0; 55.5, -17.7, 0; 55.5, -20.4, 0; 55.5, -23.2, 0; 55.5, -25.9, 0; 55.5, -28.7, 0; 55.5, -31.5, 0; 55.5, -34.4, 0; 55.5, -37, 0; 55.5, -39.9, 0; 55.5, -42.5, 0], ...
    'midupup', [43.5, -13.4, 0; 43.5, -16.2, 0; 43.5, -19, 0; 43.5, -21.8, 0; 43.5, -24.4, 0; 43.5, -27.2, 0; 43.5, -30, 0; 43.5, -32.7, 0; 43.5, -35.5, 0], ...
    'midupdown', [38, -13.4, 0; 38, -16.2, 0; 38, -19, 0; 38, -21.8, 0; 38, -24.4, 0; 38, -27.2, 0; 38, -30, 0; 38, -32.7, 0; 38, -35.5, 0], ...
    'middownup', [24.5, -13.4, 0; 24.5, -16.2, 0; 24.5, -19, 0; 24.5, -21.8, 0; 24.5, -24.4, 0; 24.5, -27.2, 0; 24.5, -30, 0; 24.5, -32.7, 0; 24.5, -35.5, 0], ...
    'middowndown', [19, -13.4, 0; 19, -16.2, 0; 19, -19, 0; 19, -21.8, 0; 19, -24.4, 0; 19, -27.2, 0; 19, -30, 0; 19, -32.7, 0; 19, -35.5, 0], ...
    'down', [4.7, -7.5, 0; 4.7, -10.5, 0;4.7, -13.2, 0; 4.7, -15.9, 0; 4.7, -18.6, 0; 4.7, -21.4, 0; 4.7, -24.1, 0; 4.7, -26.9, 0; 4.7, -29.7, 0; 4.7, -32.4, 0; 4.7, -35.1, 0; 4.7, -37.9, 0; 4.7, -40.6, 0 ] ...
);
occupancy = struct( ...
    'top', zeros(size(parkingSpacePositions.top, 1), 1), ...
    'midupup', zeros(size(parkingSpacePositions.midupup, 1), 1), ...
    'midupdown', zeros(size(parkingSpacePositions.midupdown, 1), 1), ...
    'middownup', zeros(size(parkingSpacePositions.middownup, 1), 1), ...
    'middowndown', zeros(size(parkingSpacePositions.middowndown, 1), 1), ...
    'down', zeros(size(parkingSpacePositions.down, 1), 1) ...
);

function occupancy = insertVehicle(scenario, position, parkingSpacePositions, occupancy)
    ego = vehicle(scenario, 'ClassID', 1, 'Position', position);
    
    % Loop through each section of parking spaces
    fields = fieldnames(parkingSpacePositions);
    for i = 1:length(fields)
        section = fields{i};  % Get the section name (e.g., 'top', 'midupdown', etc.)
        
        % Loop through each parking space in the section
        for j = 1:size(parkingSpacePositions.(section), 1)
            % Use a tolerance to compare the position with the parking space
            tolerance = 1e-4;  % Adjust as needed
            if all(abs(parkingSpacePositions.(section)(j, :) - position) < tolerance)
                % Check if the parking space is vacant
                if occupancy.(section)(j) == 0
                    % Mark as occupied
                    occupancy.(section)(j) = 1;
                    return;  % Exit function after inserting the vehicle
                end
            end
        end
    end
end

function occupancy = removeFromOccupancy(occupancy, section, idx)
    % This function updates the occupancy status when a vehicle is removed
    
    % Update the corresponding section of occupancy based on the index
    switch section
        case 'down'
            if occupancy.down(idx) == 1
                occupancy.down(idx) = 0; % Mark as empty
                disp(['Spot ', num2str(idx), ' in down section is now empty.']);
            else
                disp(['Spot ', num2str(idx), ' in down section was already empty.']);
            end
        % Add cases for other sections if needed...
        otherwise
            error('Invalid section in occupancy update.');
    end
end
function vehicleObj = getVehicleByPosition(scenario, position)
    % This function looks for a vehicle by position in the scenario
    tolerance = 1e-4;
    vehicles = scenario.Actors;  % Get all actors in the scenario
    
    vehicleObj = [];  % Initialize as empty
    
    % Loop through all vehicles in the scenario
    for i = 1:length(vehicles)
        if all(abs(vehicles(i).Position - position) < tolerance)
            vehicleObj = vehicles(i);  % Found the vehicle
            break;
        end
    end
end


while true
    % Prompt the user for input
    disp('Enter the command as "insert: [x, y, z]" or "remove: [x, y, z]", or type "exit" to stop:');
    userInput = input('Command: ', 's');
    
    % Check if the user wants to exit
    if strcmpi(userInput, 'exit')
        disp('Exiting the interactive vehicle management process.');
        break;
    end
    
try
    if startsWith(userInput, 'insert:', 'IgnoreCase', true)
        % Extract position for insertion
        positionStr = strtrim(extractAfter(userInput, 'insert:'));
        position = str2num(positionStr); %#ok<ST2NM>
        
        if numel(position) ~= 3
            error('Position must be a 3-element vector [x, y, z].');
        end
        
        % Insert the vehicle
        occupancy = insertVehicle(scenario, position, parkingSpacePositions, occupancy);
        disp('Vehicle inserted successfully.');
    
    elseif startsWith(userInput, 'remove:', 'IgnoreCase', true)
    % Extract position for removal
    positionStr = strtrim(extractAfter(userInput, 'remove:'));
    position = str2num(positionStr);  % Convert the position to numeric array
    
    % Check if the position is a 3-element vector
    if numel(position) ~= 3
        error('Position must be a 3-element vector [x, y, z].');
    end
    vehicleObj = getVehicleByPosition(scenario, position);  % Custom function to get vehicle based on position
    
    % Check if a vehicle was found
    if ~isempty(vehicleObj)
        % Call the exitVehicle function to remove the vehicle
        occupancy = exitVehicle(vehicleObj, parkingSpacePositions, occupancy);  % Exit the vehicle from parking space
        disp('Vehicle removed successfully.');
    else
        disp('No vehicle found at the specified position.');
    end
else
    error('Invalid command. Use "insert:", "remove:", or "exit".');
end

        % Display status 
        freeTop = sum(occupancy.top == 0);
        freeMidupup = sum(occupancy.midupup == 0);
        freeMidupdown = sum(occupancy.midupdown == 0);
        freeMiddownup = sum(occupancy.middownup == 0);
        freeMiddowndown = sum(occupancy.middowndown == 0);
        freeDown = sum(occupancy.down == 0);
        
        freeTopSection = freeTop + freeMidupup;
        freeMiddleSection = freeMidupdown + freeMiddownup;
        freeBottomSection = freeMiddowndown + freeDown;
        
        topLEDStatus = 'OFF';
        middleLEDStatus = 'OFF';
        bottomLEDStatus = 'OFF';
        
        if freeTopSection == 0
            topLEDStatus = 'RED LIGHT';
        else
            topLEDStatus = 'GREEN LIGHT';
        end
        
        if freeMiddleSection == 0
            middleLEDStatus = 'RED LIGHT';
        else
            middleLEDStatus = 'GREEN LIGHT';
        end
        
        if freeBottomSection == 0
            bottomLEDStatus = 'RED LIGHT';
        else
            bottomLEDStatus = 'GREEN LIGHT';
        end
        
        disp(['Total free (Top Section): ', num2str(freeTopSection)]);
        disp(['Total free (Middle Section): ', num2str(freeMiddleSection)]);
        disp(['Total free (Bottom Section): ', num2str(freeBottomSection)]);
        disp(['Top LED : ', topLEDStatus]);
        disp(['Middle LED : ', middleLEDStatus]);
        disp(['Bottom LED : ', bottomLEDStatus]);
        plot(scenario);
        
    catch ME
        disp(['Error: ', ME.message]);
    end
end

plot(scenario);
