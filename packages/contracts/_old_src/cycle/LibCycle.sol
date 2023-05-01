// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { IWorld } from "solecs/interfaces/IWorld.sol";
import { IUint256Component } from "solecs/interfaces/IUint256Component.sol";
import { getAddressById } from "solecs/utils.sol";

import { ActiveCycleComponent, ID as ActiveCycleComponentID } from "./ActiveCycleComponent.sol";
import { ActiveCyclePreviousComponent, ID as ActiveCyclePreviousComponentID } from "./ActiveCyclePreviousComponent.sol";
import { ActiveGuiseComponent, ID as ActiveGuiseComponentID } from "../guise/ActiveGuiseComponent.sol";
import { CycleToWandererComponent, ID as CycleToWandererComponentID } from "./CycleToWandererComponent.sol";
import { GuisePrototypeComponent, ID as GuisePrototypeComponentID } from "../guise/GuisePrototypeComponent.sol";
import { ActiveWheelComponent, ID as ActiveWheelComponentID } from "../wheel/ActiveWheelComponent.sol";
import { WheelComponent, ID as WheelComponentID } from "../wheel/WheelComponent.sol";

import { LibCharstat } from "../charstat/LibCharstat.sol";
import { LibExperience } from "../charstat/LibExperience.sol";
import { LibCycleTurns } from "./LibCycleTurns.sol";
import { LibToken } from "../token/LibToken.sol";
import { LibSpawnEquipmentSlots } from "../equipment/LibSpawnEquipmentSlots.sol";
import { LibLearnedSkills } from "../skill/LibLearnedSkills.sol";

// TODO imports for testing stuff, remove later
import { RandomEquipmentSubSystem, ID as RandomEquipmentSubSystemID } from "../loot/RandomEquipmentSubSystem.sol";
import { LibLootOwner } from "../loot/LibLootOwner.sol";

library LibCycle {
  using LibCharstat for LibCharstat.Self;
  using LibExperience for LibExperience.Self;
  using LibLearnedSkills for LibLearnedSkills.Self;

  error LibCycle__CycleIsAlreadyActive();
  error LibCycle__CycleNotActive();
  error LibCycle__InvalidGuiseProtoEntity();
  error LibCycle__InvalidWheelEntity();

  function initCycle(
    IWorld world,
    uint256 targetEntity,
    uint256 guiseProtoEntity,
    uint256 wheelEntity
  ) internal returns (uint256 cycleEntity) {
    // cycleEntity is for all the in-cycle components (everything except activeCycle)
    cycleEntity = world.getUniqueEntityId();

    IUint256Component components = world.components();
    ActiveCycleComponent activeCycleComp = ActiveCycleComponent(getAddressById(components, ActiveCycleComponentID));
    ActiveGuiseComponent activeGuiseComp = ActiveGuiseComponent(getAddressById(components, ActiveGuiseComponentID));
    CycleToWandererComponent cycleToWandererComp = CycleToWandererComponent(
      getAddressById(components, CycleToWandererComponentID)
    );
    ActiveWheelComponent activeWheelComp = ActiveWheelComponent(getAddressById(components, ActiveWheelComponentID));
    LibCharstat.Self memory charstat = LibCharstat.__construct(components, cycleEntity);

    // cycle must be inactive
    if (activeCycleComp.has(targetEntity)) {
      revert LibCycle__CycleIsAlreadyActive();
    }
    // prototypes must exist
    if (!GuisePrototypeComponent(getAddressById(components, GuisePrototypeComponentID)).has(guiseProtoEntity)) {
      revert LibCycle__InvalidGuiseProtoEntity();
    }
    if (!WheelComponent(getAddressById(components, WheelComponentID)).has(wheelEntity)) {
      revert LibCycle__InvalidWheelEntity();
    }

    // TODO check wheel requirements

    // set active cycle
    activeCycleComp.set(targetEntity, cycleEntity);
    cycleToWandererComp.set(cycleEntity, targetEntity);
    // set active guise
    activeGuiseComp.set(cycleEntity, guiseProtoEntity);
    // set active wheel
    activeWheelComp.set(cycleEntity, wheelEntity);
    // init exp
    charstat.exp.initExp();
    // init currents
    charstat.setFullCurrents();
    // claim initial cycle turns
    LibCycleTurns.claimTurns(components, cycleEntity);
    // spawn equipment slots
    LibSpawnEquipmentSlots.spawnEquipmentSlots(world, cycleEntity);
    // copy permanent skills
    LibLearnedSkills.__construct(world, cycleEntity).copySkills(targetEntity);

    // TODO loot for testing, remove later
    {
      RandomEquipmentSubSystem randomEquipmentSubSystem = RandomEquipmentSubSystem(
        getAddressById(world.systems(), RandomEquipmentSubSystemID)
      );
      uint256 lootEntity;
      for (uint256 i; i < 20; i++) {
        lootEntity = randomEquipmentSubSystem.executeTyped(uint32((i % 12) + 1), i + 123123);
        LibLootOwner.setSimpleOwnership(components, lootEntity, cycleEntity);
      }
    }

    return cycleEntity;
  }

  function endCycle(IUint256Component components, uint256 wandererEntity, uint256 cycleEntity) internal {
    // save the previous cycle entity
    ActiveCyclePreviousComponent activeCyclePreviousComp = ActiveCyclePreviousComponent(
      getAddressById(components, ActiveCyclePreviousComponentID)
    );
    activeCyclePreviousComp.set(wandererEntity, cycleEntity);
    // clear the current cycle
    ActiveCycleComponent activeCycleComp = ActiveCycleComponent(getAddressById(components, ActiveCycleComponentID));
    CycleToWandererComponent cycleToWandererComp = CycleToWandererComponent(
      getAddressById(components, CycleToWandererComponentID)
    );
    activeCycleComp.remove(wandererEntity);
    cycleToWandererComp.remove(cycleEntity);
  }

  /// @dev Return `cycleEntity` if msg.sender is allowed to use it.
  /// Revert otherwise.
  ///
  /// Note on why getCycleEntity and a permission check are 1 method:
  /// Cycle systems take `wandererEntity` as the argument to simplify checking permissions,
  /// and then convert it to `cycleEntity`. If you don't need permission checks,
  /// you probably shouldn't need this method either, and should know cycle entities directly.
  function getCycleEntityPermissioned(
    IUint256Component components,
    uint256 wandererEntity
  ) internal view returns (uint256 cycleEntity) {
    // check permission
    LibToken.requireOwner(components, wandererEntity, msg.sender);
    // get cycle entity
    ActiveCycleComponent activeCycleComp = ActiveCycleComponent(getAddressById(components, ActiveCycleComponentID));
    if (!activeCycleComp.has(wandererEntity)) revert LibCycle__CycleNotActive();
    return activeCycleComp.getValue(wandererEntity);
  }

  function requirePermission(IUint256Component components, uint256 cycleEntity) internal view {
    // get wanderer entity
    CycleToWandererComponent cycleToWandererComp = CycleToWandererComponent(
      getAddressById(components, CycleToWandererComponentID)
    );
    uint256 wandererEntity = cycleToWandererComp.getValue(cycleEntity);
    // check permission
    LibToken.requireOwner(components, wandererEntity, msg.sender);
  }
}
