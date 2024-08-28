pragma solidity ^0.8.0;

import "./Ownable.sol";

contract IntelliCasinoBetting is Ownable {

    enum BetState {PENDING, WON, LOST}
    enum GameState {OPEN, CLOSED, FINISHED}

    struct Bet {
        uint256 betId;
        uint256 gameId;
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
        uint256 nextBetId;
        mapping(uint256 => Bet) bets; // mapping of betId to Bet struct
        uint256[] betIds; // array of betIds for iteration
    }
    
    mapping(uint256 => Game) public games;

    event NewGame(uint256 gameId);
    event NewBet(uint256 gameId, uint256 betId, address user, bool bettingOnPlayer, uint256 amount);
    event BetWithdrawn(uint256 gameId, uint256 betId, address user);
    event GameClosed(uint256 gameId);
    event WinningsDistributed(uint256 gameId, uint256 totalWinnings);
    
    constructor() {}

    function createGame(uint256 _gameId) public onlyOwner {
        require(games[_gameId].state == GameState.FINISHED, "Game with this ID already exists or is not finished yet.");
        
        Game storage newGame = games[_gameId];
        newGame.id = _gameId;
        newGame.state = GameState.OPEN;
        newGame.playerBetsTotal = 0;
        newGame.casinoBetsTotal = 0;
        newGame.totalBetPool = 0;
        newGame.nextBetId = 0;

        emit NewGame(_gameId);
    }
    
    function placeBet(uint256 _gameId, bool bettingOnPlayer) public payable {
        Game storage game = games[_gameId];
        require(game.state == GameState.OPEN, "Game is not open for betting");
        require(msg.value > 0, "Bet amount must be greater than 0");

        uint256 betId = game.nextBetId++;
        Bet memory newBet = Bet({
            betId: betId,
            gameId: _gameId,
            user: msg.sender,
            amount: msg.value,
            bettingOnPlayer: bettingOnPlayer,
            state: BetState.PENDING
        });

        game.bets[betId] = newBet;
        game.betIds.push(betId);

        if (bettingOnPlayer) {
            game.playerBetsTotal += msg.value;
        } else {
            game.casinoBetsTotal += msg.value;
        }

        game.totalBetPool += msg.value;

        emit NewBet(_gameId, betId, msg.sender, bettingOnPlayer, msg.value);
    }

    function withdrawBet(uint256 _gameId, uint256 betId) public {
        Game storage game = games[_gameId];
        Bet storage bet = game.bets[betId];
        
        require(game.state == GameState.OPEN, "Game is not open for bet withdrawal");
        require(bet.user == msg.sender, "You can only withdraw your own bet");
        require(bet.state == BetState.PENDING, "Bet is not pending or already withdrawn");

        if (bet.bettingOnPlayer) {
            game.playerBetsTotal -= bet.amount;
        } else {
            game.casinoBetsTotal -= bet.amount;
        }

        game.totalBetPool -= bet.amount;
        payable(msg.sender).transfer(bet.amount);

        // Remove bet by replacing it with the last bet in the array and popping it
        uint256 betIndex = findBetIndex(game.betIds, betId);
        game.betIds[betIndex] = game.betIds[game.betIds.length - 1];
        game.betIds.pop();
        delete game.bets[betId];

        emit BetWithdrawn(_gameId, betId, msg.sender);
    }

    function findBetIndex(uint256[] storage betIds, uint256 betId) internal view returns (uint256) {
        for (uint256 i = 0; i < betIds.length; i++) {
            if (betIds[i] == betId) {
                return i;
            }
        }
        revert("Bet ID not found");
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
        uint256 totalWinnings = game.totalBetPool - commission; // Total pool after commission deduction

        uint256 payoutRatio = 0;
        if (playerWon) {
            payoutRatio = (game.casinoBetsTotal * 10000) / game.playerBetsTotal;
            distributeToWinners(game, true, payoutRatio);
        } else {
            payoutRatio = (game.playerBetsTotal * 10000) / game.casinoBetsTotal;
            distributeToWinners(game, false, payoutRatio);
        }

        // Transfer the commission to the owner
        payable(owner()).transfer(commission);

        emit WinningsDistributed(_gameId, totalWinnings);
    }

    function distributeToWinners(Game storage game, bool playerWon, uint256 payoutRatio) internal {
        for (uint256 i = 0; i < game.betIds.length; i++) {
            Bet storage bet = game.bets[game.betIds[i]];
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
