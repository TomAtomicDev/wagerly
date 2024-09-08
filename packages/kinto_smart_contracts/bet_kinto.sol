// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract WagerlyKinto {
    address private constant FEE_ADDRESS = 0x9b63FA365019Dd7bdF8cBED2823480F808391970;
    uint256 private nextBetId = 1;  

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
        mapping(address => Bet[]) bets;  
        address[] bettors;
        address creator;
        bool isOpen;
        bool isResolved;
        uint8 winningOption;
        bool isCanceled;
    }

    mapping(uint256 => BetInstance) private betInstances;

    event BetInstanceCreated(address creator, uint256 indexed betId, string title, string[] options, uint256 minimumBetAmount, address tokenAddress);
    event BetPlaced(uint256 indexed betId, address indexed bettor, uint256 amount, uint8 option);
    event BettingClosed(uint256 indexed betId);
    event BettingResolved(uint256 indexed betId, uint8 winningOption);
    event BetCancelled(uint256 indexed betId);

    modifier onlyCreator(uint256 _betId) {
        if (msg.sender != betInstances[_betId].creator) {
            revert("Not authorized");
        }
        _;
    }

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
        nextBetId++; 

        if (betInstances[betId].creator != address(0)) {
            revert("Bet instance with this ID already exists");
        }

        BetInstance storage newInstance = betInstances[betId];
        newInstance.id = betId;
        newInstance.title = _title;        
        newInstance.minimumBetAmount = _minimumBetAmount;
        newInstance.creator = msg.sender;
        newInstance.tokenAddress = _tokenAddress;
        newInstance.totalAmounts = new uint256[](_numOptions);

        for (uint8 i = 0; i < _numOptions; i++) {
            newInstance.options.push(_optionNames[i]);
        }

        emit BetInstanceCreated(msg.sender, betId, _title, _optionNames, _minimumBetAmount, _tokenAddress);
    }

    function placeBet(uint256 _betId, uint256 _amount, uint8 _option) external {
        BetInstance storage betInstance = betInstances[_betId];
        require(betInstance.isOpen, "Betting is closed");
        require(_amount >= betInstance.minimumBetAmount, "Bet amount is less than minimum");
        require(_option >= 1 && _option <= betInstance.options.length, "Invalid option");

        IERC20 token = IERC20(betInstance.tokenAddress);
        require(token.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        betInstance.totalAmounts[_option - 1] += _amount;
        betInstance.bets[msg.sender].push(Bet(msg.sender, _amount));
        betInstance.bettors.push(msg.sender);

        emit BetPlaced(_betId, msg.sender, _amount, _option);
    }

    function closeBetting(uint256 _betId) external onlyCreator(_betId) {
        BetInstance storage betInstance = betInstances[_betId];
        betInstance.isOpen = false;
        emit BettingClosed(_betId);
    }

    function distributeWinnings(uint256 _betId, uint8 _winningOption) external onlyCreator(_betId) {
        require(_winningOption >= 1 && _winningOption <= betInstances[_betId].options.length, "Invalid winning option");

        BetInstance storage betInstance = betInstances[_betId];
        require(!betInstance.isOpen && !betInstance.isResolved, "Betting must be closed and not resolved");

        IERC20 token = IERC20(betInstance.tokenAddress);

        uint256 totalAmountToDistribute = 0;
        for (uint8 i = 0; i < betInstance.totalAmounts.length; i++) {
            totalAmountToDistribute += betInstance.totalAmounts[i];
        }
        uint256 totalAmountWinningOption = betInstance.totalAmounts[_winningOption - 1];

        uint256 fee = totalAmountToDistribute / 100;
        uint256 creatorFee = fee;
        uint256 remainingAmount = totalAmountToDistribute - fee - creatorFee;
        
        require(token.transfer(FEE_ADDRESS, fee), "Fee transfer failed");
        require(token.transfer(betInstance.creator, creatorFee), "Creator fee transfer failed");

        if (betInstance.bettors.length == 0) {
            revert("No bets placed");
        } else {
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
        }

        betInstance.isResolved = true;
        betInstance.winningOption = _winningOption;
        emit BettingResolved(_betId, _winningOption);
    }

    function cancelBet(uint256 _betId) external onlyCreator(_betId) {
        BetInstance storage betInstance = betInstances[_betId];
        require(!betInstance.isResolved, "Betting already resolved");
        betInstance.isCanceled = true;
        IERC20 token = IERC20(betInstance.tokenAddress);

        uint256 totalAmountToDistribute = 0;
        for (uint8 i = 0; i < betInstance.totalAmounts.length; i++) {
            totalAmountToDistribute += betInstance.totalAmounts[i];
        }

        uint256 fee = totalAmountToDistribute / 100;
        uint256 creatorFee = fee;
        uint256 remainingAmount = totalAmountToDistribute - fee - creatorFee;
        
        require(token.transfer(FEE_ADDRESS, fee), "Fee transfer failed");
        require(token.transfer(betInstance.creator, creatorFee), "Creator fee transfer failed");

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

    function getOpenBetsByAddress(address _bettor) external view returns (
        uint256[] memory openBetIds, 
        string[] memory titles, 
        uint256[] memory amounts, 
        string[][] memory options
    ) {
        uint256 openBetCount = 0;

        for (uint256 i = 1; i < nextBetId; i++) {
            BetInstance storage betInstance = betInstances[i];
            
            if (betInstance.isOpen && betInstance.bets[_bettor].length > 0) {
                openBetCount++;
            }
        }

        openBetIds = new uint256[](openBetCount);
        titles = new string[](openBetCount);
        amounts = new uint256[](openBetCount);
        options = new string[][](openBetCount);

        uint256 index = 0;

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

    function getAllOpenBets() external view returns (
        uint256[] memory openBetIds, 
        string[] memory titles, 
        string[][] memory options, 
        uint256[] memory minimumBetAmounts, 
        address[] memory creators
    ) {
        uint256 openBetCount = 0;

        for (uint256 i = 1; i < nextBetId; i++) {
            BetInstance storage betInstance = betInstances[i];
            if (betInstance.isOpen) {
                openBetCount++;
            }
        }

        openBetIds = new uint256[](openBetCount);
        titles = new string[](openBetCount);
        options = new string[][](openBetCount);
        minimumBetAmounts = new uint256[](openBetCount);
        creators = new address[](openBetCount);

        uint256 index = 0;

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