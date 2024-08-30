// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import "./Ownable.sol";

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
        mapping(uint256 => Bet) bets; // mapping of bettors array indxes to their bets
        address[] bettors;
    }
    
    mapping(uint256 => Game) public games;

    event NewGame(uint256 gameId);
    event NewBet(uint256 gameId, address user, bool bettingOnPlayer, uint256 amount, BetState state);
    event BetWithdrawn(uint256 gameId, address user, uint256 amount);
    event GameClosed(uint256 gameId);
    event WinningsDistributed(uint256 gameId, uint256 totalWinnings, uint256 totalWinners);
    
    constructor() {}

    function findBetIndex(address[] storage bettors, address bettor) internal view returns (uint256) {
        for (uint256 i = 0; i < bettors.length; i++) {
            if (bettors[i] == bettor) {
                return i;
            }
        }
        return type(uint256).max; // Returning max uint256 as an indicator of "not found"
    }

    function createGame(uint256 _gameId) public onlyOwner {
        require(games[_gameId].state == GameState.FINISHED, "Game with this ID already exists or is not finished yet.");
        Game storage newGame = games[_gameId];
        newGame.id = _gameId;
        newGame.state = GameState.OPEN;
        newGame.playerBetsTotal = 0;
        newGame.casinoBetsTotal = 0;
        newGame.totalBetPool = 0;

        emit NewGame(_gameId);
    }
    
    function placeBet(uint256 _gameId, bool _bettingOnPlayer) public payable {
        require(games[_gameId].state == GameState.OPEN, "Game is not open for betting");
        require(msg.value > 0, "Bet amount must be greater than 0");

        Game storage game = games[_gameId];
        uint256 betIndex = findBetIndex(game.bettors, msg.sender);
        Bet memory bet;
        if (betIndex != type(uint256).max) {
            bet = game.bets[betIndex];
            require(bet.user == msg.sender, "This isn't your bet");
            bet.amount += msg.value;
        } else {
            bet = Bet({
                user: payable(msg.sender),
                amount: msg.value,
                bettingOnPlayer: _bettingOnPlayer,
                state: BetState.PENDING,
                gameId: _gameId
            });

            game.bettors.push(msg.sender);
            game.bets[game.bettors.length - 1] = bet;
        }

        if (_bettingOnPlayer) {
            game.playerBetsTotal += msg.value;
        } else {
            game.casinoBetsTotal += msg.value;
        }

        game.totalBetPool += msg.value;

        emit NewBet(_gameId, msg.sender, _bettingOnPlayer, msg.value, BetState.PENDING);
    }

    function withdrawBet(uint256 _gameId) public {
        require(games[_gameId].state == GameState.OPEN, "Game is not open for bet withdrawal");
        Game storage game = games[_gameId];
        uint256 betIndex = findBetIndex(game.bettors, msg.sender);
        require(betIndex != type(uint256).max, "You don't have bets on this game");
        Bet storage bet = game.bets[betIndex];
        require(bet.state == BetState.PENDING, "Bet is not pending or already withdrawn");
        uint256 betAmount = bet.amount;
        if (bet.bettingOnPlayer) {
            game.playerBetsTotal -= betAmount;
        } else {
            game.casinoBetsTotal -= betAmount;
        }

        game.totalBetPool -= betAmount;
        payable(msg.sender).transfer(betAmount);

        uint256 lastIndex = game.bettors.length - 1;
        game.bettors[betIndex] = game.bettors[lastIndex]; // replace the old bettors address with the last one in the array
        game.bets[betIndex] = game.bets[lastIndex]; // replace the old bet key index with the last on the mapping
        game.bettors.pop(); // delete the last bettors address
        delete game.bets[lastIndex]; // delete the duplicate k/v address/Bet pair

        emit BetWithdrawn(_gameId, msg.sender, betAmount);
    }

    function closeGame(uint256 _gameId) public onlyOwner {
        Game storage game = games[_gameId];
        require(game.state == GameState.OPEN, "Game is already closed or finished");
        game.state = GameState.CLOSED;

        emit GameClosed(_gameId);
    }

    function distributeWinnings(uint256 _gameId, bool playerWon) public onlyOwner {
        require(games[_gameId].state == GameState.CLOSED, "Game is not closed for betting yet");
        Game storage game = games[_gameId];
        game.state = GameState.FINISHED;

        uint256 commission = (game.totalBetPool * 3) / 100; // 3% commission
        uint256 totalWinnings = game.totalBetPool - commission;
        uint256 casinoBetsTotalMinusComission = game.casinoBetsTotal - (game.casinoBetsTotal * 3 / 100);
        uint256 playerBetsTotalMinusComission = game.playerBetsTotal - (game.playerBetsTotal * 3 / 100);
        // formula( bet + (bet / totalBetsOnYourTeam * total bet on the other team)
        uint256 payoutRatio = 0;
        if (playerWon) {
            payoutRatio = (casinoBetsTotalMinusComission * 10000) / playerBetsTotalMinusComission;
        } else {
            payoutRatio = (playerBetsTotalMinusComission * 10000) / casinoBetsTotalMinusComission;
        }

        uint256 totalWinners = distributeToWinners(game, playerWon, payoutRatio);
        // Transfer the commission to the owner of the contract
        payable(owner()).transfer(commission);
        emit WinningsDistributed(_gameId, totalWinnings, totalWinners);
    }

    function distributeToWinners(Game storage game, bool playerWon, uint256 payoutRatio) internal returns (uint256 totalWinners) {
        for (uint256 i = 0; i < game.bettors.length; i++) {
            Bet storage bet = game.bets[i];
            if (playerWon == bet.bettingOnPlayer) {
                uint256 winnings = (bet.amount * (10000 + payoutRatio)) / 10000;
                bet.user.transfer(winnings);
                bet.state = BetState.WON;
                totalWinners++;
            } else {
                bet.state = BetState.LOST;
            }
        }
        return totalWinners;
    }
}