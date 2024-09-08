// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract WagerlyPlatform {
    // The owner of the contract
    address public owner;
    
    // Fee address where 1% of the total bet will be sent
    address private constant FEE_ADDRESS = 0x9b63FA365019Dd7bdF8cBED2823480F808391970;
    
    // Keeps track of the next bet ID
    uint256 private nextBetId = 1;  

    // Struct to store information about individual bets
    struct Bet {
        address bettor;  // Address of the person who placed the bet
        uint256 amount;  // Amount they bet
    }

    // Struct to store information about a betting instance
    struct BetInstance {
        uint256 id;  // Bet ID
        string title;  // Title of the bet (e.g., "Team A vs Team B")
        string[] options;  // List of available options to bet on
        uint256[] totalAmounts;  // Total amounts bet on each option
        uint256 minimumBetAmount;  // Minimum amount to place a bet
        address tokenAddress;  // Address of the ERC20 token used for betting
        mapping(address => Bet[]) bets;  // Mapping from bettor's address to their bets
        address[] bettors;  // List of addresses of bettors
        address creator;  // Address of the person who created the bet instance
        bool isOpen;  // Whether betting is still open
        bool isResolved;  // Whether the bet has been resolved
        uint8 winningOption;  // The winning option (1-based index)
        bool isCanceled;  // Whether the bet has been canceled
    }

    // Mapping to store all bet instances by ID
    mapping(uint256 => BetInstance) private betInstances;

    // Events
    event BetInstanceCreated(address creator, uint256 indexed betId, string title, string[] options, uint256 minimumBetAmount, address tokenAddress);
    event BetPlaced(uint256 indexed betId, address indexed bettor, uint256 amount, uint8 option);
    event BettingClosed(uint256 indexed betId);
    event BettingResolved(uint256 indexed betId, uint8 winningOption);
    event BetCancelled(uint256 indexed betId);

    // Modifier to restrict actions to the creator of the bet instance
    modifier onlyCreator(uint256 _betId) {
        if (msg.sender != betInstances[_betId].creator) {
            revert("Not authorized");
        }
        _;
    }

    // Modifier to restrict actions to the owner of the contract
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized, only owner can create bets");
        _;
    }

    // Constructor: Initializes the owner as the person who deployed the contract
    constructor() {
        owner = msg.sender;
    }

    // Function to create a new bet instance (only the owner can call this)
    function createBetInstance(
        string calldata _title,  
        uint8 _numOptions, 
        string[] calldata _optionNames,
        uint256 _minimumBetAmount,
        address _tokenAddress
    ) external onlyOwner {  // Only the owner can create bet instances
        require(_numOptions >= 2 && _numOptions <= 5, "Invalid number of options");
        require(_optionNames.length == _numOptions, "Option names length mismatch");

        uint256 betId = nextBetId; 
        nextBetId++;  // Increment the bet ID for the next bet

        // Ensure no bet exists with the same ID (just a sanity check)
        if (betInstances[betId].creator != address(0)) {
            revert("Bet instance with this ID already exists");
        }

        // Create the new bet instance
        BetInstance storage newInstance = betInstances[betId];
        newInstance.id = betId;
        newInstance.title = _title;        
        newInstance.minimumBetAmount = _minimumBetAmount;
        newInstance.creator = msg.sender;  // Owner will be the creator of this bet
        newInstance.tokenAddress = _tokenAddress;
        newInstance.totalAmounts = new uint256[](_numOptions);

        // Set up the available options for this bet
        for (uint8 i = 0; i < _numOptions; i++) {
            newInstance.options.push(_optionNames[i]);
        }

        // Emit event that a bet instance was created
        emit BetInstanceCreated(msg.sender, betId, _title, _optionNames, _minimumBetAmount, _tokenAddress);
    }

    // Function to place a bet on a given bet instance
    function placeBet(uint256 _betId, uint256 _amount, uint8 _option) external {
        BetInstance storage betInstance = betInstances[_betId];
        require(betInstance.isOpen, "Betting is closed");
        require(_amount >= betInstance.minimumBetAmount, "Bet amount is less than minimum");
        require(_option >= 1 && _option <= betInstance.options.length, "Invalid option");

        // Transfer the bet amount from the bettor's account to the contract
        IERC20 token = IERC20(betInstance.tokenAddress);
        require(token.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        // Update the total amount for the selected option
        betInstance.totalAmounts[_option - 1] += _amount;
        betInstance.bets[msg.sender].push(Bet(msg.sender, _amount));
        betInstance.bettors.push(msg.sender);

        // Emit event that a bet was placed
        emit BetPlaced(_betId, msg.sender, _amount, _option);
    }

    // Function to close betting on a given bet instance (only creator can call this)
    function closeBetting(uint256 _betId) external onlyCreator(_betId) {
        BetInstance storage betInstance = betInstances[_betId];
        betInstance.isOpen = false;  // Mark the bet as closed
        emit BettingClosed(_betId);
    }

    // Function to distribute winnings after the bet is resolved
    function distributeWinnings(uint256 _betId, uint8 _winningOption) external onlyCreator(_betId) {
        require(_winningOption >= 1 && _winningOption <= betInstances[_betId].options.length, "Invalid winning option");

        BetInstance storage betInstance = betInstances[_betId];
        require(!betInstance.isOpen && !betInstance.isResolved, "Betting must be closed and not resolved");

        // Get the token contract for transferring funds
        IERC20 token = IERC20(betInstance.tokenAddress);

        // Calculate the total amount to distribute
        uint256 totalAmountToDistribute = 0;
        for (uint8 i = 0; i < betInstance.totalAmounts.length; i++) {
            totalAmountToDistribute += betInstance.totalAmounts[i];
        }
        uint256 totalAmountWinningOption = betInstance.totalAmounts[_winningOption - 1];

        // Deduct a 1% fee and transfer to the fee address and creator
        uint256 fee = totalAmountToDistribute / 100;
        uint256 creatorFee = fee;
        uint256 remainingAmount = totalAmountToDistribute - fee - creatorFee;
        
        require(token.transfer(FEE_ADDRESS, fee), "Fee transfer failed");
        require(token.transfer(betInstance.creator, creatorFee), "Creator fee transfer failed");

        // Distribute the remaining amount to the winners
        for (uint256 i = 0; i < betInstance.bettors.length; i++) {
            address bettor = betInstance.bettors[i];
            Bet[] storage bets = betInstance.bets[bettor];
            for (uint8 j = 0; j < bets.length; j++) {
                if (bets[j].bettor != address(0)) {
                    uint256 amountToTransfer = (bets[j].amount * remainingAmount) / totalAmountWinningOption;
                    require(token.transfer(bettor, amountToTransfer), "Winner transfer failed");
                }
            }
        }

        // Mark the bet as resolved
        betInstance.isResolved = true;
        betInstance.winningOption = _winningOption;
        emit BettingResolved(_betId, _winningOption);
    }

    // Function to cancel the bet (only creator can call this, before it's resolved)
    function cancelBet(uint256 _betId) external onlyCreator(_betId) {
        BetInstance storage betInstance = betInstances[_betId];
        require(!betInstance.isResolved, "Betting already resolved");
        betInstance.isCanceled = true;

        // Get the token contract for refunding the bettors
        IERC20 token = IERC20(betInstance.tokenAddress);

        // Refund the bettors their money minus the fee
        uint256 totalAmountToDistribute = 0;
        for (uint8 i = 0; i < betInstance.totalAmounts.length; i++) {
            totalAmountToDistribute += betInstance.totalAmounts[i];
        }

        uint256 fee = totalAmountToDistribute / 100;
        uint256 creatorFee = fee;
        uint256 remainingAmount = totalAmountToDistribute - fee - creatorFee;
        
        require(token.transfer(FEE_ADDRESS, fee), "Fee transfer failed");
        require(token.transfer(betInstance.creator, creatorFee), "Creator fee transfer failed");

        // Refund all bettors
        for (uint256 i = 0; i < betInstance.bettors.length; i++) {
            address bettor = betInstance.bettors[i];
            Bet[] storage bets = betInstance.bets[bettor];
            for (uint8 j = 0; j < bets.length; j++) {
                uint256 betAmount = bets[j].amount;
                uint256 amountToTransfer = (betAmount * remainingAmount) / totalAmountToDistribute;
                require(token.transfer(bettor, amountToTransfer), "Bettor transfer failed");
            }
        }

        emit BetCancelled(_betId);
    }

    // Function to get information about a specific bet instance
    function getBetInfo(uint256 _betId) external view returns (
        address creator,
        string memory title,         
        string[] memory options,
        bool isOpen,
        bool isResolved,
        uint256 totalAmountBet,
        uint256[] memory totalAmounts,
        address tokenAddress,
        uint8 winningOption,
        bool isCanceled
    ) {
        BetInstance storage betInstance = betInstances[_betId];

        creator = betInstance.creator;
        title = betInstance.title;          
        options = betInstance.options;
        isOpen = betInstance.isOpen;
        isResolved = betInstance.isResolved;

        totalAmounts = new uint256[](betInstance.totalAmounts.length);
        totalAmountBet = 0;
        for (uint8 i = 0; i < betInstance.totalAmounts.length; i++) {
            totalAmounts[i] = betInstance.totalAmounts[i];
            totalAmountBet += betInstance.totalAmounts[i];
        }

        tokenAddress = betInstance.tokenAddress;
        winningOption = betInstance.isResolved ? betInstance.winningOption : 0;

        return (
            creator,
            title,
            options,
            isOpen,
            isResolved,
            totalAmountBet,
            totalAmounts,
            tokenAddress,
            winningOption,
            isCanceled
        );
    }

    // Function to get all open bets placed by a specific bettor
    function getOpenBetsByAddress(address _bettor) external view returns (
        uint256[] memory openBetIds, 
        string[] memory titles, 
        uint256[] memory amounts, 
        string[][] memory options
    ) {
        uint256 openBetCount = 0;

        // Count all open bets for the bettor
        for (uint256 i = 1; i < nextBetId; i++) {
            BetInstance storage betInstance = betInstances[i];
            if (betInstance.isOpen && betInstance.bets[_bettor].length > 0) {
                openBetCount++;
            }
        }

        // Initialize arrays to store the results
        openBetIds = new uint256[](openBetCount);
        titles = new string[](openBetCount);
        amounts = new uint256[](openBetCount);
        options = new string[][](openBetCount);

        uint256 index = 0;

        // Populate the arrays with the open bet information
        for (uint256 i = 1; i < nextBetId; i++) {
            BetInstance storage betInstance = betInstances[i];

            if (betInstance.isOpen && betInstance.bets[_bettor].length > 0) {
                openBetIds[index] = betInstance.id;
                titles[index] = betInstance.title;

                uint256 totalAmountBetByUser = 0;
                Bet[] storage bets = betInstance.bets[_bettor];
                for (uint256 j = 0; j < bets.length; j++) {
                    totalAmountBetByUser += bets[j].amount;
                }
                amounts[index] = totalAmountBetByUser;
                options[index] = betInstance.options;

                index++;
            }
        }
    }

    // Function to get all open bets across all bettors
    function getAllOpenBets() external view returns (
        uint256[] memory openBetIds, 
        string[] memory titles, 
        string[][] memory options, 
        uint256[] memory minimumBetAmounts, 
        address[] memory creators
    ) {
        uint256 openBetCount = 0;

        // Count all open bets
        for (uint256 i = 1; i < nextBetId; i++) {
            BetInstance storage betInstance = betInstances[i];
            if (betInstance.isOpen) {
                openBetCount++;
            }
        }

        // Initialize arrays to store the results
        openBetIds = new uint256[](openBetCount);
        titles = new string[](openBetCount);
        options = new string[][](openBetCount);
        minimumBetAmounts = new uint256[](openBetCount);
        creators = new address[](openBetCount);

        uint256 index = 0;

        // Populate the arrays with the open bet information
        for (uint256 i = 1; i < nextBetId; i++) {
            BetInstance storage betInstance = betInstances[i];

            if (betInstance.isOpen) {
                openBetIds[index] = betInstance.id;
                titles[index] = betInstance.title;
                options[index] = betInstance.options;
                minimumBetAmounts[index] = betInstance.minimumBetAmount;
                creators[index] = betInstance.creator;

                index++;
            }
        }
    }
}
