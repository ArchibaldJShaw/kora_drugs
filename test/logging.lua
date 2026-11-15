-- Run from kora_drugs: lua test/logging.lua
-- Migrated diagnostics: a schema warning and the repeated-cooldown error must reach Kora.logging
-- with the expected level, a stable event name, static message and details in fields.
local logged = {}
Kora = { sql = {
    NULL = '\0kora_sql:null\0',
    ready = function() return true end,
    ensureTables = function() return { { table = 'kora_drugs', warnings = { 'collation differs' } } } end,
}, logging = {} }
for _, level in ipairs({ 'trace', 'debug', 'info', 'warn', 'error', 'fatal' }) do
    Kora.logging[level] = function(event, message, fields) logged[#logged + 1] = { level = level, event = event, message = message, fields = fields }; return true end
end
GetCurrentResourceName = function() return 'kora_drugs' end
AddEventHandler = function() end
local dropped
SetTimeout = function() end
DropPlayer = function(src) dropped = src end
local realPrint, raw = print, 0
print = function() raw = raw + 1 end

dofile('server/schema.lua')
dofile('server/_functions.lua')

local function last(event) for i = #logged, 1, -1 do if logged[i].event == event then return logged[i] end end end

local w = last('schema.warning')
assert(w and w.level == 'warn', 'schema warning logged at warn')
assert(w.fields.table == 'kora_drugs' and w.fields.warning == 'collation differs', 'warning details ride in fields')
assert(not w.message:find('collation', 1, true), 'message stays static')

-- startCooldown/onCooldown: drive the cooldown until the 5th block.
startCooldown(7, 'craft', 60000)
for _ = 1, 5 do onCooldown(7, 'craft') end
local e = last('cooldown.repeated_abuse')
assert(e and e.level == 'error' and e.fields.cooldown == 'craft', 'repeated cooldown abuse logged at error')
assert(dropped == 7, 'behaviour unchanged: the player is still dropped')
print = realPrint
assert(raw == 0, 'no raw print')
print('kora_drugs logging: migrated diagnostics emit the expected logger calls')
