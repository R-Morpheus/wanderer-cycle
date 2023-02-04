// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { System } from "solecs/System.sol";
import { IWorld } from "solecs/interfaces/IWorld.sol";
import { getAddressById } from "solecs/utils.sol";

import {
  Action,
  ActionType,
  CombatSubsystem,
  ID as CombatSubsystemID
} from "../combat/CombatSubsystem.sol";

import { LibActiveCombat } from "../combat/LibActiveCombat.sol";
import { LibCycle } from "./LibCycle.sol";
import { LibCycleCombatRewardRequest } from "./LibCycleCombatRewardRequest.sol";

uint256 constant ID = uint256(keccak256("system.CycleCombat"));

contract CycleCombatSystem is System {
  constructor(IWorld _world, address _components) System(_world, _components) {}

  function executeTyped(
    uint256 wandererEntity,
    Action[] memory initiatorActions
  ) public returns (CombatSubsystem.CombatResult) {
    return abi.decode(
      execute(abi.encode(wandererEntity, initiatorActions)),
      (CombatSubsystem.CombatResult)
    );
  }

  function execute(bytes memory args) public override returns (bytes memory) {
    (
      uint256 wandererEntity,
      Action[] memory initiatorActions
    ) = abi.decode(args, (uint256, Action[]));
    // reverts if sender doesn't have permission
    uint256 cycleEntity = LibCycle.getCycleEntityPermissioned(components, wandererEntity);
    // reverts if combat isn't active
    uint256 retaliatorEntity = LibActiveCombat.getRetaliatorEntity(components, cycleEntity);

    // TODO other retaliator actions?
    Action[] memory retaliatorActions = new Action[](1);
    retaliatorActions[0] = Action({
      actionType: ActionType.ATTACK,
      actionEntity: 0
    });

    CombatSubsystem combatSubsystem = CombatSubsystem(getAddressById(world.systems(), CombatSubsystemID));
    CombatSubsystem.CombatResult result = combatSubsystem.executePVERound(
      cycleEntity,
      retaliatorEntity,
      initiatorActions,
      retaliatorActions
    );

    if (result == CombatSubsystem.CombatResult.VICTORY) {
      LibCycleCombatRewardRequest.requestReward(
        world,
        cycleEntity,
        retaliatorEntity
      );
    }

    return abi.encode(result);
  }
}