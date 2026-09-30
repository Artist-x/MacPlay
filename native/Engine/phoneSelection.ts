export function acceptsPhone(target: string | undefined, incoming: string, occupied: boolean): boolean {
  const normalize = (value: string) => value.replace(/-/g, ':').toLowerCase()
  return !occupied && (!target || normalize(target) === normalize(incoming))
}
