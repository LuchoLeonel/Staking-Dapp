// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading

contract ExternalContract {
  address public owner;
  mapping(address => bool) public completed;
  mapping(address => bool) public rescued;

  modifier onlyOwner() {
    require(msg.sender == owner, "Not the owner of the contract");
    _;
  }

  modifier noCompleted(address player) {
    require(!completed[player], "The contract is already completed");
    _;
  }

  modifier noRescued(address player) {
    require(!rescued[player], "The contract is already rescued");
    _;
  }

  function setOwner(address _owner) public {
    require(owner == address(0), "Owner already set");
    owner = _owner;
  }

  function complete(address player) public payable onlyOwner noCompleted(player) {
    completed[player] = true;
    rescued[player] = false;
  }

  function getBack(address player) public onlyOwner noRescued(player) {
    (bool success,) = owner.call{value: address(this).balance}("");
    require(success, "fail to get back money locked");
    completed[player] = false;
    rescued[player] = true;
  }

}
