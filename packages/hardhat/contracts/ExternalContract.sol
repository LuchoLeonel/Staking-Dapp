// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading

contract ExternalContract {
  bool public completed;
  address public owner;

  modifier onlyOwner() {
    require(msg.sender == owner, "Not the owner of the contract");
    _;
  }

  function setOwner(address _owner) public {
    require(owner == address(0), "Owner already set");
    owner = _owner;
  }

  function complete() public payable {
    completed = true;
  }

  function getBack() public onlyOwner {
    (bool success,) = owner.call{value: address(this).balance}("");
    require(success, "fail to get back money locked");
    completed = false;
  }

}
