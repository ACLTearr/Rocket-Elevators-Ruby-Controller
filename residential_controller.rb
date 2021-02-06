module ResidentialController
    #Defining column class
    class Column
        def initialize(id, status, amountOfElevators, amountOfFloors)
            @ID = id
            @status = status
            @amountOfElevators = amountOfElevators
            @amountOfFloors = amountOfFloors
            @elevatorsList = []
            @callButtonsList = []
            
            makeElevator() #Calling the method to create elevators
            makeCallButtons() #Calling the method to create call buttons
        end

        #Getter
        def columnElevatorsList
            @elevatorsList
        end
        #End getter

        #Method to create elevators
        def makeElevator
            for elevatorID in 1..@amountOfElevators
                elevator = Elevator.new(elevatorID, 'idle', @amountOfFloors, 1)
                @elevatorsList.push(elevator)
            end
        end

        #Method to create call buttons
        def makeCallButtons
            callButtonId = 1
            callButtonFloor = 1
            for callButtonCounter in 1..@amountOfFloors
                #If not first floor
                if callButtonCounter > 1
                    callButton = CallButton.new(callButtonId, 'off', callButtonFloor, 'down')
                    @callButtonsList.push(callButton)
                    callButtonId += 1
                end
                #If not last floor
                if callButtonCounter < @amountOfFloors
                    callButton = CallButton.new(callButtonId, 'off', callButtonFloor, 'up')
                    @callButtonsList.push(callButton)
                    callButtonId += 1
                end
                callButtonFloor += 1
            end
        end

        #User calls an elevator
        def requestElevator(floor, direction)
            puts "A request for an elevator is made from floor #{floor}, going #{direction}."
            elevator = findBestElevator(floor, direction)
            puts "Elevator #{elevator.elevatorId} is the best elevator, so it is sent."
            elevator.elevatorFloorRequestList.push(floor)
            elevator.sortFloorList()
            puts "Elevator is moving."
            elevator.moveElevator()
            puts "Elevator is #{elevator.elevatorStatus}."
            elevator.doorController()
            return elevator
        end

        #Find best Elevator
        def findBestElevator(floor, direction)
            requestedFloor = floor
            requestedDirection = direction
            bestElevator = nil
            bestScore = 5
            referenceGap = 1000000
            bestElevatorInfo = [bestElevator, bestScore, referenceGap]

            for elevator in @elevatorsList
                #Elevator is at floor going in correct direction
                if requestedFloor == elevator.elevatorCurrentFloor and elevator.elevatorStatus == 'stopped' and requestedDirection == elevator.elevatorDirection
                    bestElevatorInfo = checkBestElevator(1, elevator, bestElevatorInfo, requestedFloor)
                #Elevator is lower than user and moving through them to destination
                elsif requestedFloor > elevator.elevatorCurrentFloor and elevator.elevatorDirection == 'up' and requestedDirection == elevator.elevatorDirection
                    bestElevatorInfo = checkBestElevator(2, elevator, bestElevatorInfo, requestedFloor)
                #Elevator is higher than user and moving through them to destination
                elsif requestedFloor < elevator.elevatorCurrentFloor and elevator.elevatorDirection == 'down' and requestedDirection == elevator.elevatorDirection
                    bestElevatorInfo = checkBestElevator(2, elevator, bestElevatorInfo, requestedFloor)
                #Elevator is idle
                elsif elevator.elevatorStatus == 'idle'
                    bestElevatorInfo = checkBestElevator(3, elevator, bestElevatorInfo, requestedFloor)
                #Elevator is last resort
                else
                    bestElevatorInfo = checkBestElevator(4, elevator, bestElevatorInfo, requestedFloor)
                end
            end
            return bestElevatorInfo[0]

        end

        #Comparing elevator to previous best
        def checkBestElevator(scoreToCheck, newElevator, bestElevatorInfo, floor)
            #If elevators situation is more favourable
            if scoreToCheck < bestElevatorInfo[1]
                bestElevatorInfo[1] = scoreToCheck
                bestElevatorInfo[0] = newElevator
                bestElevatorInfo[2] = (newElevator.elevatorCurrentFloor - floor).abs
            #If elevators are in a similar situation, set the closest one to the best elevator
            elsif bestElevatorInfo[1] == scoreToCheck
                gap = (newElevator.elevatorCurrentFloor - floor).abs
                if bestElevatorInfo[2] > gap
                    bestElevatorInfo[1] = scoreToCheck
                    bestElevatorInfo[0] = newElevator
                    bestElevatorInfo[2] = gap
                end
            end
            return bestElevatorInfo 
        end

    end

    #Defining elevator class
    class Elevator
        def initialize(id, status, amountOfFloors, currentFloor)
            @ID = id
            @status = status
            @amountOfFloors = amountOfFloors
            @currentFloor = currentFloor
            @direction = nil
            @door = Door.new(id, 'closed')
            @overweight = false
            @obstruction = false
            @floorRequestButtonsList = []
            @floorRequestList = []
            makeFloorRequestButton() #Calling the method to create the floor request buttons
        end
        
        #Getters
        def elevatorId
            @ID
        end
        def elevatorStatus
            @status
        end
        def elevatorStatus=(newStatus)
            @status = newStatus
        end
        def elevatorAmountOfFloors
            @amountOfFloors
        end
        def elevatorCurrentFloor
            @currentFloor
        end
        def elevatorCurrentFloor=(newFloor)
            @currentFloor = newFloor
        end
        def elevatorDirection
            @direction
        end
        def elevatorDirection=(newDirection)
            @direction = newDirection
        end
        def elevatorDoor
            @door
        end
        def elevatorFloorRequestList
            @floorRequestList
        end
        #End getters

        #Method to create floor request buttons
        def makeFloorRequestButton
            floorRequestButtonFloor = 1
            for i in 1..@amountOfFloors
                floorRequestButton = FloorRequestButton.new(i, 'off', floorRequestButtonFloor)
                @floorRequestButtonsList.push(floorRequestButton)
                floorRequestButtonFloor += 1
            end
        end

        #User requesting floor inside elevator
        def requestFloor(floor)
            puts "The elevator is requested to move to floor #{floor}."
            @floorRequestList.push(floor)
            sortFloorList()
            puts "Elevator is moving."
            moveElevator()
            puts "Elevator is #{@status}."
            doorController()
            if @floorRequestList.length() == 0
                @direction = nil
                @status = 'idle'
            end
            puts "Elevator is #{@status}."
        end

        #Moving elevator
        def moveElevator
            while @floorRequestList.length() != 0
                destination = @floorRequestList[0]
                @status = 'moving'
                if @currentFloor < destination
                    @direction = 'up'
                    while @currentFloor < destination
                        @currentFloor += 1
                        puts "Elevator is at floor: #{@currentFloor}"
                    end
                elsif @currentFloor > destination
                    @direction = 'down'
                    while @currentFloor > destination
                        @currentFloor -= 1
                        puts "Elevator is at floor: #{@currentFloor}"
                    end
                end
                @status = 'stopped'
                @floorRequestList.shift()
            end
        end

        #Sorting floor request list
        def sortFloorList
            if @direction == 'up'
                @floorRequestList.sort!
            elsif @direction == 'down'
                @floorRequestList.sort!.reverse
            end
        end

        #Door operation controller
        def doorController
            @door = 'opened'
            puts "Elevator doors are #{@door}."
            puts "Waiting for occupant(s) to transition."
            #Wait 5 seconds
            if @overweight == false
                @door = 'closing'
                if @obstruction == false
                    @door = 'closed'
                    puts "Elevator doors are #{@door}."
                else
                    #Wait for obstruction to clear
                    @obstruction = false
                    doorController()
                end
            else
                while @overweight == true
                    #Ring alarm and wait until not overweight
                    @overweight = false
                end
                doorController()
            end
        end

    end

    #Defining call button class
    class CallButton
        def initialize(id, status, floor, direction)
            @ID = id
            @status = status
            @floor = floor
            @direction = direction
        end

        #Getters
        def callButtonId
            @ID
        end
        def callButtonStatus
            @status
        end
        def callButtonFloor
            @floor
        end
        def callButtonDirection
            @direction
        end
        #End getters

    end

    #Defining floor request button class
    class FloorRequestButton
        def initialize(id, status, floor)
            @ID = id
            @status = status
            @floor = floor
        end

        #Getters
        def floorRequestButtonId
            @ID
        end
        def floorRequestButtonStatus
            @status
        end
        def floorRequestButtonFloor
            @floor
        end
        #End getters
    end

    #Defining door class
    class Door
        def initialize(id, status)
            @ID = id
            @status = status
        end

        #Getters
        def doorId
            @ID
        end
        def doorStatus
            @status
        end
        #End getters

    end

    #Defining scenario 1
    def self.scenario1
        #In scenario 1, an individual is on floor 3, going up to floor 7.
        #Elevator 1 is at floor 2, and Elevator 2 is at floor 6.
        #Elevator 1 will be sent.
        column = Column.new(1, 'online', 2, 10)

        column.columnElevatorsList[0].elevatorCurrentFloor=(2)
        column.columnElevatorsList[1].elevatorCurrentFloor=(6)

        elevator = column.requestElevator(3, 'up')
        elevator.requestFloor(7)
    end

    #Defining scenario 2
    def self.scenario2
        #In scenario 2, an individual is on floor 1, going up to floor 6.
        #Elevator 1 is at floor 10, and Elevator 2 is at floor 3.
        #Elevator 2 will be sent.
        #An individial is on floor 3, going up to floor 5.
        #Elevator 1 is at floor 10, and Elevator 2 is at floor 6.
        #Elevator 2 will be sent.
        #An individial is on floor 9, going down to floor 2.
        #Elevator 1 is at floor 10, and Elevator 2 is at floor 5.
        #Elevator 1 will be sent.
        column = Column.new(1, 'online', 2, 10)

        column.columnElevatorsList[0].elevatorCurrentFloor=(10)
        column.columnElevatorsList[1].elevatorCurrentFloor=(3)

        elevator = column.requestElevator(1, 'up')
        elevator.requestFloor(6)

        puts ""
        puts ""
        
        elevator = column.requestElevator(3, 'up')
        elevator.requestFloor(5)

        puts ""
        puts ""
        
        elevator = column.requestElevator(9, 'down')
        elevator.requestFloor(2)
    end

    #Defining scenario 3
    def self.scenario3
        #In scenario 2, an individual is on floor 3, going down to floor 2.
        #Elevator 1 is at floor 10, and Elevator 2 is moving from floor 3 to 6.
        #Elevator 1 will be sent.
        #An individial is on floor 10, going down to floor 3.
        #Elevator 1 is at floor 10, and Elevator 2 is at floor 6.
        #Elevator 2 will be sent.
        column = Column.new(1, 'online', 2, 10)

        column.columnElevatorsList[0].elevatorCurrentFloor=(10)
        column.columnElevatorsList[1].elevatorCurrentFloor=(3)
        column.columnElevatorsList[1].elevatorStatus=('moving')
        column.columnElevatorsList[1].elevatorDirection=('up')

        elevator = column.requestElevator(3, 'down')
        elevator.requestFloor(2)

        puts ""
        puts ""

        column.columnElevatorsList[1].elevatorCurrentFloor=(6)
        column.columnElevatorsList[1].elevatorStatus=('idle')
        column.columnElevatorsList[1].elevatorDirection=(nil)

        elevator = column.requestElevator(10, 'down')
        elevator.requestFloor(3)
    end
end

#Uncomment to run scenario 1
#ResidentialController::scenario1()

#Uncomment to run scenario 2
#ResidentialController::scenario2()

#Uncomment to run scenario 3
#ResidentialController::scenario3()