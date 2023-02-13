import { useWandererContext } from "../../../contexts/WandererContext";
import CycleInfoContent from "./CycleInfoContent";

export default function CycleInfo() {
  const { cycleEntity } = useWandererContext();
  console.log("cycleEntity", cycleEntity);

  // TODO display some placeholder if this is even possible to reach
  if (!cycleEntity) {
    return <></>;
  }

  return <CycleInfoContent cycleEntity={cycleEntity} />;
}
