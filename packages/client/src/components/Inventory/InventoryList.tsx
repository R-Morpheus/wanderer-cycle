import { equipmentPrototypes } from "../../mud/utils/equipment";
import InventorySection from "./InventorySection";
import InventoryHeader from "./InventoryHeader";
import InventoryFilter from "./InventoryFilter";
import { useInventoryContext } from "../../contexts/InventoryContext";

const InventoryList = () => {
  const { equipmentList, presentProtoEntityIds, filter } = useInventoryContext();

  const separator = <hr className="h-px my-2 bg-dark-400 border-0" />;
  return (
    <div className="w-[60%] flex flex-col ">
      <div className="flex justify-start w-full m-2">
        <div className="text-2xl text-dark-comment">{"// inventory"}</div>
        <InventoryFilter />
      </div>

      <div className="flex flex-col justify-center items-center">
        {presentProtoEntityIds.map((_protoEntityId) => (
          <div key={_protoEntityId} className="w-full">
            <div
              key={_protoEntityId}
              className={
                !filter ? "flex flex-col justify-start w-full flex-wrap" : "flex flex-col justify-center flex-wrap"
              }
            >
              <div className="w-1/3">
                <InventoryHeader>{equipmentPrototypes[_protoEntityId]}</InventoryHeader>
              </div>
              <div className="w-auto">
                <InventorySection
                  equipmentList={equipmentList.filter(({ protoEntityId }) => protoEntityId === _protoEntityId)}
                />
              </div>
            </div>
            {separator}
          </div>
        ))}
      </div>
    </div>
  );
};

export default InventoryList;
