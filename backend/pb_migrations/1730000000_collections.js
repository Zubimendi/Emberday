/// <reference path="../types.d.ts" />

migrate((app) => {
  const habits = new Collection({
    name: "habits",
    type: "base",
    listRule: "@request.auth.id != '' && owner = @request.auth.id",
    viewRule: "@request.auth.id != '' && owner = @request.auth.id",
    createRule: "@request.auth.id != '' && @request.body.owner = @request.auth.id",
    updateRule: "@request.auth.id != '' && owner = @request.auth.id && @request.body.owner:isset = false",
    deleteRule: null,
    fields: [
      { name: "owner", type: "relation", required: true, collectionId: "_pb_users_auth_", maxSelect: 1 },
      { name: "name", type: "text", required: true, max: 60 },
      { name: "icon", type: "text", required: true },
      { name: "color_key", type: "text", required: true },
      { name: "schedule_type", type: "text", required: true },
      { name: "weekdays_mask", type: "number", required: true },
      { name: "weekly_target", type: "number", required: true },
      { name: "start_date", type: "text", required: true },
      { name: "reminder_enabled", type: "bool" },
      { name: "reminder_minutes", type: "number" },
      { name: "reminder_weekdays_mask", type: "number" },
      { name: "sort_order", type: "number" },
      { name: "archived_at", type: "number" },
      { name: "client_updated_at", type: "number", required: true },
      { name: "deleted_at", type: "number" },
    ],
  });
  app.save(habits);

  const checkIns = new Collection({
    name: "check_ins",
    type: "base",
    listRule: "@request.auth.id != '' && owner = @request.auth.id",
    viewRule: "@request.auth.id != '' && owner = @request.auth.id",
    createRule: "@request.auth.id != '' && @request.body.owner = @request.auth.id",
    updateRule: "@request.auth.id != '' && owner = @request.auth.id && @request.body.owner:isset = false",
    deleteRule: null,
    fields: [
      { name: "owner", type: "relation", required: true, collectionId: "_pb_users_auth_", maxSelect: 1 },
      { name: "habit", type: "text", required: true },
      { name: "local_date", type: "text", required: true },
      { name: "status", type: "text", required: true },
      { name: "note", type: "text", max: 280 },
      { name: "client_updated_at", type: "number", required: true },
      { name: "deleted_at", type: "number" },
    ],
    indexes: [
      "CREATE UNIQUE INDEX idx_checkins_owner_habit_date ON check_ins (owner, habit, local_date)",
    ],
  });
  app.save(checkIns);
}, (app) => {
  const checkIns = app.findCollectionByNameOrId("check_ins");
  if (checkIns) app.delete(checkIns);
  const habits = app.findCollectionByNameOrId("habits");
  if (habits) app.delete(habits);
});
