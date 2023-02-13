import { useCallback } from "react";
import { useWandererContext } from "../../contexts/WandererContext";
import { useDurationValue } from "../../mud/hooks/useDurationValue";
import { AppliedEffect, EffectRemovability } from "../../mud/hooks/useEffectPrototype";
import { EffectModifier } from "./EffectStatmod";
import EffectNameItem from "./EffectNameItem";
import EffectNameSkill from "./EffectNameSkill";
import CustomButton from "../UI/CustomButton/CustomButton";
import { useGuise } from "../../mud/hooks/useGuise";
import { useGuiseEntities } from "../../mud/hooks/useGuiseEntities";

export default function Effect({
  entity,
  protoEntity = "item",
  removability,
  statmods,
  isItem = true,
  isSkill = true,
}: any) {
  const { cycleEntity } = useWandererContext();
  const durationValue = true;
  const skill = useGuise(useGuiseEntities()[0]).skillEntities[0];
  console.log("duration", durationValue);

  const removeEffect = useCallback(() => {
    console.log("TODO add removeEffect callback");
  }, []);

  return (
    <div className="p-1 bg-dark-600 border border-dark-400">
      <div className="overflow-hidden text-ellipsis whitespace-nowrap">
        {protoEntity && isItem && <EffectNameItem entity={protoEntity} />}
        {protoEntity && isSkill && <EffectNameSkill entity={skill} />}
      </div>

      {statmods &&
        statmods.map(({ protoEntity, value }) => (
          <EffectModifier key={protoEntity} protoEntity={protoEntity} value={value} />
        ))}

      {!!durationValue && (
        <div className="text-sm">
          ({/* TODO timeScopeId name map */}
          <span className="text-dark-key"> placeholder</span>
          <span className="text-dark-number">{durationValue}</span>)
        </div>
      )}

      {/* TODO replace with a working button */}
      {removability === EffectRemovability.BUFF && (
        <CustomButton onClick={() => removeEffect()}>{"remove"}</CustomButton>
      )}
    </div>
  );
}
