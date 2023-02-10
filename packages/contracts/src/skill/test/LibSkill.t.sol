// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { BaseTest } from "../../BaseTest.sol";

import { IUint256Component } from "solecs/interfaces/IUint256Component.sol";

import { ScopedDuration } from "../../duration/DurationSubSystem.sol";
import { getSkillProtoEntity } from "../SkillPrototypeComponent.sol";
import { getEffectEntity } from "../../effect/EffectSubSystem.sol";

import { LibSkill } from "../LibSkill.sol";
import { LibLearnedSkills } from "../LibLearnedSkills.sol";
import { LibCharstat, Element } from "../../charstat/LibCharstat.sol";
import { LibExperience, PStat, PS_L } from "../../charstat/LibExperience.sol";

// can't expectRevert internal calls, so this is an external wrapper
contract LibSkillRevertHelper {
  using LibSkill for LibSkill.Self;

  function useSkill(LibSkill.Self memory libSkill, uint256 targetEntity) public {
    libSkill.useSkill(targetEntity);
  }
}

contract LibSkillTest is BaseTest {
  using LibSkill for LibSkill.Self;
  using LibLearnedSkills for LibLearnedSkills.Self;
  using LibCharstat for LibCharstat.Self;

  // helpers
  LibSkillRevertHelper revertHelper;

  // libs
  LibCharstat.Self charstat;
  LibLearnedSkills.Self learnedSkills;

  uint256 userEntity = uint256(keccak256("userEntity"));
  uint256 otherEntity = uint256(keccak256("otherEntity"));

  // sample skill entities
  uint256 cleavePE = getSkillProtoEntity("Cleave");
  uint256 chargePE = getSkillProtoEntity("Charge");
  uint256 parryPE = getSkillProtoEntity("Parry");
  uint256 someInvalidSkillPE = getSkillProtoEntity("someInvalidSkill");

  function setUp() public virtual override {
    super.setUp();

    IUint256Component components = world.components();
    // init helpers and libs
    revertHelper = new LibSkillRevertHelper();
    charstat = LibCharstat.__construct(components, userEntity);
    learnedSkills = LibLearnedSkills.__construct(components, userEntity);

    // learn sample skills
    learnedSkills.learnSkill(cleavePE);
    learnedSkills.learnSkill(chargePE);
    learnedSkills.learnSkill(parryPE);

    // give user some mana
    charstat.setManaCurrent(4);
    // allow user to receive experience
    LibExperience.initExp(charstat.exp);
  }

  function _libSkill(uint256 skillEntity) internal view returns (LibSkill.Self memory) {
    return LibSkill.__construct(world, userEntity, skillEntity);
  }

  function test_setUp() public {
    assertTrue(learnedSkills.hasSkill(cleavePE));
    assertTrue(learnedSkills.hasSkill(chargePE));
    assertTrue(learnedSkills.hasSkill(parryPE));

    assertEq(charstat.getMana(), 4);
  }

  function test_hasSkill_invalidSkill() public {
    assertFalse(learnedSkills.hasSkill(someInvalidSkillPE));
  }

  function test_useSkill_invalidTarget() public {
    // user is the only valid target for charge
    LibSkill.Self memory libSkill = _libSkill(chargePE);
    vm.expectRevert(LibSkill.LibSkill__InvalidSkillTarget.selector);
    revertHelper.useSkill(libSkill, otherEntity);
  }

  // TODO mana stuff isn't very skill-related?
  function test_setManaCurrent_capped() public {
    charstat.setManaCurrent(100);
    assertEq(charstat.getMana(), 4);
  }

  function test_useSkill_Charge() public {
    _libSkill(chargePE).useSkill(userEntity);

    assertEq(charstat.getManaCurrent(), 4 - 1, "Invalid mana remainder");
    assertTrue(durationSubSystem.has(userEntity, chargePE), "No ongoing cooldown");

    assertTrue(effectSubSystem.has(userEntity, chargePE), "No ongoing effect");
  }

  function test_useSkill_Cleave_effect() public {
    _libSkill(cleavePE).useSkill(userEntity);
    assertEq(charstat.getAttack()[uint256(Element.PHYSICAL)], 3);
  }

  // str and the 2 skills should all modify physical attack,
  // test that it all stacks correctly
  function test_useSkill_CleaveAndCharge_strengthStacking() public {
    // add exp to get 2 str (which should increase base physical attack to 2)
    uint32[PS_L] memory addExp;
    addExp[uint256(PStat.STRENGTH)] = LibExperience.getExpForPStat(2);
    LibExperience.increaseExp(charstat.exp, addExp);

    // 16%, +2
    LibSkill.Self memory libSkill = _libSkill(cleavePE);
    libSkill.useSkill(userEntity);
    // 64%
    libSkill.switchSkill(chargePE);
    libSkill.useSkill(userEntity);
    // 2 * 1.8 + 2
    assertEq(charstat.getAttack()[uint256(Element.PHYSICAL)], 5);
  }

  // this tests durations, especially DurationSubSystem's effect removal callback
  // TODO a lot of this can be removed if effects get their own tests,
  // atm the many assertions help tell apart bugs in effectSubSystem and durationSubSystem
  function test_useSkill_CleaveAndCharge_onDurationEnd() public {
    // add exp to get 2 str (which should increase base physical attack to 2)
    uint32[PS_L] memory addExp;
    addExp[uint256(PStat.STRENGTH)] = LibExperience.getExpForPStat(2);
    LibExperience.increaseExp(charstat.exp, addExp);

    assertEq(charstat.getAttack()[uint256(Element.PHYSICAL)], 2);

    LibSkill.Self memory libSkill = _libSkill(cleavePE);
    libSkill.useSkill(userEntity);
    libSkill = libSkill.switchSkill(chargePE);
    libSkill.useSkill(userEntity);

    assertTrue(durationSubSystem.has(userEntity, getEffectEntity(userEntity, cleavePE)));
    assertTrue(durationSubSystem.has(userEntity, getEffectEntity(userEntity, chargePE)));
    assertEq(charstat.getAttack()[uint256(Element.PHYSICAL)], 5);

    // decrease cleave duration and cooldown
    durationSubSystem.executeDecreaseScope(
      userEntity,
      ScopedDuration({ timeScopeId: uint256(keccak256("round")), timeValue: 1 })
    );

    // cooldown
    assertFalse(durationSubSystem.has(userEntity, cleavePE));
    // effect
    assertFalse(durationSubSystem.has(userEntity, getEffectEntity(userEntity, cleavePE)));
    assertTrue(durationSubSystem.has(userEntity, getEffectEntity(userEntity, chargePE)));
    assertEq(charstat.getAttack()[uint256(Element.PHYSICAL)], 3);

    // decrease charge duration
    durationSubSystem.executeDecreaseScope(
      userEntity,
      ScopedDuration({ timeScopeId: uint256(keccak256("round_persistent")), timeValue: 1 })
    );

    assertFalse(durationSubSystem.has(userEntity, getEffectEntity(userEntity, cleavePE)));
    assertFalse(durationSubSystem.has(userEntity, getEffectEntity(userEntity, chargePE)));
    assertEq(charstat.getAttack()[uint256(Element.PHYSICAL)], 2);
  }
}
