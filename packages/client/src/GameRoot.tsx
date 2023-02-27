import { useWandererContext } from "./contexts/WandererContext";
import WandererSelect from "./pages/WandererSelect";
import CycleInfo from "./components/info/CycleInfo";
import { Outlet } from "react-router-dom";
import CombatPage from "./pages/CombatPage";

export function GameRoot() {
  const { selectedWandererEntity, enemyEntity } = useWandererContext();

  if (selectedWandererEntity === undefined) {
    return <WandererSelect />;
  }

  if (enemyEntity !== undefined) {
    return (
      <div className="flex">
        <CycleInfo />
        <CombatPage />
      </div>
    );
  }

  return (
    <div className="flex">
      <CycleInfo />
      <Outlet />
    </div>
  );
}
