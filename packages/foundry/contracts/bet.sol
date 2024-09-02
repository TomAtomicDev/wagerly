// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Wagerly {

    struct Bet {
        address bettor;
        uint256 amount;
    }

    struct BetInstance {
        string id;
        string option1;
        string option2;
        uint256 totalAmountOption1;
        uint256 totalAmountOption2;
        uint256 minimumBetAmount;
        mapping(address => Bet) betsoption1;
        mapping(address => Bet) betsoption2;
        address[] bettorsoption1;
        address[] bettorsoption2;
        address creator;
        bool isClosed;
        bool isResolved;
    }

    address private constant FEE_ADDRESS = 0xd806A01E295386ef7a7Cea0B9DA037B242622743;
    mapping(string => BetInstance) private betInstances;
    IERC20 private Token;

    event BetInstanceCreated(address creator, string indexed betId, string option1, string option2, uint256 minimumBetAmount);
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

    constructor(address token) {
        Token = IERC20(token);
    }

    function createBetInstance(string calldata _betId, string calldata _option1, string calldata _option2, uint256 _minimumBetAmount) external {
        if (bytes(betInstances[_betId].id).length != 0) {
            revert("Bet instance with this ID already exists");
        }

        BetInstance storage newInstance = betInstances[_betId];
        newInstance.id = _betId;
        newInstance.option1 = _option1;
        newInstance.option2 = _option2;
        newInstance.minimumBetAmount = _minimumBetAmount;
        newInstance.creator = msg.sender;
        emit BetInstanceCreated(msg.sender, _betId, _option1, _option2, _minimumBetAmount);
    }

    function placeBetOnoption1(string calldata _betId, uint256 _amount) external {
        BetInstance storage betInstance = betInstances[_betId];
        if (betInstance.isClosed) {
            revert("Betting is closed");
        }
        if (_amount < betInstance.minimumBetAmount) {
            revert("Bet amount is less than minimum");
        }

        if (!Token.transferFrom(msg.sender, address(this), _amount)) {
            revert("Transfer failed");
        }
        betInstance.totalAmountOption1 += _amount;
        betInstance.betsoption1[msg.sender] = Bet(msg.sender, _amount);
        betInstance.bettorsoption1.push(msg.sender);
        
        emit BetPlaced(_betId, msg.sender, _amount, 1);
    }

    function placeBetOnoption2(string calldata _betId, uint256 _amount) external {
        BetInstance storage betInstance = betInstances[_betId];
        if (betInstance.isClosed) {
            revert("Betting is closed");
        }
        if (_amount < betInstance.minimumBetAmount) {
            revert("Bet amount is less than minimum");
        }

        if (!Token.transferFrom(msg.sender, address(this), _amount)) {
            revert("Transfer failed");
        }
        betInstance.totalAmountOption2 += _amount;
        betInstance.betsoption2[msg.sender] = Bet(msg.sender, _amount);
        betInstance.bettorsoption2.push(msg.sender);

        emit BetPlaced(_betId, msg.sender, _amount, 2);
    }

    function closeBetting(string calldata _betId) external onlyCreator(_betId) {
        BetInstance storage betInstance = betInstances[_betId];
        betInstance.isClosed = true;
        emit BettingClosed(_betId);
    }

    function getTotalAmounts(string calldata _betId) external view returns (uint256 total, uint256 totaloption1, uint256 totaloption2, uint256 minimumBetAmount, bool isClosed, bool isResolved) {
        BetInstance storage betInstance = betInstances[_betId];
        totaloption1 = betInstance.totalAmountOption1;
        totaloption2 = betInstance.totalAmountOption2;
        total = totaloption1 + totaloption2;
        minimumBetAmount = betInstance.minimumBetAmount;
        isClosed = betInstance.isClosed;
        isResolved = betInstance.isResolved;
    }

    function distributeWinnings(string calldata _betId, uint8 _winningOption) external onlyCreator(_betId) {
        if (_winningOption != 1 && _winningOption != 2) {
            revert("Invalid winning option");
        }

        BetInstance storage betInstance = betInstances[_betId];
        if (!betInstance.isClosed || betInstance.isResolved) {
            revert("Betting must be closed and not resolved");
        }

        uint256 totalAmountToDistribute = betInstance.totalAmountOption1 + betInstance.totalAmountOption2;
        uint256 totalAmountWinningOption;
        address[] memory losers;
        address[] memory winners;

        // Determinar el total apostado en el equipo ganador
        if (_winningOption == 1) {
            winners = betInstance.bettorsoption1;
            losers = betInstance.bettorsoption2;
            totalAmountWinningOption = betInstance.totalAmountOption1;
        } else {
            winners = betInstance.bettorsoption2;
            losers = betInstance.bettorsoption1;
            totalAmountWinningOption = betInstance.totalAmountOption2;
        }

        // Calcular y transferir el 1% del total al FEE_ADDRESS y al creador
        uint256 fee = totalAmountToDistribute / 100;
        uint256 creatorFee = fee;
        uint256 remainingAmount = totalAmountToDistribute - fee - creatorFee;
        
        if (!Token.transfer(FEE_ADDRESS, fee)) {
            revert("Fee transfer failed");
        }
        if (!Token.transfer(betInstance.creator, creatorFee)) {
            revert("Creator fee transfer failed");
        }

        // Verificar si hay ganadores
        if (winners.length == 0) {
            // Devolver el dinero a los que apostaron
            for (uint256 i = 0; i < losers.length; i++) {
                address loser = losers[i];
                uint256 betAmount = (_winningOption == 1) ? betInstance.betsoption2[loser].amount : betInstance.betsoption1[loser].amount;

                // Calcular el porcentaje de la apuesta del apostador respecto al total del equipo perdedor
                uint256 amountToTransfer = (betAmount * (totalAmountToDistribute - fee - creatorFee)) / totalAmountToDistribute;
                
                if (!Token.transfer(loser, amountToTransfer)) {
                    revert("Loser transfer failed");
                }
            }
        } else {
            // Calcular y transferir los fondos a los ganadores
            for (uint256 i = 0; i < winners.length; i++) {
                address winner = winners[i];
                uint256 betAmount = (_winningOption == 1) ? betInstance.betsoption1[winner].amount : betInstance.betsoption2[winner].amount;

                // Calcular el porcentaje de la apuesta del ganador respecto al total del equipo ganador
                uint256 amountToTransfer = (betAmount * remainingAmount) / totalAmountWinningOption;

                if (!Token.transfer(winner, amountToTransfer)) {
                    revert("Winner transfer failed");
                }
            }
        }

        betInstance.isResolved = true;
        emit BettingResolved(_betId, _winningOption);
    }

    function cancelBet(string calldata _betId) external onlyCreator(_betId) {
        BetInstance storage betInstance = betInstances[_betId];
        if (betInstance.isResolved) {
            revert("Betting already resolved");
        }

        uint256 totalAmountToDistribute = betInstance.totalAmountOption1 + betInstance.totalAmountOption2;

        // Calcular y transferir el 1% del total al FEE_ADDRESS y al creador
        uint256 fee = totalAmountToDistribute / 100;
        uint256 creatorFee = fee;
        uint256 remainingAmount = totalAmountToDistribute - fee - creatorFee;
        
        if (!Token.transfer(FEE_ADDRESS, fee)) {
            revert("Fee transfer failed");
        }
        if (!Token.transfer(betInstance.creator, creatorFee)) {
            revert("Creator fee transfer failed");
        }

        // Devolver el dinero a los apostadores de la opción 1
        for (uint256 i = 0; i < betInstance.bettorsoption1.length; i++) {
            address bettor = betInstance.bettorsoption1[i];
            uint256 betAmount = betInstance.betsoption1[bettor].amount;
            uint256 amountToTransfer = (betAmount * remainingAmount) / totalAmountToDistribute;
            if (!Token.transfer(bettor, amountToTransfer)) {
                revert("Option 1 bettor transfer failed");
            }
        }

        // Devolver el dinero a los apostadores de la opción 2
        for (uint256 i = 0; i < betInstance.bettorsoption2.length; i++) {
            address bettor = betInstance.bettorsoption2[i];
            uint256 betAmount = betInstance.betsoption2[bettor].amount;
            uint256 amountToTransfer = (betAmount * remainingAmount) / totalAmountToDistribute;
            if (!Token.transfer(bettor, amountToTransfer)) {
                revert("Option 2 bettor transfer failed");
            }
        }

        betInstance.isResolved = true;
        emit BetCancelled(_betId);
    }
}