// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

/**
 * @title ICycleEquipmentSystem
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 */
interface ICycleEquipmentSystem {
  error CycleEquipmentSystem_NotSlotOwner(bytes32 targetEntity, bytes32 slotEntity);
  error CycleEquipmentSystem_NotEquipmentOwner(bytes32 targetEntity, bytes32 equipmentEntity);

  function cycle__equip(bytes32 cycleEntity, bytes32 slotEntity, bytes32 equipmentEntity) external;

  function cycle__unequip(bytes32 cycleEntity, bytes32 slotEntity) external;
}
