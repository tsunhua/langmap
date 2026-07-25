export interface Edge { id: string; a: number; b: number; }

export function edgesForGroup(memberIds: number[]): Edge[] {
  const ids = [...new Set(memberIds)].sort((x, y) => x - y);
  const out: Edge[] = [];
  for (let i = 0; i < ids.length; i++) {
    for (let j = i + 1; j < ids.length; j++) {
      const a = ids[i], b = ids[j];
      out.push({ id: `${a}-${b}`, a, b });
    }
  }
  return out;
}
