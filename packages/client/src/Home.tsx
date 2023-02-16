import { useMUD } from "./mud/MUDContext";
import { useWandererContext } from "./contexts/WandererContext";
import WandererSelect from "./pages/WandererSelect";
import CycleInfo from "./components/info/CycleInfo";
import CombatPage from "./pages/CombatPage";

export const Home = () => {
  // const {components: { /*ActiveGuise, GuisePrototype, LoadingState*/ }, playerEntity,} = useMUD();
  const { selectedWandererEntity, enemyEntity } = useWandererContext();

  return (
    <div>
      {selectedWandererEntity === undefined ? <WandererSelect /> : enemyEntity ? <CombatPage /> : <CycleInfo />}
    </div>
  );
};
