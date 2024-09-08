// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract WagerlyUsers is KeeperCompatibleInterface {
    address public owner;  // Contract owner address
    address private constant FEE_ADDRESS = 0x9b63FA365019Dd7bdF8cBED2823480F808391970;
    uint256 private nextBetId = 1;  // Keeps track of the next bet ID

    struct Bet {
        address bettor;
        uint256 amount;
    }

    struct BetInstance {
        uint256 id;
        string title;
        string[] options;
        uint256[] totalAmounts;
        uint256 minimumBetAmount;
        address tokenAddress;
        mapping(address => Bet[]) bets;  // Tracks the bets of each address
        address[] bettors;
        address creator;
        bool isClosed;
        bool isResolved;
        bool isProcessingPayment;  // Indicates if the bet is currently processing payments
        bool isPaid;  // Indicates if the bet has already been paid
        uint8 winningOption;
        uint256 distributionTime;  // Time when the winnings will be distributed (after 24 hours)
        bool isDistributionScheduled;  // Indicates if the distribution has been scheduled
    }

    mapping(uint256 => BetInstance) private betInstances;  // Stores all the bet instances

    event BetInstanceCreated(address creator, uint256 indexed betId, string title, string[] options, uint256 minimumBetAmount, address tokenAddress);
    event BetPlaced(uint256 indexed betId, address indexed bettor, uint256 amount, uint8 option);
    event BettingClosed(uint256 indexed betId);
    event BettingResolved(uint256 indexed betId, uint8 winningOption);
    event BetCancelled(uint256 indexed betId);
    event DistributionScheduled(uint256 indexed betId, uint256 distributionTime);  // Event for when a distribution is scheduled
    
    modifier onlyCreator(uint256 _betId) {
        require(msg.sender == betInstances[_betId].creator, "Not authorized");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized, only owner can call this");
        _;
    }

    constructor() {
        owner = msg.sender;  // Initialize the contract owner
    }

    // Function to create a new betting instance
    function createBetInstance(
        string calldata _title,      
        uint8 _numOptions,
        string[] calldata _optionNames,
        uint256 _minimumBetAmount,
        address _tokenAddress
    ) external {
        require(_numOptions >= 2 && _numOptions <= 5, "Invalid number of options");
        require(_optionNames.length == _numOptions, "Option names length mismatch");

        uint256 betId = nextBetId; 
        nextBetId++;  // Increment the bet ID for the next bet

        BetInstance storage newInstance = betInstances[betId];
        newInstance.id = betId;
        newInstance.title = _title;
        newInstance.minimumBetAmount = _minimumBetAmount;
        newInstance.creator = msg.sender;
        newInstance.tokenAddress = _tokenAddress;
        newInstance.totalAmounts = new uint256[](_numOptions);

        // Add the option names to the bet instance
        for (uint8 i = 0; i < _numOptions; i++) {
            newInstance.options.push(_optionNames[i]);
        }

        emit BetInstanceCreated(msg.sender, betId, _title, _optionNames, _minimumBetAmount, _tokenAddress);
    }

    // Function to place a bet on an open bet instance
    function placeBet(uint256 _betId, uint256 _amount, uint8 _option) external {
        BetInstance storage betInstance = betInstances[_betId];
        require(!betInstance.isClosed, "Betting is closed");
        require(_amount >= betInstance.minimumBetAmount, "Bet amount is less than minimum");
        require(_option >= 1 && _option <= betInstance.options.length, "Invalid option");

        IERC20 token = IERC20(betInstance.tokenAddress);
        require(token.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        // Add the bet amount to the chosen option
        betInstance.totalAmounts[_option - 1] += _amount;
        betInstance.bets[msg.sender].push(Bet(msg.sender, _amount));
        betInstance.bettors.push(msg.sender);

        emit BetPlaced(_betId, msg.sender, _amount, _option);
    }

    // Function to close betting on a specific bet instance
    function closeBetting(uint256 _betId) external onlyCreator(_betId) {
        BetInstance storage betInstance = betInstances[_betId];
        betInstance.isClosed = true;  // Mark the betting instance as closed
        emit BettingClosed(_betId);
    }

    // Function to resolve a bet and define the winning option
    function distributeWinnings(uint256 _betId, uint8 _winningOption) external onlyCreator(_betId) {
        BetInstance storage betInstance = betInstances[_betId];
        require(_winningOption >= 1 && _winningOption <= betInstance.options.length, "Invalid winning option");
        require(betInstance.isClosed && !betInstance.isResolved, "Betting must be closed and not resolved");

        // Mark the bet as resolved and set the winning option
        betInstance.isResolved = true;
        betInstance.winningOption = _winningOption;

        // Schedule the distribution in 24 hours
        betInstance.distributionTime = block.timestamp + 24 hours;
        betInstance.isDistributionScheduled = true;
        betInstance.isProcessingPayment = true;  // Mark that the payment is being processed

        emit BettingResolved(_betId, _winningOption);
        emit DistributionScheduled(_betId, betInstance.distributionTime);
    }

    // Internal function to distribute winnings (used by Chainlink Keepers after 24 hours)
    function distribute(uint256 _betId) internal {
        BetInstance storage betInstance = betInstances[_betId];
        require(betInstance.isResolved, "Bet not resolved");
        require(block.timestamp >= betInstance.distributionTime, "Distribution time has not been reached");

        IERC20 token = IERC20(betInstance.tokenAddress);

        // Calculate the total amount to distribute
        uint256 totalAmountToDistribute = 0;
        for (uint8 i = 0; i < betInstance.totalAmounts.length; i++) {
            totalAmountToDistribute += betInstance.totalAmounts[i];
        }
        uint256 totalAmountWinningOption = betInstance.totalAmounts[betInstance.winningOption - 1];

        // Deduct fees and distribute the remaining amount
        uint256 fee = totalAmountToDistribute / 100;  // 1% fee
        uint256 creatorFee = fee;
        uint256 remainingAmount = totalAmountToDistribute - fee - creatorFee;

        require(token.transfer(FEE_ADDRESS, fee), "Fee transfer failed");
        require(token.transfer(betInstance.creator, creatorFee), "Creator fee transfer failed");

        // Distribute winnings to all bettors who chose the winning option
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

        betInstance.isProcessingPayment = false;  // Mark that the payment is no longer being processed
        betInstance.isPaid = true;  // Mark that the bet has been fully paid
        betInstance.isDistributionScheduled = false;  // Mark that the distribution is completed
    }

    // Chainlink Keepers function: checkUpkeep is called to see if upkeep is needed
    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory performData) {
        // Loop through all bet instances to check if any is due for distribution
        for (uint256 i = 1; i < nextBetId; i++) {
            if (betInstances[i].isDistributionScheduled && block.timestamp >= betInstances[i].distributionTime) {
                upkeepNeeded = true;  // Set to true if there are bets ready for distribution
                performData = abi.encode(i);  // Encode the bet ID to pass to performUpkeep
                break;
            }
        }
    }

    // Chainlink Keepers function: performUpkeep is called to execute the distribution after 24 hours
    function performUpkeep(bytes calldata performData) external override {
        uint256 betId = abi.decode(performData, (uint256));
        if (betInstances[betId].isDistributionScheduled && block.timestamp >= betInstances[betId].distributionTime) {
            distribute(betId);  // Call distribute to finalize the payment
        }
    }

    // Function to cancel the bet (creator cannot cancel after bet is resolved)
    function cancelBet(uint256 _betId) external onlyCreator(_betId) {
        BetInstance storage betInstance = betInstances[_betId];
        require(!betInstance.isResolved, "Cannot cancel, bet is already resolved");

        IERC20 token = IERC20(betInstance.tokenAddress);

        // Calculate the total amount to distribute
        uint256 totalAmountToDistribute = 0;
        for (uint8 i = 0; i < betInstance.totalAmounts.length; i++) {
            totalAmountToDistribute += betInstance.totalAmounts[i];
        }

        uint256 fee = totalAmountToDistribute / 100;
        uint256 creatorFee = fee;
        uint256 remainingAmount = totalAmountToDistribute - fee - creatorFee;

        // Refund fees
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

    // Owner can cancel a bet during the 24-hour waiting period if there's a fraud
    function ownerCancelBet(uint256 _betId) external onlyOwner {
        BetInstance storage betInstance = betInstances[_betId];
        require(betInstance.isProcessingPayment && !betInstance.isPaid, "Cannot cancel, bet is not in processing state or already paid");
        require(block.timestamp < betInstance.distributionTime, "Cannot cancel, distribution time has passed");

        IERC20 token = IERC20(betInstance.tokenAddress);

        // Refund all bettors
        for (uint256 i = 0; i < betInstance.bettors.length; i++) {
            address bettor = betInstance.bettors[i];
            Bet[] storage bets = betInstance.bets[bettor];
            for (uint8 j = 0; j < bets.length; j++) {
                uint256 betAmount = bets[j].amount;
                require(token.transfer(bettor, betAmount), "Refund transfer failed");
            }
        }

        emit BetCancelled(_betId);
    }

    // Function to get information about a specific bet instance
    function getBetInfo(uint256 _betId) external view returns (
        address creator,
        string memory title,
        string[] memory options,
        bool isClosed,
        bool isResolved,
        uint256 totalAmountBet,
        uint256[] memory totalAmounts,
        address tokenAddress,
        uint8 winningOption
    ) {
        BetInstance storage betInstance = betInstances[_betId];

        creator = betInstance.creator;
        title = betInstance.title;
        options = betInstance.options;
        isClosed = betInstance.isClosed;
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
            isClosed,
            isResolved,
            totalAmountBet,
            totalAmounts,
            tokenAddress,
            winningOption
        );
    }

    // Check if a bet has already been paid
    function isBetPaid(uint256 _betId) external view returns (bool) {
        return betInstances[_betId].isPaid;
    }

    // Check if a bet is currently in the payment processing state
    function isPaymentProcessing(uint256 _betId) external view returns (bool) {
        return betInstances[_betId].isProcessingPayment;
    }

    // Get all open bets for a specific address
    function getOpenBetsByAddress(address _bettor) external view returns (
        uint256[] memory openBetIds, 
        string[] memory titles, 
        uint256[] memory amounts, 
        string[][] memory options
    ) {
        uint256 openBetCount = 0;

        // Count all open bets for the specified address
        for (uint256 i = 1; i < nextBetId; i++) {
            BetInstance storage betInstance = betInstances[i];
            if (!betInstance.isClosed && betInstance.bets[_bettor].length > 0) {
                openBetCount++;
            }
        }

        // Create arrays to store the information
        openBetIds = new uint256[](openBetCount);
        titles = new string[](openBetCount);
        amounts = new uint256[](openBetCount);
        options = new string[][](openBetCount);

        uint256 index = 0;

        // Fill the arrays with the open bet information
        for (uint256 i = 1; i < nextBetId; i++) {
            BetInstance storage betInstance = betInstances[i];

            if (!betInstance.isClosed && betInstance.bets[_bettor].length > 0) {
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

    // Get all open bets in the contract
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
            if (!betInstance.isClosed) {
                openBetCount++;
            }
        }

        // Create arrays to store the information
        openBetIds = new uint256[](openBetCount);
        titles = new string[](openBetCount);
        options = new string[][](openBetCount);
        minimumBetAmounts = new uint256[](openBetCount);
        creators = new address[](openBetCount);

        uint256 index = 0;

        // Fill the arrays with the open bet information
        for (uint256 i = 1; i < nextBetId; i++) {
            BetInstance storage betInstance = betInstances[i];

            if (!betInstance.isClosed) {
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
