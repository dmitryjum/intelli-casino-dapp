// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import "./Ownable.sol";

contract IntelliCasinoBetting is Ownable {

    enum BetState {PENDING, WON, LOST}
    enum GameState {OPEN, CLOSED, FINISHED}

    struct Bet {
        address user;
        uint256 amount;
        bool bettingOnPlayer; // true = player wins, false = Intelli Casino wins
        BetState state;
    }
    
    struct Game {
        uint256 id; // Game ID passed from the frontend
        GameState state;
        uint256 playerBetsTotal;
        uint256 casinoBetsTotal;
        uint256 totalBetPool;
        mapping(address => Bet[]) bets; // mapping of user address to their bets
    }
    
    mapping(uint256 => Game) public games;

    event NewGame(uint256 gameId, string description);
    event NewBet(uint256 gameId, address user, bool bettingOnPlayer, uint256 amount);
    event BetWithdrawn(uint256 gameId, address user, uint256 betIndex);
    event GameClosed(uint256 gameId);
    event WinningsDistributed(uint256 gameId, uint256 totalWinnings);
    
    constructor() {}

    function createGame(uint256 _gameId, string memory _description) public onlyOwner {
        Game storage newGame = games[_gameId];
        newGame.id = _gameId;
        newGame.state = GameState.OPEN;
        newGame.playerBetsTotal = 0;
        newGame.casinoBetsTotal = 0;
        newGame.totalBetPool = 0;

        emit NewGame(_gameId, _description);
    }
    
    function placeBet(uint256 _gameId, bool bettingOnPlayer) public payable {
        require(games[_gameId].state == GameState.OPEN, "Game is not open for betting");
        require(msg.value > 0, "Bet amount must be greater than 0");

        Game storage game = games[_gameId];
        Bet memory newBet = Bet({
            user: msg.sender,
            amount: msg.value,
            bettingOnPlayer: bettingOnPlayer,
            state: BetState.PENDING
        });

        game.bets[msg.sender].push(newBet);

        if (bettingOnPlayer) {
            game.playerBetsTotal += msg.value;
        } else {
            game.casinoBetsTotal += msg.value;
        }

        game.totalBetPool += msg.value;

        emit NewBet(_gameId, msg.sender, bettingOnPlayer, msg.value);
    }

    function withdrawBet(uint256 _gameId, uint256 betIndex) public {
        Game storage game = games[_gameId];
        require(game.state == GameState.OPEN, "Game is not open for bet withdrawal");

        Bet storage bet = game.bets[msg.sender][betIndex];
        require(bet.state == BetState.PENDING, "Bet is not pending or already withdrawn");

        if (bet.bettingOnPlayer) {
            game.playerBetsTotal -= bet.amount;
        } else {
            game.casinoBetsTotal -= bet.amount;
        }

        game.totalBetPool -= bet.amount;
        payable(msg.sender).transfer(bet.amount);

        // Remove bet from user's bet list
        game.bets[msg.sender][betIndex] = game.bets[msg.sender][game.bets[msg.sender].length - 1];
        game.bets[msg.sender].pop();

        emit BetWithdrawn(_gameId, msg.sender, betIndex);
    }

    function closeGame(uint256 _gameId) public onlyOwner {
        Game storage game = games[_gameId];
        require(game.state == GameState.OPEN, "Game is already closed or finished");
        game.state = GameState.CLOSED;

        emit GameClosed(_gameId);
    }

    function distributeWinnings(uint256 _gameId, bool playerWon) public onlyOwner {
        Game storage game = games[_gameId];
        require(game.state == GameState.CLOSED, "Game is not closed for betting yet");
        game.state = GameState.FINISHED;

        uint256 commission = (game.totalBetPool * 3) / 100; // 3% commission
        uint256 totalWinnings = game.totalBetPool - commission;

        uint256 payoutRatio = 0;
        if (playerWon) {
            payoutRatio = (game.casinoBetsTotal * 10000) / game.playerBetsTotal;
            distributeToWinners(game, true, payoutRatio);
        } else {
            payoutRatio = (game.playerBetsTotal * 10000) / game.casinoBetsTotal;
            distributeToWinners(game, false, payoutRatio);
        }

        payable(owner()).transfer(commission);

        emit WinningsDistributed(_gameId, totalWinnings);
    }

    function distributeToWinners(Game storage game, bool playerWon, uint256 payoutRatio) internal {
        for (uint i = 0; i < game.bets[msg.sender].length; i++) {
            Bet storage bet = game.bets[msg.sender][i];
            if ((playerWon && bet.bettingOnPlayer) || (!playerWon && !bet.bettingOnPlayer)) {
                uint256 winnings = (bet.amount * (10000 + payoutRatio)) / 10000;
                payable(bet.user).transfer(winnings);
                bet.state = BetState.WON;
            } else {
                bet.state = BetState.LOST;
            }
        }
    }
}