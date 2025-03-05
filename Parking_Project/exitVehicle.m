function occupancy = exitVehicle(vehicleObj, parkingSpacePositions, occupancy)
    % Find the index of the parking space the vehicle is occupying
    found = false;
    sections = {'top', 'midupup', 'midupdown', 'middownup', 'middowndown', 'down'};
    
    for i = 1:length(sections)
        section = sections{i};
        
        % Loop through each parking space in the section
        for j = 1:size(parkingSpacePositions.(section), 1)
            % Compare the position of the vehicle to the parking space position
            tolerance = 1e-4;
            if all(abs(parkingSpacePositions.(section)(j, :) - vehicleObj.Position) < tolerance)
                % Mark the parking space as empty
                occupancy.(section)(j) = 0;
                disp(['Vehicle removed from ', section, ' section, spot ', num2str(j)]);
                
                % Move the vehicle outside the parking area 
                vehicleObj.Position = [0 8 0];
                found = true;
                break;
            end
        end
        
        if found
            break;
        end
    end
    
    if ~found
        disp('Vehicle not found at the specified position.');
    end
end
