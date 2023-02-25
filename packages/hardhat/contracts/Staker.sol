// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExternalContract.sol";

contract Staker {

  ExternalContract public externalContract;

  mapping(address => uint256) public balances;
  mapping(address => uint256) public depositTimestamps;
  mapping(address => uint256) public withdrawLeft;
  mapping(address => uint256) public claimLeft;

  uint256 public constant rewardRatePerSecond = 0.0001 ether;
  uint256 public currentBlock = 0;

  // Events
  event Stake(address indexed sender, uint256 amount);
  event Received(address, uint);
  event Execute(address indexed sender, uint256 amount);

  constructor(address externalContractAddress) {
      externalContract = ExternalContract(externalContractAddress);
  }


  // Modifiers
  /*
  Checks if the withdrawal period has been reached or not
  */
  modifier isWithdrawPeriod() {
    require(withdrawPeriodLeft(msg.sender) == 0, "Withdrawal period is not reached yet");
    require(claimPeriodLeft(msg.sender) > 0, "Withdrawal period is over");
    _;
  }

  /*
  Checks if the claim period has ended or not
  */
  modifier isClaimPeriod() {
    require(claimPeriodLeft(msg.sender) == 0, "Claim period is not reached yet");
    _;
  }

  /*
  Requires that the contract only be completed once!
  */
  modifier notCompleted() {
    bool completed = externalContract.completed(msg.sender);
    require(!completed, "Stake already completed!");
    _;
  }

  /*
  Requires the contract to be completed
  */
  modifier completed() {
    bool completed = externalContract.completed(msg.sender);
    require(completed, "Stake is not completed!");
    _;
  }

  // Stake function for a user to stake ETH in our contract
  function stake() public payable notCompleted {
    balances[msg.sender] = balances[msg.sender] + msg.value;
    depositTimestamps[msg.sender] = block.timestamp;
    withdrawLeft[msg.sender] = block.timestamp + 30 seconds;
    claimLeft[msg.sender] = block.timestamp + 60 seconds;
    emit Stake(msg.sender, msg.value);
  }

  /*
  Withdraw function for a user to remove their staked ETH inclusive
  of both principal and any accrued interest
  */
  function withdraw() public isWithdrawPeriod notCompleted {
    require(balances[msg.sender] > 0, "You have no balance to withdraw!");
    uint256 individualBalance = balances[msg.sender];
    uint256 indBalanceRewards = individualBalance + ((block.timestamp-depositTimestamps[msg.sender])*rewardRatePerSecond);
    balances[msg.sender] = 0;

    // Transfer all ETH via call! (not transfer) cc: https://solidity-by-example.org/sending-ether
    (bool sent, bytes memory data) = msg.sender.call{value: indBalanceRewards}("");
    require(sent, "RIP; withdrawal failed :( ");
    depositTimestamps[msg.sender] = 0;
  }

  /*
  Allows any user to repatriate "unproductive" funds that are left in the staking contract
  past the defined withdrawal period
  */
  function execute() public isClaimPeriod notCompleted {
    externalContract.complete{value: address(this).balance}(msg.sender);
  }


    /*
  Allows any user to repatriate "unproductive" funds that are left in the staking contract
  past the defined withdrawal period
  */
  function rescue() public completed {
    externalContract.getBack(msg.sender);
  }

  /*
  READ-ONLY function to calculate the time remaining before the minimum staking period has passed
  */
  function withdrawPeriodLeft(address user) public view returns (uint256 withdrawPeriodLeft) {
    uint left = withdrawLeft[user];
    if( block.timestamp >= left) {
      return (0);
    } else {
      return (left - block.timestamp);
    }
  }

  /*
  READ-ONLY function to calculate the time remaining before the minimum staking period has passed
  */
  function claimPeriodLeft(address user) public view returns (uint256 claimPeriodLeft) {
    uint left = claimLeft[user];
    if( block.timestamp >= left) {
      return (0);
    } else {
      return (left - block.timestamp);
    }
  }

  /*
  Time to "kill-time" on our local testnet
  */
  function killTime() public {
    currentBlock = block.timestamp;
  }

  /*
  \Function for our smart contract to receive ETH
  cc: https://docs.soliditylang.org/en/latest/contracts.html#receive-ether-function
  */
  receive() external payable {
      emit Received(msg.sender, msg.value);
  }

}
