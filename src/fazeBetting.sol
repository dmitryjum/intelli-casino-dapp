// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./ownable.sol";
import "./ATM.sol";

contract IntelliCasinoBetting is ATM, Ownable {

    event NewBet(
        address addy, 
        uint amount, 
        Team teamBet
    );

    struct Bet {
        uint256 gameId;
        string name;
        address addy;
        uint amount;
        Team teamBet;
    }

    struct Team {
        string name;
        uint totalBetAmount;
    }

    Bet[] public bets;
    Team[] public teams;
    
    address payable conOwner;
    uint public totalBetMoney = 0;

    mapping (address => uint) public numBetsAddress;


    constructor() payable {
        conOwner = payable(msg.sender);
        teams.push(Team("team1", 0));
        teams.push(Team("team2", 0));

    }

    function createTeam (string memory _name) public {
        teams.push(Team(_name, 0));
    }

    function getTotalBetAmount (uint _teamId) public view returns (uint) {
        return teams[_teamId].totalBetAmount;
    }
    
    function createBet (string memory _name, uint _teamId) external payable {       
        require (msg.sender != conOwner, "owner can't make a bet");
        require (numBetsAddress[msg.sender] == 0, "you have already placed a bet");
        require (msg.value > 0.01 ether, "bet more");

        deposit();

        bets.push(Bet(_name, msg.sender, msg.value, teams[_teamId]));

        if (_teamId == 0) {
            teams[0].totalBetAmount += msg.value;
        } 
        if (_teamId == 1) {
            teams[1].totalBetAmount += msg.value;
        }

        numBetsAddress[msg.sender]++;
        
        (bool sent, bytes memory data) = conOwner.call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        totalBetMoney += msg.value;

        emit NewBet(msg.sender, msg.value, teams[_teamId]);

    }

    function teamWinDistribution(uint _teamId) public payable onlyOwner() {
        
        deposit();
        uint div;
                
        if (_teamId == 0) {
            for (uint i = 0; i < bets.length; i++) {
                if (keccak256(abi.encodePacked((bets[i].teamBet.name))) == keccak256(abi.encodePacked("team1"))) {
                    address payable receiver = payable(bets[i].addy);
                    div = (bets[i].amount * (10000 + (getTotalBetAmount(1) * 10000 / getTotalBetAmount(0)))) / 10000;
                    // div = bets[i].amount + (bets[i].amount / getTotalBetAmount(0) * getTotalBetAmount(1));

                    (bool sent, bytes memory data) = receiver.call{ value: div }("");
                    require(sent, "Failed to send Ether");
                    
                }
            }
        } else {
            for (uint i = 0; i < bets.length; i++) {
                if (keccak256(abi.encodePacked((bets[i].teamBet.name))) == keccak256(abi.encodePacked("team2"))) {
                    address payable receiver = payable(bets[i].addy);
                    div = (bets[i].amount * (10000 + (getTotalBetAmount(0) * 10000 / getTotalBetAmount(1)))) / 10000;

                    (bool sent, bytes memory data) = receiver.call{ value: div }("");
                    require(sent, "Failed to send Ether");
                }
            }
        }

        totalBetMoney = 0;
        teams[0].totalBetAmount = 0;
        teams[1].totalBetAmount = 0;

        for (uint i = 0; i < bets.length; i++) {
            numBetsAddress[bets[i].addy] = 0;
        }

    }

}