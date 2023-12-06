// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {MyStake} from "../src/MyStake.sol";
import {StakeToken} from "../src/token/StakeToken.sol";
import {RewardToken} from "../src/token/RewardToken.sol";

contract MyStakeTest is Test {

    uint public time;
    address user1;
    address user2;
    address user3;
    
    StakeToken public stakeToken;
    RewardToken public rewardToken;
    MyStake public myStake;

    event Deposit(address _user, uint _amount, uint _depositTime);
    event Withdraw(address _user, uint _amount, uint _withdrawTime);
    event Claim(address _user, uint reward);

    function setUp() public {
        time = block.timestamp;
        user1 = address(1);
        user2 = address(2);
        user3 = address(3);

        stakeToken = new StakeToken(address(this));
        stakeToken.mint(user1, 1000 ether);
        stakeToken.mint(user2, 20000 ether);
        stakeToken.mint(user3, 20000 ether);

        rewardToken = new RewardToken(address(this)); 

        myStake = new MyStake(IERC20(stakeToken), IERC20(rewardToken), address(this));
        rewardToken.mint(address(myStake), 2000000 ether);
    }

    function _setTotalRewardAndDuration() private {
        myStake.setTotalReward(2000000 ether);
        myStake.setDuration(2000000);
    }

    function _deposit(address _user,uint _amount, uint _time) private {
        vm.startPrank(_user);
        vm.warp(time + _time);
        stakeToken.approve(address(myStake), _amount);
        myStake.deposit(_amount);
        vm.stopPrank();
    }

    function _withdraw(address _user,uint _amount, uint _time) private {
        vm.startPrank(_user);
        vm.warp(time + _time);
        myStake.withdraw(_amount);
        vm.stopPrank();
    }
    
    function testConstractor() public {
        assertEq(address(myStake.stakeToken()), address(stakeToken));
        assertEq(address(myStake.rewardToken()), address(rewardToken));
    }

    function testSetTotalReward() public {
        myStake.setTotalReward(2000000 ether);
        assertEq(myStake.totalReward(), 2000000 ether);
    }

    function testSetDuration() public {
        myStake.setDuration(2000000);
        assertEq(myStake.duration(), 2000000);
    }

    function testDepositFail() public {
        vm.expectRevert(MyStake.InvalidAmount.selector);
        myStake.deposit(0);
    }

    function testDeposit() public {
        _setTotalRewardAndDuration();

        // test deposit function for first deposit
        vm.warp(time + 1000);
        vm.startPrank(user1);
        stakeToken.approve(address(myStake), 1000 ether);
        vm.expectEmit(true, false, false, true);
        emit Deposit(user1, 1000 ether, time +1000);
        myStake.deposit(1000 ether);
        vm.stopPrank();

        assertEq(stakeToken.balanceOf(address(myStake)), 1000 ether);
        assertEq(myStake.deposits(user1), 1000 ether);
        assertEq(myStake.totalSupply(), 1000 ether);

        // test reward function for first deposit
        assertEq(myStake.rewardPerToken(), 0);
        assertEq(myStake.rewards(user1), 0 ether);
        assertEq(myStake.userRewardPerTokenPaid(user1), 0);
        assertEq(myStake.lastUpdateTime(), time + 1000);

        // test deposit function for second deposit
        vm.warp(time + 50000);
        vm.startPrank(user2);
        stakeToken.approve(address(myStake), 20000 ether);
        vm.expectEmit(true, false, false, true);
        emit Deposit(user2, 20000 ether, time + 50000);
        myStake.deposit(20000 ether);
        vm.stopPrank();

        assertEq(stakeToken.balanceOf(address(myStake)), 21000 ether);
        assertEq(myStake.deposits(user2), 20000 ether);
        assertEq(myStake.totalSupply(), 21000 ether);

        // test reward function for second deposit
        assertEq(myStake.rewardPerToken(), 49);
        assertEq(myStake.rewards(user2), 0 ether);
        assertEq(myStake.userRewardPerTokenPaid(user2), 49);
        assertEq(myStake.lastUpdateTime(), time + 50000);

        // test deposit function for third deposit
        vm.warp(time + 70000);
        vm.startPrank(user3);
        stakeToken.approve(address(myStake), 10000 ether);
        vm.expectEmit(true, false, false, true);
        emit Deposit(user3, 10000 ether, time + 70000);
        myStake.deposit(10000 ether);
        vm.stopPrank();

        assertEq(stakeToken.balanceOf(address(myStake)), 31000 ether);
        assertEq(myStake.deposits(user3), 10000 ether);
        assertEq(myStake.totalSupply(), 31000 ether);

        // test reward function for third deposit
        assertEq(myStake.rewardPerToken(), 49);
        assertEq(myStake.rewards(user3), 0 ether);
        assertEq(myStake.userRewardPerTokenPaid(user3), 49);
        assertEq(myStake.lastUpdateTime(), time + 70000);
    }

    function testWithdrawFail() public {
        vm.expectRevert(MyStake.InvalidAmount.selector);
        vm.prank(user1);
        myStake.withdraw(2000);
    }

    function testWithdraw() public {
        _setTotalRewardAndDuration();
        _deposit(user1, 1000 ether , 1000);
        _deposit(user2, 20000 ether, 50000);
        _deposit(user3, 10000 ether, 70000);

        // test withdraw function for first withdraw
        vm.warp(time + 100000);
        vm.startPrank(user1);
        vm.expectEmit(true, false, false, true);
        emit Withdraw(user1, 1000 ether, time +100000);
        myStake.withdraw(1000 ether);
        vm.stopPrank();

        assertEq(stakeToken.balanceOf(address(myStake)), 30000 ether);
        assertEq(stakeToken.balanceOf(user1), 1000 ether);
        assertEq(myStake.deposits(user1), 0 ether);
        assertEq(myStake.totalSupply(), 30000 ether);
        assertEq(myStake.userRewardPerTokenPaid(user1), 0);

        // test reward function for first withdraw
        assertEq(myStake.rewardPerToken(), 49);
        assertEq(myStake.rewards(user1), 49000 ether);
        assertEq(myStake.lastUpdateTime(), time + 100000);

        // again deposit
        // test deposit function for fourth deposit
        vm.warp(time + 500000);
        vm.startPrank(user3);
        stakeToken.approve(address(myStake), 10000 ether);
        vm.expectEmit(true, false, false, true);
        emit Deposit(user3, 10000 ether, time + 500000);
        myStake.deposit(10000 ether);
        vm.stopPrank();

        assertEq(stakeToken.balanceOf(address(myStake)), 40000 ether);
        assertEq(myStake.deposits(user3), 20000 ether);
        assertEq(myStake.totalSupply(), 40000 ether);

        // test reward function for fourth deposit
        assertEq(myStake.rewardPerToken(), 62);
        assertEq(myStake.rewards(user3), 130000 ether);
        assertEq(myStake.userRewardPerTokenPaid(user3), 62);
        assertEq(myStake.lastUpdateTime(), time + 500000);

        // test withdraw function for second withdraw
        vm.warp(time + 1000000);
        vm.startPrank(user2);
        vm.expectEmit(true, false, false, true);
        emit Withdraw(user2, 20000 ether, time +1000000);
        myStake.withdraw(20000 ether);
        vm.stopPrank();

        assertEq(stakeToken.balanceOf(address(myStake)), 20000 ether);
        assertEq(stakeToken.balanceOf(user2), 20000 ether);
        assertEq(myStake.deposits(user2), 0 ether);
        assertEq(myStake.totalSupply(), 20000 ether);
        assertEq(myStake.userRewardPerTokenPaid(user2), 0);

        // test reward function for second withdraw
        assertEq(myStake.rewardPerToken(), 74);
        assertEq(myStake.rewards(user2), 500000 ether);
        assertEq(myStake.lastUpdateTime(), time + 1000000);

        // test withdraw function for third withdraw
        vm.warp(time + 1500000);
        vm.startPrank(user3);
        vm.expectEmit(true, false, false, true);
        emit Withdraw(user3, 20000 ether, time + 1500000);
        myStake.withdraw(20000 ether);
        vm.stopPrank();

        assertEq(stakeToken.balanceOf(address(myStake)), 0 ether);
        assertEq(stakeToken.balanceOf(user3), 20000 ether);
        assertEq(myStake.deposits(user3), 0 ether);
        assertEq(myStake.totalSupply(), 0 ether);
        assertEq(myStake.userRewardPerTokenPaid(user3), 0);

        // test reward function for third withdraw
        assertEq(myStake.rewardPerToken(), 99);
        assertEq(myStake.rewards(user3), 870000 ether);
        assertEq(myStake.lastUpdateTime(), time + 1500000);
    }

    function testClaim() public {
        _setTotalRewardAndDuration();
        _deposit(user1, 1000 ether , 1000);
        _deposit(user2, 20000 ether, 50000);
        _deposit(user3, 10000 ether, 70000);
        _withdraw(user1, 1000, 100000);
        rewardToken.approve(user1, 49000 ether);
        emit Claim(user1, 49000 ether);
        vm.prank(user1);
        myStake.claim();
        assertEq(rewardToken.balanceOf(user1), 49000 ether);
        assertEq(myStake.rewards(user1), 0);
    }

}