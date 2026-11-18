// Minimal stubs for PocketBase JS migration/hook tooling.
declare const migrate: (
  up: (app: any) => void,
  down: (app: any) => void,
) => void;
declare const onRecordCreateRequest: (
  handler: (e: any) => void,
  ...collections: string[]
) => void;
declare const onRecordUpdateRequest: (
  handler: (e: any) => void,
  ...collections: string[]
) => void;
declare class Collection {
  constructor(config: Record<string, unknown>);
}
declare class BadRequestError {
  constructor(message: string);
}
declare class ConflictError {
  constructor(message: string, record?: unknown);
}
declare const $app: any;
