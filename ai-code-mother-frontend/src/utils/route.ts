export function parseRouteParamId(param: string | string[] | undefined): string | undefined {
  const raw = Array.isArray(param) ? param[0] : param
  if (!raw || !/^\d+$/.test(raw)) {
    return undefined
  }
  return raw
}
