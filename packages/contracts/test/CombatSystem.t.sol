// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { IWorldErrors } from "@latticexyz/world/src/IWorldErrors.sol";
import { BaseTest } from "./BaseTest.t.sol";

import { ActiveCombat } from "../src/namespaces/combat/codegen/index.sol";
import { charstatSystem } from "../src/namespaces/charstat/codegen/systems/CharstatSystemLib.sol";
import { combatSystem } from "../src/namespaces/combat/codegen/systems/CombatSystemLib.sol";
import { CombatSystem, CombatAction, CombatActionType } from "../src/namespaces/combat/CombatSystem.sol";
import { LibActiveCombat } from "../src/namespaces/combat/LibActiveCombat.sol";
import { LibCharstat } from "../src/namespaces/charstat/LibCharstat.sol";
import { PStat, PStat_length, EleStat_length } from "../src/CustomTypes.sol";
import { StatmodTopics } from "../src/namespaces/statmod/StatmodTopic.sol";
import { Statmod } from "../src/namespaces/statmod/Statmod.sol";
import { EleStat, StatmodOp, CombatResult } from "../src/codegen/common.sol";

contract CombatSystemTest is BaseTest {
  address writer = address(bytes20(keccak256("writer")));
  address notWriter = address(bytes20(keccak256("notWriter")));
  bytes32 playerEntity = keccak256("playerEntity");
  bytes32 encounterEntity = keccak256("encounterEntity");

  CombatAction[] _noActions;

  // default data
  uint32 constant initLevel = 2;
  uint32 initLife;
  uint32 initAttack;
  uint32 defaultMaxRounds = 12;

  // statmod entities
  bytes32 levelStatmodEntity = StatmodTopics.LEVEL.toStatmodEntity(StatmodOp.BADD, EleStat.NONE);

  function setUp() public virtual override {
    super.setUp();

    // authorize writer
    _grantAccess("combat", writer);

    // give direct levels
    // (note: don't change statmods directly outside of tests, use effects)
    Statmod.increase(playerEntity, levelStatmodEntity, initLevel);
    Statmod.increase(encounterEntity, levelStatmodEntity, initLevel);

    // initialize and fill up life, mana
    charstatSystem.setFullCurrents(playerEntity);
    charstatSystem.setFullCurrents(encounterEntity);

    initLife = LibCharstat.getLifeCurrent(playerEntity);
    initAttack = LibCharstat.getAttack(playerEntity)[uint256(EleStat.PHYSICAL)];
  }

  // ================ HELPERS ================

  function _activateCombat(uint32 maxRounds) internal {
    // activate combat between player and encounter
    combatSystem.activateCombat(playerEntity, encounterEntity, maxRounds);
  }

  function _sumElements(uint32[EleStat_length] memory elemValues) internal pure returns (uint32 result) {
    // TODO elemental values could use their own library, or at least some helpers
    for (uint256 i = 1; i < EleStat_length; i++) {
      result += elemValues[i];
    }
  }

  function _actions1Attack() internal pure returns (CombatAction[] memory result) {
    result = new CombatAction[](1);
    result[0] = CombatAction({ actionType: CombatActionType.ATTACK, actionEntity: 0 });
  }

  function _actions2Attacks() internal pure returns (CombatAction[] memory result) {
    result = new CombatAction[](2);
    result[0] = CombatAction({ actionType: CombatActionType.ATTACK, actionEntity: 0 });
    result[1] = CombatAction({ actionType: CombatActionType.ATTACK, actionEntity: 0 });
  }

  // ================ TESTS ================

  // this just shows the values I expect, and may need to change if LibCharstat config changes
  function testSetUp() public {
    _activateCombat(defaultMaxRounds);

    assertEq(initLife, 2 + 2 * initLevel);
    assertEq(LibCharstat.getLifeCurrent(playerEntity), LibCharstat.getLifeCurrent(encounterEntity));

    assertEq(initAttack, 1 + initLevel / 2);
    assertEq(_sumElements(LibCharstat.getAttack(playerEntity)), initAttack);
    assertEq(_sumElements(LibCharstat.getAttack(playerEntity)), _sumElements(LibCharstat.getAttack(encounterEntity)));
  }

  function testCombatPVERoundRevertAccessDenied() public {
    _activateCombat(defaultMaxRounds);

    vm.prank(notWriter);
    vm.expectRevert(
      abi.encodeWithSelector(IWorldErrors.World_AccessDenied.selector, "sy:combat:CombatSystem", notWriter)
    );
    combatSystem.actPVERound(playerEntity, encounterEntity, _noActions, _noActions);
  }

  // skipping a round is fine
  function testCombatPVERoundNoActions() public {
    _activateCombat(defaultMaxRounds);

    vm.prank(writer);
    CombatResult result = combatSystem.actPVERound(playerEntity, encounterEntity, _noActions, _noActions);
    assertEq(uint8(result), uint8(CombatResult.NONE));
  }

  // by default entities can only do 1 action per round
  function testCombatPVERoundRevertInvalidActionsLength() public {
    _activateCombat(defaultMaxRounds);

    vm.prank(writer);
    vm.expectRevert(CombatSystem.CombatSystem_InvalidActionsLength.selector);
    combatSystem.actPVERound(playerEntity, encounterEntity, _actions2Attacks(), _actions2Attacks());
  }

  // an unopposed single attack
  function testCombatPVERoundPlayerAttacks1() public {
    _activateCombat(defaultMaxRounds);

    vm.prank(writer);

    CombatResult result = combatSystem.actPVERound(playerEntity, encounterEntity, _actions1Attack(), _noActions);
    assertEq(uint8(result), uint8(CombatResult.NONE));
    assertEq(LibCharstat.getLifeCurrent(encounterEntity), initLife - initAttack);
  }

  // unopposed player attacks, enough to get victory
  function testCombatPVERoundPlayerAttacksVictory() public {
    _activateCombat(defaultMaxRounds);

    vm.prank(writer);

    CombatResult result;
    // do enough attacks to defeat encounter
    uint256 attacksNumber = initLife / initAttack;
    for (uint256 i; i < attacksNumber; i++) {
      result = combatSystem.actPVERound(playerEntity, encounterEntity, _actions1Attack(), _noActions);
      if (i != attacksNumber - 1) {
        assertEq(uint8(result), uint8(CombatResult.NONE));
      }
    }
    assertEq(uint8(result), uint8(CombatResult.VICTORY));
    assertEq(LibCharstat.getLifeCurrent(encounterEntity), 0);
  }

  // unopposed encounter attacks, enough to get defeat
  function testCombatPVERoundEncounterAttacksDefeat() public {
    _activateCombat(defaultMaxRounds);

    vm.prank(writer);

    CombatResult result;
    // do enough attacks to defeat player
    uint256 attacksNumber = initLife / initAttack;
    for (uint256 i; i < attacksNumber; i++) {
      result = combatSystem.actPVERound(playerEntity, encounterEntity, _noActions, _actions1Attack());
      if (i != attacksNumber - 1) {
        assertEq(uint8(result), uint8(CombatResult.NONE));
      }
    }
    assertEq(uint8(result), uint8(CombatResult.DEFEAT));
    assertEq(LibCharstat.getLifeCurrent(playerEntity), 0);
  }

  // player and encounter have the same stats and attacks, but player goes 1st and wins the last round
  function testCombatPVERoundOpposedAttacksVictoryByInitiative() public {
    _activateCombat(defaultMaxRounds);

    vm.prank(writer);

    CombatResult result;
    // do enough attacks to defeat encounter
    uint256 attacksNumber = initLife / initAttack;
    for (uint256 i; i < attacksNumber; i++) {
      result = combatSystem.actPVERound(playerEntity, encounterEntity, _actions1Attack(), _actions1Attack());
      if (i != attacksNumber - 1) {
        assertEq(uint8(result), uint8(CombatResult.NONE));
      }
    }
    assertEq(uint8(result), uint8(CombatResult.VICTORY));
    // also check that the last encounter action didn't go through, since it lost
    assertEq(LibCharstat.getLifeCurrent(playerEntity), initLife - initAttack * (attacksNumber - 1));
    assertEq(LibCharstat.getLifeCurrent(encounterEntity), 0);
  }

  function testRoundDurationDecrease() public {
    _activateCombat(defaultMaxRounds);

    uint32 initialRoundsSpent = ActiveCombat.getRoundsSpent(playerEntity);

    vm.prank(writer);
    combatSystem.actPVERound(playerEntity, encounterEntity, _noActions, _noActions);

    uint32 roundsSpent = ActiveCombat.getRoundsSpent(playerEntity);
    assertEq(roundsSpent, initialRoundsSpent + 1, "Rounds spent should increase by 1");
  }

  function testCombatDeactivatesAfterMaxRounds() public {
    _activateCombat(1);

    vm.prank(writer);
    combatSystem.actPVERound(playerEntity, encounterEntity, _noActions, _noActions);

    bool isActive = ActiveCombat.getRetaliatorEntity(playerEntity) != bytes32(0);
    assertFalse(isActive, "Combat should be deactivated after max rounds");
  }

  function testInvalidActionsLength() public {
    _activateCombat(defaultMaxRounds);

    CombatAction[] memory actions = _actions2Attacks();

    vm.prank(writer);
    vm.expectRevert(CombatSystem.CombatSystem_InvalidActionsLength.selector);
    combatSystem.actPVERound(playerEntity, encounterEntity, actions, _noActions);
  }

  // TODO So far just basic physical attacks. More tests, with statmods and skills.
}
