// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";
import {IntelliCasinoBetting} from "../src/IntelliCasinoBetting.sol";

contract IntelliCasinoBettingTest is Test {
    IntelliCasinoBetting public betting;
    uint256 gameId = 1;
    address owner = address(this);
    address player = address(1);
    address casino = address(2);
    address bettor = address(3);
    uint256 betAmount = 1 ether;

    function setUp() public virtual {
        betting = new IntelliCasinoBetting();
    }

    function createGame(uint256 _gameId) internal {
        betting.createGame(_gameId);
    }

    function placeBet(uint256 _gameId, bool _bettingOnPlayer, uint256 _betAmount) internal {
        betting.placeBet{value: _betAmount}(_gameId, _bettingOnPlayer);
    }

    function withdrawBet(uint256 _gameId) internal {
        betting.withdrawBet(_gameId);
    }

    function closeGame(uint256 _gameId) internal {
        betting.closeGame(_gameId);
    }

    function distributeWinnings(uint256 _gameId, bool playerWon) internal {
        betting.distributeWinnings(_gameId, playerWon);
    }

    receive() external payable {}
}

contract CreateGameTest is IntelliCasinoBettingTest {
    event NewGame(uint256 indexed gameId);

    function setUp() public override {
        super.setUp();
    }

    function test_createGame() public {
        vm.expectEmit(true, true, true, true);
        emit NewGame(gameId);

        createGame(gameId);

        (uint256 _id, IntelliCasinoBetting.GameState state,,,) = betting.games(gameId);
        assertEq(_id, gameId);
        assertEq(uint(state), uint(IntelliCasinoBetting.GameState.OPEN));
    }

    function test_createGameAlreadyExists() public {
        createGame(gameId);
        vm.expectRevert(IntelliCasinoBetting.GameAlreadyExists.selector);
        createGame(gameId);
    }
}

contract PlaceBetTest is IntelliCasinoBettingTest {
    event NewBet(uint256 indexed gameId, address indexed user, bool bettingOnPlayer, uint256 amount, IntelliCasinoBetting.BetState state);

    function setUp() public override {
        super.setUp();
        createGame(gameId);
    }

    function test_placeBet() public {
        vm.expectEmit(true, true, true, true);
        hoax(bettor, betAmount);
        emit NewBet(gameId, bettor, true, betAmount, IntelliCasinoBetting.BetState.PENDING);
        
        placeBet(gameId, true, betAmount);
        (,,uint256 _playerBetsTotal, uint256 _casinoBetsTotal, uint256 _totalBetPool) = betting.games(gameId);
        assertEq(_playerBetsTotal, betAmount);
        assertEq(_casinoBetsTotal, 0);
        assertEq(_totalBetPool, betAmount);
    }

    function test_placeBetGameNotOpen() public {
        closeGame(gameId); // game's closed by the owner (this contract);
        hoax(bettor, betAmount); // bettor becomes the msg.sender for "placeBet" function
        vm.expectRevert(IntelliCasinoBetting.GameNotOpen.selector);
        placeBet(gameId, true, betAmount);
    }

    function test_placeBetNoAmount() public {
        vm.prank(bettor);
        vm.expectRevert(IntelliCasinoBetting.NotEnoughBetAmount.selector);
        placeBet(gameId, true, 0);
    }

    function test_placeBetAddToExisting() public {
        hoax(bettor, 3 ether);
        placeBet(gameId, true, betAmount);
        placeBet(gameId, true, betAmount);

        (,,uint256 _playerBetsTotal,,) = betting.games(gameId);
        assertEq(_playerBetsTotal, 2 ether);
    }
}

contract WithdrawBetTest is IntelliCasinoBettingTest {
    event BetWithdrawn(uint256 indexed gameId, address indexed user, uint256 amount);

    function setUp() public override {
        super.setUp();
        createGame(gameId);
        hoax(bettor, 1 ether);
        placeBet(gameId, true, betAmount);
    }

    function test_withdrawBet() public {
        vm.expectEmit(true, true, true, true);
        vm.prank(bettor);
        emit BetWithdrawn(gameId, bettor, betAmount);

        uint256 playerBalanceBefore = bettor.balance;
        withdrawBet(gameId);
        uint256 playerBalanceAfter = bettor.balance;

        assertEq(playerBalanceAfter - playerBalanceBefore, betAmount);
    }

    function test_withdrawBetGameNotOpen() public {
        closeGame(gameId);
        vm.expectRevert(IntelliCasinoBetting.GameNotOpen.selector);
        withdrawBet(gameId);
    }

    function test_withdrawBetDoesNotExist() public {
        vm.prank(player);
        vm.expectRevert(IntelliCasinoBetting.BetDoesNotExist.selector);
        withdrawBet(gameId);
    }

    function test_withdrawBetFailedTransfer() public {
        vm.prank(bettor);
        vm.deal(address(betting), betAmount - 1); // Deal less Ether than needed
        vm.expectRevert(IntelliCasinoBetting.TransferFailed.selector);
        withdrawBet(gameId);
    }
}

contract CloseGameTest is IntelliCasinoBettingTest {
    event GameClosed(uint256 indexed gameId);

    function setUp() public override {
        super.setUp();
        createGame(gameId);
    }

    function test_closeGame() public {
        vm.expectEmit(true, true, true, true);
        emit GameClosed(gameId);

        closeGame(gameId);

        (, IntelliCasinoBetting.GameState state,,,) = betting.games(gameId);
        assertEq(uint(state), uint(IntelliCasinoBetting.GameState.CLOSED));
    }

    function test_closeGameNotOpen() public {
        closeGame(gameId);
        vm.expectRevert(IntelliCasinoBetting.GameNotOpen.selector);
        closeGame(gameId);
    }

    function test_closeGameInvalidId() public {
        vm.expectRevert(IntelliCasinoBetting.InvalidGameId.selector);
        closeGame(99);
    }
}

// contract DistributeWinningsTest is IntelliCasinoBettingTest {
//     event WinningsDistributed(uint256 indexed gameId, uint256 totalWinnings, uint256 totalWinners);

//     function setUp() public override {
//         super.setUp();
//         createGame(gameId);
//         placeBet(gameId, true, player);
//         placeBet(gameId, false, casino);
//         closeGame(gameId);
//     }

//     function test_distributeWinnings() public {
//         vm.expectEmit(true, true, true, true);
//         emit WinningsDistributed(gameId, 0.97 ether, 1);

//         distributeWinnings(gameId, true);

//         (, IntelliCasinoBetting.GameState state,,,) = betting.games(gameId);
//         assertEq(uint(state), uint(IntelliCasinoBetting.GameState.FINISHED));
//     }

//     function test_distributeWinningsGameNotClosed() public {
//         createGame(2);
//         vm.expectRevert(IntelliCasinoBetting.GameNotClosed.selector);
//         distributeWinnings(2, true);
//     }

//     function test_distributeWinningsAlreadyFinished() public {
//         distributeWinnings(gameId, true);
//         vm.expectRevert(IntelliCasinoBetting.GameAlreadyFinished.selector);
//         distributeWinnings(gameId, true);
//     }

//     function test_distributeWinningsFailedTransfer() public {
//         vm.prank(address(3));
//         vm.deal(address(betting), 1 ether - 1); // Deal less Ether than needed
//         vm.expectRevert(IntelliCasinoBetting.TransferFailed.selector);
//         distributeWinnings(gameId, true);
//     }
// }