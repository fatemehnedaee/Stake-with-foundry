// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "forge-std/console.sol";
import "forge-std/Test.sol";
import {MyStake} from "../src/MyStake.sol";
import {StakeToken} from "../src/token/StakeToken.sol";
import {RewardToken} from "../src/token/RewardToken.sol";
// import "openzeppelin-contracts/interfaces/IERC20.sol";
// import "openzeppelin-contracts/access/Ownable.sol";

contract MyStakeTest is Test {

    StakeToken public stakeToken;
    RewardToken public rewardToken;
    MyStake public myStake;

    function setUp() public {
        stakeToken = new StakeToken(address(this));
        rewardToken = new RewardToken(address(this));
        myStake = new MyStake(address(stakeToken), address(rewardToken), address(this));
    }
    
    function constractorTest() public {
        assertEq(myStake.stakeToken(), address(stakeToken));
        assertEq(myStake.rewardToken(), address(rewardToken));
    }

}