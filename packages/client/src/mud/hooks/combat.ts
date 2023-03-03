import { useComponentValue, useEntityQuery } from "@latticexyz/react";
import { EntityID, EntityIndex, getComponentValue, getComponentValueStrict, Has, HasValue } from "@latticexyz/recs";
import { BigNumber } from "ethers";
import { defaultAbiCoder } from "ethers/lib/utils";
import { useCallback, useEffect, useMemo } from "react";
import { useMUD } from "../MUDContext";
import { CombatAction } from "../utils/combat";
import { parsePStats, pstatNames } from "../utils/experience";

export const useActiveCombat = (entity: EntityIndex | undefined) => {
  const mud = useMUD();
  const {
    world,
    components: { ActiveCombat },
  } = mud;

  const activeCombat = useComponentValue(ActiveCombat, entity);
  const enemyEntity = useMemo(() => {
    const enemyEntityId = activeCombat?.value;
    if (!enemyEntityId) return;
    return world.entityToIndex.get(enemyEntityId);
  }, [world, activeCombat]);

  return enemyEntity;
};

export const useActivateCycleCombat = () => {
  const { world, systems } = useMUD();

  return useCallback(
    async (wandererEntity: EntityIndex, mapEntity: EntityIndex) => {
      const tx = await systems["system.CycleActivateCombat"].executeTyped(
        world.entities[wandererEntity],
        world.entities[mapEntity]
      );
      await tx.wait();
    },
    [world, systems]
  );
};

export const useExecuteCycleCombatRound = () => {
  const { world, systems } = useMUD();

  return useCallback(
    async (wandererEntity: EntityIndex, actions: CombatAction[]) => {
      const tx = await systems["system.CycleCombat"].executeTyped(world.entities[wandererEntity], actions);
      await tx.wait();
    },
    [world, systems]
  );
};

export const useClaimCycleCombatReward = () => {
  const { world, systems } = useMUD();

  return useCallback(
    async (wandererEntity: EntityIndex, requestEntity: EntityIndex) => {
      const tx = await systems["system.CycleCombatReward"].executeTyped(
        world.entities[wandererEntity],
        world.entities[requestEntity]
      );
      await tx.wait();
    },
    [world, systems]
  );
};

export const useCancelCycleCombatReward = () => {
  const { world, systems } = useMUD();

  return useCallback(
    async (wandererEntity: EntityIndex, requestEntity: EntityIndex) => {
      const tx = await systems["system.CycleCombatReward"].cancelRequest(
        world.entities[wandererEntity],
        world.entities[requestEntity]
      );
      await tx.wait();
    },
    [world, systems]
  );
};

export type CycleCombatRewardRequest = ReturnType<typeof useCycleCombatRewardRequests>[number];

export const useCycleCombatRewardRequests = (requesterEntity: EntityIndex | undefined) => {
  const mud = useMUD();
  const {
    world,
    components: { CycleCombatRewardRequest, RNGPrecommit },
  } = mud;

  const requesterEntityId = useMemo(() => {
    if (!requesterEntity) return;
    return world.entities[requesterEntity];
  }, [world, requesterEntity]);
  const requestEntities = useEntityQuery([
    HasValue(CycleCombatRewardRequest, { value: requesterEntityId }),
    Has(RNGPrecommit),
  ]);

  return useMemo(() => {
    return requestEntities.map((requestEntity) => {
      const rngPrecommit = getComponentValueStrict(RNGPrecommit, requestEntity);
      // TODO this is so bad, use a normal table for this in v2
      const [struct] = defaultAbiCoder.decode(
        [`(uint256, uint32, uint32, uint32[${pstatNames.length}], uint32[${pstatNames.length}])`],
        rngPrecommit.data
      );

      const [mapEntityBigNumber, connection, fortune, winnerPStats, loserPStats] = struct as [
        BigNumber,
        number,
        number,
        [number, number, number],
        [number, number, number]
      ];

      const mapEntityId = mapEntityBigNumber.toHexString() as EntityID;
      const mapEntity = world.entityToIndex.get(mapEntityId);
      if (mapEntity === undefined) throw new Error(`No index for map entity id ${mapEntityId}`);

      return {
        requestEntity,
        blocknumber: rngPrecommit.blocknumber,
        mapEntity,
        mapEntityId: mapEntityId,
        connection: connection,
        fortune: fortune,
        winnerPStats: parsePStats(winnerPStats[0], winnerPStats[1], winnerPStats[2]),
        loserPStats: parsePStats(loserPStats[0], loserPStats[1], loserPStats[2]),
      };
    });
  }, [world, RNGPrecommit, requestEntities]);
};

export enum CombatResult {
  NONE,
  VICTORY,
  DEFEAT,
}

export interface OnCombatResultData {
  initiatorActions: CombatAction[];
  combatResult: CombatResult;
  enemyEntity: EntityIndex | undefined;
}

/**
 * Calls the callback after each CycleCombat system call with combat results as arguments
 */
export function useOnCombatResultEffect(
  // TODO using cycleEntity here instead of system's args is a crutch
  // (But then this whole thing should be replaced with action events)
  initiatorEntity: EntityIndex | undefined,
  callback: (combatData: OnCombatResultData) => void
) {
  const {
    world,
    systemCallStreams,
    components: { ActiveCombat, LifeCurrent },
  } = useMUD();

  useEffect(() => {
    const subscription = systemCallStreams["system.CycleCombat"].subscribe((systemCall) => {
      if (initiatorEntity === undefined) return;
      const { initiatorActions } = systemCall.args as { wandererEntity: EntityID; initiatorActions: CombatAction[] };

      const enemyEntityId = getComponentValue(ActiveCombat, initiatorEntity)?.value;
      const enemyEntity = enemyEntityId ? world.entityToIndex.get(enemyEntityId) : undefined;

      // TODO this is also a crutch
      let combatResult;
      if (enemyEntity !== undefined) {
        combatResult = CombatResult.NONE;
      } else {
        const lifeCurrent = getComponentValueStrict(LifeCurrent, initiatorEntity).value;
        combatResult = lifeCurrent === 0 ? CombatResult.DEFEAT : CombatResult.VICTORY;
      }

      callback({ initiatorActions, combatResult, enemyEntity });
    });
    return () => subscription.unsubscribe();
  }, [world, ActiveCombat, LifeCurrent, systemCallStreams, callback, initiatorEntity]);
}
