import { useWandererContext } from "../contexts/WandererContext";
import WandererSelect from "./WandererSelect";
import CombatPage from "./CombatPage";
import Inventory from "../components/Inventory ";

const InventoryPage = () => {
  const { selectedWandererEntity, enemyEntity } = useWandererContext();

  // TODO maybe move this check higher up the tree, so it's not repeated in every page
  return (
    <div>
      {selectedWandererEntity === undefined ? <WandererSelect /> : enemyEntity ? <CombatPage /> : <Inventory />}
    </div>
  );
};

export default InventoryPage;
