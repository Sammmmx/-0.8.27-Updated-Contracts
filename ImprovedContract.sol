// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GasHog {

    uint256 public totalSupply;
    address public owner;
    bool public paused;

    address[] public stakers;
    mapping(address => uint256) public balances;

    uint256 Count;

    constructor() {
        owner = msg.sender;
        totalSupply = 1000000;
        paused = false;                     //bool variables are False by default. No constructor needed for paused.
    }

    modifier checkOwner() {
        require(msg.sender == owner);       //Instead of checking for owner in multiple functions, you can put one modifier that checks for each function.
        _;
    }

    function addStaker(address staker) public checkOwner() {        //checkOwner Modifier
        stakers.push(staker);
    }

    function isStaker(address user) public view returns (bool) {
        for (uint256 i = 0; i < stakers.length; i++) {
            if (stakers[i] == user) return true;
        }
        return false;
    }

    function distributeRewards(uint256 amount) public checkOwner() {      //checkOwner Modifier
        require(!paused);
        for (uint256 i = 0; i < stakers.length; i++) {
            balances[stakers[i]] += amount;
        }
    }

    function getBalance(address user) public view returns (uint256) {
        return balances[user];
    }

    function updateOwner(address newOwner) public checkOwner() {           //checkOwner Modifier
        owner = newOwner;
    }
}