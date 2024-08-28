// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
// import "forge-std/console.sol";
import {IntelliCasinoBetting} from "../src/IntelliCasinoBetting.sol";

contract IntelliCasinoBettingTest is Test {
    IntelliCasinoBetting public casino;
    // uint256 campaignId = 1;
    // address owner = address(this);
    // uint256 goal = 3 ether;
    // uint256 duration = 5 days;
    // uint256 deadline = block.timestamp + duration;
    // address contributor = address(1);
    // uint256 contributeAmount = 1 ether;

    function setUp() public virtual {
        casino = new IntelliCasinoBetting();
    }

    function createGame() internal {
        
    }

    function placeBet() internal {
        
    }

    function withdrawBet() internal {
        
    }

    receive() external payable {}
}

// contract CreateCampaignTest is SecureCrowdfundingTest {
//     event CampaignCreated(uint256 indexed campaignId, address owner, uint256 goal, uint256 deadline);

//     function setUp() public override {
//         super.setUp();
//     }

//     function test_createCampaign() public {
//         vm.expectEmit(true, true, true, true);
//         emit CampaignCreated(campaignId, owner, goal, deadline);

//         createCampaign(goal, duration);
//         (address _owner, uint256 _goal, uint256 _deadline, uint256 _fundsRaised, bool _claimed) =
//             crowdFund.campaigns(campaignId);
//         assertEq(_goal, goal);
//         assertEq(_deadline, deadline);
//         assertEq(_owner, owner);
//         assertFalse(_claimed);
//         assertEq(_fundsRaised, 0);
//     }

//     function test_invalidGoal() public {
//         vm.expectRevert(SecureCrowdfunding.InvalidGoal.selector);
//         createCampaign(0, duration);
//     }
// }

// contract ContributeCompaignTest is SecureCrowdfundingTest {
//     event ContributionMade(uint256 indexed campaignId, address contributor, uint256 amount);

//     function setUp() public override {
//         super.setUp();
//         createCampaign(goal, duration);
//     }

//     function test_contribute() public {
//         vm.expectEmit(true, true, true, true);
//         hoax(contributor, goal);
//         emit ContributionMade(campaignId, contributor, contributeAmount);

//         contribute(campaignId, contributeAmount);
//         (address _owner, uint256 _goal, uint256 _deadline, uint256 _fundsRaised, bool _claimed) =
//             crowdFund.campaigns(campaignId);
        
//         assertEq(_goal, goal);
//         assertEq(_deadline, deadline);
//         assertEq(_owner, owner);
//         assertFalse(_claimed);
//         assertEq(_fundsRaised, contributeAmount);
//     }

//     function test_contributeCampaignEnded() public {
//         hoax(contributor, contributeAmount);
//         vm.warp(deadline);
//         vm.expectRevert(SecureCrowdfunding.CampaignEnded.selector);
//         contribute(campaignId, contributeAmount);
//     }

//     function test_contributeInvalidContribution() public {
//         hoax(contributor, contributeAmount);
//         vm.expectRevert(SecureCrowdfunding.InvalidContribution.selector);
//         contribute(campaignId, 0);
//     }

//     function test_compaignDoesNotExist() public {
//         hoax(contributor, contributeAmount);
//         vm.expectRevert(SecureCrowdfunding.InvalidCampaignId.selector);
//         contribute(type(uint256).max, contributeAmount);
//     }
// }

// contract ClaimFundsTest is SecureCrowdfundingTest {
//     event FundsClaimed(uint256 indexed campaignId, uint256 amount);

//     function setUp() public override {
//         super.setUp();
//         createCampaign(goal, duration);
//     }

//     function test_claimFunds() public {
//         hoax(contributor, goal);
//         contribute(campaignId, goal);

//         vm.warp(deadline);
//         vm.expectEmit(true, true, true, true);
//         emit FundsClaimed(campaignId, goal);

//         claimFunds(campaignId);
//         (,,,, bool _claimed) = crowdFund.campaigns(campaignId);
//         assertEq(_claimed, true);
//     }

//     function test_CampaignNotEnded() public {
//         hoax(contributor, goal);
//         contribute(campaignId, goal);

//         vm.expectRevert(SecureCrowdfunding.CampaignNotEnded.selector);
//         claimFunds(campaignId);
//     }

//     function test_InvalidCampaignId() public {
//         hoax(contributor, goal);
//         contribute(campaignId, goal);

//         vm.expectRevert(SecureCrowdfunding.InvalidCampaignId.selector);
//         claimFunds(3);
//     }

//     function test_GoalNotReached() public {
//         hoax(contributor, contributeAmount);
//         contribute(campaignId, contributeAmount);
//         vm.warp(deadline);

//         vm.expectRevert(SecureCrowdfunding.GoalNotReached.selector);
//         claimFunds(campaignId);
//     }

//     function test_FundsAlreadyClaimed() public {
//         hoax(contributor, goal);
//         contribute(campaignId, goal);

//         vm.warp(deadline);

//         claimFunds(campaignId);
//         vm.expectRevert(SecureCrowdfunding.FundsAlreadyClaimed.selector);
//         claimFunds(campaignId);
//     }

//     function test_NotCampaignOwner() public {
//         hoax(contributor, goal);
//         contribute(campaignId, goal);
//         vm.warp(deadline);
//         vm.prank(contributor);

//         vm.expectRevert(SecureCrowdfunding.NotOwnerOfCampaign.selector);
//         claimFunds(campaignId);
//     }

//     function test_TransferFailed() public {
//         deal(contributor, goal);
//         hoax(contributor);
//         contribute(campaignId, goal);

//         // Warp to after the campaign deadline
//         vm.warp(block.timestamp + duration + 1);

//         // Ensure the contract has insufficient balance
//         deal(address(crowdFund), goal - 1);  // Deal less Ether than needed

//         // Prank as the owner to claim funds
//         vm.prank(owner);
//         vm.expectRevert(SecureCrowdfunding.TransferFailed.selector);
//         crowdFund.claimFunds(campaignId);
//     }
// }

// contract WithdrawContributionTest is SecureCrowdfundingTest {
//     function setUp() public override {
//         super.setUp();
//         createCampaign(goal, duration);
//     }

//     function test_withdrawContributionTest() public {
//         hoax(contributor, contributeAmount);
//         contribute(campaignId, contributeAmount);
//         uint256 contributorBalanceBeforeRefund = contributor.balance;
//         (,,, uint256 _fundsRaisedBeforeWithdrawal,) = crowdFund.campaigns(campaignId);
//         vm.warp(deadline);
//         vm.prank(contributor);
//         withdrawContribution(campaignId);
//         uint256 contributorBalanceAfterRefund = contributor.balance;
//         (,,, uint256 _fundsRaisedAfterWithdrawal,) = crowdFund.campaigns(campaignId);
//         assertEq(_fundsRaisedAfterWithdrawal, _fundsRaisedBeforeWithdrawal - contributeAmount);
//         assertEq(contributorBalanceBeforeRefund, 0);
//         assertEq(contributorBalanceAfterRefund, contributeAmount);

//     }

//     function test_campaignNotEnded() public {
//         vm.expectRevert(SecureCrowdfunding.CampaignNotEnded.selector);
//         withdrawContribution(campaignId);
//     }

//     function test_GoalReached() public {
//         hoax(contributor, goal);
//         contribute(campaignId, goal);
//         vm.warp(deadline);
//         vm.expectRevert(SecureCrowdfunding.GoalReached.selector);
//         withdrawContribution(campaignId);
//     }

//     function test_InvalidCampaignId() public {
//         vm.warp(deadline);
//         vm.expectRevert(SecureCrowdfunding.InvalidCampaignId.selector);
//         withdrawContribution(4);
//     }

//     function test_TransferFailed() public {
//         // deal(contributor, contributeAmount);
//         hoax(contributor, contributeAmount);
//         contribute(campaignId, contributeAmount);

//         // Warp to after the campaign deadline
//         vm.warp(block.timestamp + duration + 1);

//         // Ensure the contract has insufficient balance
//         deal(address(crowdFund), contributeAmount - 1);  // Deal less Ether than needed

//         // Prank as the owner to claim funds
//         vm.expectRevert(SecureCrowdfunding.TransferFailed.selector);
//         vm.prank(contributor);
//         withdrawContribution(campaignId);
//     }

//     function test_NoContributionMade() public {
//         hoax(address(4));
//         vm.warp(deadline);
//         vm.expectRevert(SecureCrowdfunding.NoContributionMade.selector);
//         withdrawContribution(campaignId);
//     }
// }
