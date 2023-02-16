import Map from "../components/Map";
import { useMaps } from "../mud/hooks/useMaps";
import { useWandererContext } from "../contexts/WandererContext";
import WandererSelect from "./WandererSelect";
import CombatPage from "./CombatPage";

const GlobalMaps = () => {
  const mapEntities = useMaps("Global Basic");
  const { selectedWandererEntity, enemyEntity } = useWandererContext();

  return (
    <>
      <div className="relative">
        {selectedWandererEntity === undefined ? (
          <WandererSelect />
        ) : enemyEntity === undefined ? (
          <div className="flex justify-around flex-wrap">
            {mapEntities.map((entity) => (
              <Map key={entity} entity={entity} />
            ))}
          </div>
        ) : (
          <CombatPage />
        )}
      </div>
    </>
  );
};

export default GlobalMaps;
