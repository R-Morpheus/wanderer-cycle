import { useState } from "react";
import { AppliedEffect } from "../../mud/hooks/useEffectPrototype";
import Effect from "../Effect";
import { useGuise } from "../../mud/hooks/useGuise";
import { useGuiseEntities } from "../../mud/hooks/useGuiseEntities";

interface EffectListSectionProps {
  sourceName: string;
  effects: AppliedEffect[] | undefined;
  initCollapsed: boolean;
}

export default function EffectListSection({ sourceName, effects, initCollapsed }: EffectListSectionProps) {
  const [collapsed, setCollapsed] = useState(initCollapsed);
  const skill = useGuise(useGuiseEntities()[0]).skillEntities[0];

  return (
    <div className="col-span-3 space-y-2">
      <h5 className="cursor-pointer" onClick={() => setCollapsed((collapsed) => !collapsed)}>
        <span className="text-dark-comment ml-2 mr-1">{`// source:${sourceName}`}</span>
        {collapsed ? ">" : "v"}
      </h5>

      {!collapsed && effects?.map((effect) => <Effect key={effect} {...effect} skill={skill} />)}
    </div>
  );
}
