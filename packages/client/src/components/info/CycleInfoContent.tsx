import { useMemo } from "react";
import BaseInfo from "./BaseInfo";
import PassTurnButton from "./infoButton/PassTurnButton";
import ClaimTurnsButton from "./infoButton/ClaimTurnsButton";
import { EntityIndex } from "@latticexyz/recs";
import { useActiveGuise } from "../../mud/hooks/useActiveGuise";
import { useExperience } from "../../mud/hooks/useExperience";
import { expToLevel, pstatNames } from "../../mud/utils/experience";
import { useCycleTurns } from "../../mud/hooks/useCycleTurns";
import { useLifeCurrent } from "../../mud/hooks/useLifeCurrent";
import { useManaCurrent } from "../../mud/hooks/useManaCurrent";

export default function CycleInfoContent({ cycleEntity }: { cycleEntity: EntityIndex }) {
  const guise = useActiveGuise(cycleEntity);
  const experience = useExperience(cycleEntity);
  const turns = useCycleTurns(cycleEntity);
  const lifeCurrent = useLifeCurrent(cycleEntity);
  const manaCurrent = useManaCurrent(cycleEntity);
  console.log(guise, experience, turns, lifeCurrent, manaCurrent);
  const levelProps = useMemo(() => {
    // TODO add total exp data
    const exp = 10;
    const level = 1;

    return {
      name: "level",
      props: { exp, level },
    };
  }, []);

  const statProps = useMemo(() => {
    return pstatNames.map((name) => {
      let exp, level, buffedLevel;
      if (experience) {
        (exp = experience[name]), (level = expToLevel(exp));
        // TODO add statmods data
        buffedLevel = level;
      }
      return {
        name,
        props: { exp, level, buffedLevel },
      };
    });
  }, [experience]);

  const turnsHtml = (
    <>
      <div className="flex">
        <div className="text-dark-key">turns:</div>
        <div className="text-dark-number">{turns}</div>
      </div>

      {/*<PassTurnButton />*/}
      {/*<ClaimTurnsButton />*/}
    </>
  );

  return (
    <BaseInfo
      name={guise?.name}
      locationName={null}
      levelProps={levelProps}
      statProps={statProps}
      lifeCurrent={lifeCurrent}
      manaCurrent={manaCurrent}
      turnsHtml={turnsHtml}
    />
  );
}
