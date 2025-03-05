function updatedOccupancy = insertVehicle(scenario, position, parkingSpacePositions, occupancy)
    % Function to insert a vehicle into a parking space
    % Define a tolerance for position matching
    tolerance = 0.5; % Adjust as needed for precision
    
    % Initialize a flag to check if a parking space is found
    found = false;
    
    % Loop through all parking spaces to find an available one
    for i = 1:length(parkingSpacePositions)
        if occupancy(i)
            % Skip already occupied spaces
            continue;
        end
        
        % Check if the position is close enough to the parking space
        if norm(parkingSpacePositions(i, :) - position) < tolerance
            % Insert a vehicle at the matched parking space
            vehicleObj = vehicle(scenario, 'ClassID', 1); % Create a vehicle
            vehicleObj.Position = parkingSpacePositions(i, :);
            
            % Update the occupancy array
            occupancy(i) = true;
            found = true;
            break; % Exit the loop once a match is found
        end
    end
    
    % Handle case where no matching parking space is found
    if ~found
        error('No available parking space near the specified position.');
    end
    
    % Return the updated occupancy
    updatedOccupancy = occupancy;
end