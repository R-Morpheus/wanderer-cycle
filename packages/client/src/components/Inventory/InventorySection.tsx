import InventoryEquipment from "./InventoryEquipment";
import { useOwnedEquipment } from "../../mud/hooks/useOwnedEquipment";

const InventorySection = ({ equipmentList }: { equipmentList: ReturnType<typeof useOwnedEquipment> }) => {
  return (
    <div className="flex justify-start flex-wrap">
      {equipmentList.map((equipmentData) => (
        <InventoryEquipment key={equipmentData.entity} equipmentData={equipmentData} />
      ))}
    </div>
  );
};

export default InventorySection;
