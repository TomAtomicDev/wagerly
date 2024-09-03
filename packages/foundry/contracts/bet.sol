// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Wagerly {
    address private constant FEE_ADDRESS = 0xD7bF67d127Ea9c7F58122E965F2F7aE8f1b5032E;

    struct Bet {
        address bettor;
        uint256 amount;
    }

    struct BetInstance {
        string id;
        string[] options;  // Array de nombres de opciones
        uint256[] totalAmounts;  // Array de montos totales por opción
        uint256 minimumBetAmount;
        address tokenAddress;
        mapping(address => Bet[]) bets;  // Mapeo de apostadores a sus apuestas
        address[] bettors;
        address creator;
        bool isClosed;
        bool isResolved;
        uint8 winningOption;
    }

    mapping(string => BetInstance) private betInstances;

    event BetInstanceCreated(address creator, string indexed betId, string[] options, uint256 minimumBetAmount, address tokenAddress);
    event BetPlaced(string indexed betId, address indexed bettor, uint256 amount, uint8 option);
    event BettingClosed(string indexed betId);
    event BettingResolved(string indexed betId, uint8 winningOption);
    event BetCancelled(string indexed betId);

    modifier onlyCreator(string memory _betId) {
        if (msg.sender != betInstances[_betId].creator) {
            revert("Not authorized");
        }
        _;
    }

    function createBetInstance(
    string calldata _betId,
    uint8 _numOptions,
    string[] calldata _optionNames,
    uint256 _minimumBetAmount,
    address _tokenAddress
) external {
    require(_numOptions >= 2 && _numOptions <= 5, "Invalid number of options");
    require(_optionNames.length == _numOptions, "Option names length mismatch");

    if (bytes(betInstances[_betId].id).length != 0) {
        revert("Bet instance with this ID already exists");
    }

    BetInstance storage newInstance = betInstances[_betId];
    newInstance.id = _betId;
    newInstance.minimumBetAmount = _minimumBetAmount;
    newInstance.creator = msg.sender;
    newInstance.tokenAddress = _tokenAddress;
    newInstance.totalAmounts = new uint256[](_numOptions);

    // Copiamos manualmente los nombres de las opciones del array de calldata al array de storage
    for (uint8 i = 0; i < _numOptions; i++) {
        newInstance.options.push(_optionNames[i]);
    }

    emit BetInstanceCreated(msg.sender, _betId, _optionNames, _minimumBetAmount, _tokenAddress);
}

    function placeBet(string calldata _betId, uint256 _amount, uint8 _option) external {
        BetInstance storage betInstance = betInstances[_betId];
        require(!betInstance.isClosed, "Betting is closed");
        require(_amount >= betInstance.minimumBetAmount, "Bet amount is less than minimum");
        require(_option >= 1 && _option <= betInstance.options.length, "Invalid option");

        IERC20 token = IERC20(betInstance.tokenAddress);
        require(token.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        betInstance.totalAmounts[_option - 1] += _amount;
        betInstance.bets[msg.sender].push(Bet(msg.sender, _amount));
        betInstance.bettors.push(msg.sender);

        emit BetPlaced(_betId, msg.sender, _amount, _option);
    }

    function closeBetting(string calldata _betId) external onlyCreator(_betId) {
        BetInstance storage betInstance = betInstances[_betId];
        betInstance.isClosed = true;
        emit BettingClosed(_betId);
    }

    function distributeWinnings(string calldata _betId, uint8 _winningOption) external onlyCreator(_betId) {
        require(_winningOption >= 1 && _winningOption <= betInstances[_betId].options.length, "Invalid winning option");

        BetInstance storage betInstance = betInstances[_betId];
        require(betInstance.isClosed && !betInstance.isResolved, "Betting must be closed and not resolved");

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

    function cancelBet(string calldata _betId) external onlyCreator(_betId) {
        BetInstance storage betInstance = betInstances[_betId];
        require(!betInstance.isResolved, "Betting already resolved");

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

    function getBetInfo(string calldata _betId) external view returns (
        address creator,
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
            options,
            isClosed,
            isResolved,
            totalAmountBet,
            totalAmounts,
            tokenAddress,
            winningOption
        );
    }
}
