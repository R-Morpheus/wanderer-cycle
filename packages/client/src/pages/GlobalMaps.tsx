import Map from "../components/Map";
import { useMaps } from "../mud/hooks/useMaps";

const GlobalMaps = () => {
  const mapEntities = useMaps("Global Basic");

  return (
    <div className="flex justify-around flex-wrap">
      {mapEntities.map((entity) => (
        <Map key={entity} entity={entity} />
      ))}
    </div>
  );
};

export default GlobalMaps;
