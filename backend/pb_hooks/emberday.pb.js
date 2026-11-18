/// <reference path="../types.d.ts" />

onRecordCreateRequest((e) => {
  const name = e.record.get("name");
  if (typeof name === "string" && name.length > 60) {
    throw new BadRequestError("name too long");
  }
  const note = e.record.get("note");
  if (typeof note === "string" && note.length > 280) {
    throw new BadRequestError("note too long");
  }
  const localDate = e.record.get("local_date");
  if (typeof localDate === "string" && !/^\d{4}-\d{2}-\d{2}$/.test(localDate)) {
    throw new BadRequestError("invalid local_date");
  }
  e.next();
}, "habits", "check_ins");

onRecordUpdateRequest((e) => {
  const clientUpdated = Number(e.record.get("client_updated_at") || 0);
  const now = Date.now();
  if (clientUpdated > now + 5 * 60 * 1000) {
    e.record.set("client_updated_at", now);
  }
  try {
    const existing = $app.findRecordById(e.record.collection().id, e.record.id);
    const stored = Number(existing.get("client_updated_at") || 0);
    if (clientUpdated < stored) {
      throw new ConflictError("stale_write", existing);
    }
  } catch (err) {
    if (err instanceof ConflictError) throw err;
  }
  e.next();
}, "habits", "check_ins");
