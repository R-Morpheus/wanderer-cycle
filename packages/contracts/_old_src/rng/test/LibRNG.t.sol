// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { IUint256Component } from "solecs/interfaces/IUint256Component.sol";

import { BaseTest } from "../../BaseTest.sol";

import { LibRNG } from "../LibRNG.sol";

contract GetRandomnessRevertHelper {
  function getRandomness(IUint256Component components, uint256 requestOwner, uint256 requestId) public view {
    LibRNG.getRandomness(components, requestOwner, requestId);
  }
}

contract LibRNGTest is BaseTest {
  GetRandomnessRevertHelper revertHelper;
  uint256 internal constant requestOwner = 123;

  function setUp() public virtual override {
    super.setUp();

    revertHelper = new GetRandomnessRevertHelper();
  }

  function test_getRandomness() public {
    uint256 requestId = LibRNG.requestRandomness(world, requestOwner);
    vm.roll(block.number + LibRNG.WAIT_BLOCKS + 1);
    uint256 randomness = LibRNG.getRandomness(components, requestOwner, requestId);
    assertGt(randomness, 0);
    assertEq(LibRNG.getRequestOwner(components, requestId), requestOwner);
  }

  function test_getRandomness_revert_NotRequestOwner() public {
    uint256 requestId = LibRNG.requestRandomness(world, requestOwner);
    uint256 notOwner = 987;

    vm.expectRevert(LibRNG.LibRNG__NotRequestOwner.selector);
    revertHelper.getRandomness(components, notOwner, requestId);
  }

  function test_getRandomness_revert_sameBlock() public {
    uint256 requestId = LibRNG.requestRandomness(world, requestOwner);

    vm.expectRevert(LibRNG.LibRNG__InvalidPrecommit.selector);
    revertHelper.getRandomness(components, requestOwner, requestId);
  }

  /* TODO not relevant while WAIT_BLOCKS = 0
  function test_getRandomness_revert_tooEarly() public {
    uint256 requestId = LibRNG.requestRandomness(world, '');

    vm.roll(block.number + 1);
    vm.expectRevert(LibRNG.LibRNG__InvalidPrecommit.selector);
    revertHelper.getRandomness(components, requestId);
  }*/

  function test_getRandomness_revert_tooLate() public {
    uint256 requestId = LibRNG.requestRandomness(world, requestOwner);

    vm.roll(block.number + LibRNG.WAIT_BLOCKS + 256 + 1);
    vm.expectRevert(LibRNG.LibRNG__InvalidPrecommit.selector);
    revertHelper.getRandomness(components, requestOwner, requestId);
  }

  // basic test for different base blocknumbers
  function test_requestRandomness_blocknumbers(uint32 blocknumber) public {
    vm.assume(blocknumber != 0);
    vm.roll(blocknumber);
    uint256 requestId = LibRNG.requestRandomness(world, requestOwner);

    uint256 precommit = LibRNG.getPrecommit(components, requestId);
    assertEq(precommit, blocknumber + LibRNG.WAIT_BLOCKS);
    assertEq(LibRNG.getRequestOwner(components, requestId), requestOwner);

    uint256 newBlocknumber = uint256(blocknumber) + 10;
    vm.roll(newBlocknumber);
    precommit = LibRNG.getPrecommit(components, requestId);
    assertLt(precommit, newBlocknumber);
    assertEq(LibRNG.getRequestOwner(components, requestId), requestOwner);
    assertTrue(LibRNG.isValid(precommit));
  }

  // thorough validity test for the possible offsets
  function test_requestRandomness_validity() public {
    uint256 initBlock = 1;
    vm.roll(initBlock);

    uint256 requestId = LibRNG.requestRandomness(world, requestOwner);
    uint256 precommit = LibRNG.getPrecommit(components, requestId);

    for (uint256 i = initBlock; i < initBlock + 270; i++) {
      vm.roll(i);
      if (i <= initBlock + LibRNG.WAIT_BLOCKS) {
        assertFalse(LibRNG.isValid(precommit));
        assertEq(uint256(blockhash(precommit)), 0);
      } else if (i <= initBlock + LibRNG.WAIT_BLOCKS + 256) {
        assertTrue(LibRNG.isValid(precommit));
        assertFalse(LibRNG.isOverBlockLimit(precommit));
        assertNotEq(uint256(blockhash(precommit)), 0);
      } else {
        assertFalse(LibRNG.isValid(precommit));
        assertTrue(LibRNG.isOverBlockLimit(precommit));
        assertEq(uint256(blockhash(precommit)), 0);
      }
    }
  }
}
