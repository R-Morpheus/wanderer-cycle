// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { Uint256Component } from "std-contracts/components/Uint256Component.sol";

uint256 constant ID = uint256(keccak256("component.ActiveWheel"));

contract ActiveWheelComponent is Uint256Component {
  constructor(address world) Uint256Component(world, ID) {}
}
