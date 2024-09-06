// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;
import "./Ownable.sol";
import "forge-std/console.sol";
contract IntelliCasinoBetting is Ownable {

    enum BetState {PENDING, WON, LOST}
    enum GameState {OPEN, CLOSED, FINISHED}

    struct Bet {
        address payable user;
        uint256 amount;
        bool bettingOnPlayer; // true = player wins, false = Intelli Casino wins
        BetState state;
        uint256 gameId;
    }
    
    struct Game {
        uint256 id; // Game ID passed from the frontend
        GameState state;
        uint256 playerBetsTotal;
        uint256 casinoBetsTotal;
        uint256 totalBetPool;
        mapping(uint256 => Bet) bets; // mapping of bettor indices to their bets
        address[] bettors;
    }
    
    mapping(uint256 => Game) public games;

    event NewGame(uint256 indexed gameId);
    event NewBet(uint256 indexed gameId, address indexed user, bool bettingOnPlayer, uint256 amount, BetState state);
    event BetWithdrawn(uint256 indexed gameId, address indexed user, uint256 amount);
    event GameClosed(uint256 indexed gameId);
    event WinningsDistributed(uint256 indexed gameId, uint256 totalWinnings, uint256 totalWinners);

    error InvalidGameId();
    error GameAlreadyExists();
    error GameNotOpen();
    error GameNotClosed();
    error GameAlreadyFinished();
    error NotEnoughBetAmount();
    error BetDoesNotExist();
    error BetNotPending();
    error TransferFailed();

    modifier onlyExistingGame(uint256 _gameId) {
        if (games[_gameId].id != _gameId) revert InvalidGameId();
        _;
    }

    constructor() {}

    function findBetIndex(address[] storage bettors, address bettor) internal view returns (uint256) {
        for (uint256 i = 0; i < bettors.length; i++) {
            if (bettors[i] == bettor) {
                return i;
            }
        }
        return type(uint256).max; // Returning max uint256 as an indicator of "not found"
    }

    function createGame(uint256 _gameId) external onlyOwner {
        if (games[_gameId].id == _gameId) revert GameAlreadyExists();
        
        Game storage newGame = games[_gameId];
        newGame.id = _gameId;
        newGame.state = GameState.OPEN;

        emit NewGame(_gameId);
    }
    
    function placeBet(uint256 _gameId, bool _bettingOnPlayer) external payable onlyExistingGame(_gameId) {
        Game storage game = games[_gameId];
        if (game.state != GameState.OPEN) revert GameNotOpen();
        if (msg.value == 0) revert NotEnoughBetAmount();

        uint256 betIndex = findBetIndex(game.bettors, msg.sender);
        Bet storage bet;
        if (betIndex != type(uint256).max) {
            bet = game.bets[betIndex];
            require(bet.user == msg.sender, "This isn't your bet");
            bet.amount += msg.value;
        } else {
            bet = game.bets[game.bettors.length];
            bet.user = payable(msg.sender);
            bet.amount = msg.value;
            bet.bettingOnPlayer = _bettingOnPlayer;
            bet.state = BetState.PENDING;
            bet.gameId = _gameId;
            
            game.bettors.push(msg.sender);
        }
        
        if (_bettingOnPlayer) {
            game.playerBetsTotal += msg.value;
        } else {
            game.casinoBetsTotal += msg.value;
        }

        game.totalBetPool += msg.value;

        emit NewBet(_gameId, msg.sender, _bettingOnPlayer, msg.value, BetState.PENDING);
    }

    function withdrawBet(uint256 _gameId) external onlyExistingGame(_gameId) {
        Game storage game = games[_gameId];
        if (game.state != GameState.OPEN) revert GameNotOpen();
        
        uint256 betIndex = findBetIndex(game.bettors, msg.sender);
        if (betIndex == type(uint256).max) revert BetDoesNotExist();
        
        Bet storage bet = game.bets[betIndex];
        if (bet.state != BetState.PENDING) revert BetNotPending();

        uint256 betAmount = bet.amount;
        address payable betUser = bet.user;
        if (bet.bettingOnPlayer) {
            game.playerBetsTotal -= betAmount;
        } else {
            game.casinoBetsTotal -= betAmount;
        }

        game.totalBetPool -= betAmount;

        uint256 lastIndex = game.bettors.length - 1;
        if (betIndex != lastIndex) {
            game.bettors[betIndex] = game.bettors[lastIndex];
            game.bets[betIndex] = game.bets[lastIndex];
        }
        game.bettors.pop();
        delete game.bets[lastIndex];
        
        emit BetWithdrawn(_gameId, msg.sender, betAmount);
        bool sent = betUser.send(betAmount);
        if (!sent) revert TransferFailed();

    }

    function closeGame(uint256 _gameId) external onlyOwner onlyExistingGame(_gameId) {
        Game storage game = games[_gameId];
        if (game.state != GameState.OPEN) revert GameNotOpen();
        game.state = GameState.CLOSED;

        emit GameClosed(_gameId);
    }

    function distributeWinnings(uint256 _gameId, bool playerWon) external onlyOwner onlyExistingGame(_gameId) {
        Game storage game = games[_gameId];
        if (game.state != GameState.CLOSED) revert GameNotClosed();
        if (game.state == GameState.FINISHED) revert GameAlreadyFinished();

        game.state = GameState.FINISHED;

        uint256 commission = (game.totalBetPool * 3) / 100; // 3% commission
        uint256 totalWinnings = game.totalBetPool - commission;

        uint256 payoutRatio = 0;
        if (playerWon) {
            payoutRatio = (game.casinoBetsTotal * 10000) / game.playerBetsTotal;
        } else {
            payoutRatio = (game.playerBetsTotal * 10000) / game.casinoBetsTotal;
        }
        

        // Transfer the commission to the owner of the contract
        uint256 totalWinners = distributeToWinners(game, playerWon, payoutRatio);
        emit WinningsDistributed(_gameId, totalWinnings, totalWinners);
        
        bool sent = payable(owner()).send(commission);
        if (!sent) revert TransferFailed();

    }

    function distributeToWinners(Game storage game, bool playerWon, uint256 payoutRatio) internal returns (uint256 totalWinners) {
        for (uint256 i = 0; i < game.bettors.length; i++) {
            Bet storage bet = game.bets[i];
            if (playerWon == bet.bettingOnPlayer) {
                uint256 winnings = (bet.amount * (10000 + payoutRatio)) / 10000;
                winnings = winnings - ((winnings * 3) / 100);
                bool sent = bet.user.send(winnings);
                if (!sent) revert TransferFailed();
                bet.state = BetState.WON;
                totalWinners++;
            } else {
                bet.state = BetState.LOST;
            }
        }
        return totalWinners;
    }
}