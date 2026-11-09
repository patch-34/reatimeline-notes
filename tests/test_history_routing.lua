-- Independent history routing tests. Run from repository root with Lua 5.4.
local M=assert(loadfile('ReaTimeline_Notes.lua'))('__test')
assert(M.history_route('markers',false,true,true)=='project')
assert(M.history_route('markers',false,true,false)==nil)
assert(M.history_route('notes',false,true,true)=='notes')
assert(M.history_route('notes',false,false,true)==nil)
assert(M.history_route('markers',true,true,true)==nil)
assert(M.history_route('notes',true,true,true)==nil)
local project={}
local calls={undo=0,redo=0}
local entries={'Change marker lane','Rename ruler lane'}
local redos={}
local api={}
function api.Undo_CanUndo2(p)
  assert(p==project)
  return entries[#entries]
end
function api.Undo_CanRedo2(p)
  assert(p==project)
  return redos[#redos]
end
function api.Undo_DoUndo2(p)
  assert(p==project)
  if #entries==0 then return 0 end
  redos[#redos+1]=table.remove(entries)
  calls.undo=calls.undo+1
  return 1
end
function api.Undo_DoRedo2(p)
  assert(p==project)
  if #redos==0 then return 0 end
  entries[#entries+1]=table.remove(redos)
  calls.redo=calls.redo+1
  return 1
end
local h=M.project_history_adapter(api)
assert(h.caption(project,-1)=='Rename ruler lane')
assert(h.caption(project,1)==nil)
local ok,err=h.step(project,-1)
assert(ok and err==nil)
assert(h.caption(project,-1)=='Change marker lane')
assert(h.caption(project,1)=='Rename ruler lane')
ok,err=h.step(project,1)
assert(ok and err==nil and calls.undo==1 and calls.redo==1)
assert(h.caption(nil,-1)==nil)
ok,err=h.step(nil,-1)
assert(not ok and err=='No REAPER project history entry')
-- No project history must not fall back to notes history.
assert(M.history_route('markers',false,true,false)==nil)
print('History routing: all mock tests passed')
