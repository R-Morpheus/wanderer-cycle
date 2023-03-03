import { LootData } from "../../mud/utils/getLoot";
import { EffectStatmod } from "../Effect/EffectStatmod";
import CustomButton from "../UI/Button/CustomButton";

type BaseEquipmentProps = {
  equipmentData: LootData;
  button?: boolean;
  className?: string;
};

export default function BaseEquipment({ equipmentData, button, className }: BaseEquipmentProps) {
  const { name, ilvl, affixes } = equipmentData;
  return (
    <div className="text-dark-key p-1.5 flex flex-col justify-between border border-dark-400 w-64 m-2">
      <div className={className}>
        <div className="flex items-start justify-between">
          <div className="text-lg text-dark-method flex box-border items-start">
            <span>{name}</span>
          </div>
          <span className="text-dark-key ml-1">
            ilvl:<span className="ml-1 text-dark-number">{ilvl}</span>
          </span>
        </div>
        {affixes.map(({ protoEntity, value, partId, statmod }) => (
          <div className="flex box-content flex-wrap" key={`${partId}${protoEntity}`}>
            <EffectStatmod protoEntity={statmod.protoEntity} value={value} />
            {/* TODO add global button to trigger this data: */}
            {/*{affixPrototype.tier} {affixPrototype.name}
          ({affixPrototype.min}-{affixPrototype.max})*/}
          </div>
        ))}
      </div>
      {button && (
        <div className="flex justify-around mt-1">
          {equipmentData.availableSlots.map((slotData) => (
            <CustomButton
              key={slotData.entity}
              style={{ width: "80px", fontSize: "12px", padding: "5px", border: "none", marginTop: "5px" }}
              onClick={() => slotData.equip()}
            >
              equip
              {equipmentData.availableSlots.length > 1 && <span className="text-dark-string"> {slotData.name}</span>}
            </CustomButton>
          ))}
        </div>
      )}
    </div>
  );
}
