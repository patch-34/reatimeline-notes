-- ReaTimeline Notes G2 adapter integration mock.
-- Execute from repository root: lua5.4 tests/test_marker_adapter.lua
local M=assert(loadfile('ReaTimeline_Notes.lua'))('__test')
assert(type(M)=='table' and type(M.timeline_marker_adapter)=='function')
local p={
  lanes={{guid='{LANE-A}',name='Dialogue'},{guid='{LANE-B}',name='SFX'}},
  markers={{
    guid='{MARKER-1}',name='Footsteps',number=3,lane=0,position=2.084123},
    {guid='{MARKER-2}',name='City',number=6,lane=1,position=7.50789},
    {guid='{REGION-1}',name='Scene',number=1,lane=0,position=0,is_region=true}
  }}
}
local calls={begin=0,finish=0,write=0,rename=0,update=0}
local r={}
function r.GetSetProjectInfo(project,key,value,set)
  assert(project==p and key=='RULER_LANE_COUNT' and not set)
  return #p.lanes
end
function r.GetSetProjectInfo_String(project,key,value,set)
  assert(project==p)
  local kind,index=key:match('^(RULER_LANE_[A-Z]+):(%d+)$')
  local lane=p.lanes[tonumber(index)+1]
  if not lane then return false,'' end
  if kind=='RULER_LANE_GUID' then return true,lane.guid end
  if kind=='RULER_LANE_NAME' then
    if set then lane.name=value;calls.rename=calls.rename+1 end
    return true,lane.name
  end
  error('Unknown project string '..key)
end
function r.GetNumRegionsOrMarkers(project) assert(project==p);return #p.markers end
function r.GetRegionOrMarker(project,index,guid)
  assert(project==p)
  if index>=0 then return p.markers[index+1] end
  for _,m in ipairs(p.markers) do if m.guid==guid then return m end end
end
function r.GetRegionOrMarkerInfo_Value(project,m,key)
  assert(project==p)
  if key=='B_ISREGION' then return m.is_region and 1 or 0 end
  if key=='I_LANENUMBER' then return m.lane end
  if key=='I_NUMBER' then return m.number end
  if key=='D_STARTPOS' then return m.position end
  error('Unknown marker value '..key)
end
function r.GetSetRegionOrMarkerInfo_String(project,m,key,value,set)
  assert(project==p and not set)
  if key=='GUID' then return true,m.guid end
  if key=='P_NAME' then return true,m.name end
  error('Unknown marker field '..key)
end
function r.SetRegionOrMarkerInfo_Value(project,m,key,value)
  assert(project==p and key=='I_LANENUMBER')
  assert(value>=0 and value<#p.lanes)
  m.lane=value;calls.write=calls.write+1
  return value
end
function r.Undo_BeginBlock2(project)assert(project==p);calls.begin=calls.begin+1 end
function r.Undo_EndBlock2(project,name,flags)
  assert(project==p and type(name)=='string' and flags==-1)
  calls.finish=calls.finish+1
end
function r.UpdateTimeline() calls.update=calls.update+1 end
local a=M.timeline_marker_adapter(r)
local snap=a.read(p)
assert(snap.count==2 and #snap.lanes==2)
assert(snap.lanes[1].guid=='{LANE-A}' and #snap.lanes[1].markers==1)
assert(snap.by_guid['{MARKER-1}'].position==2.084123)
local ok,err=a.move(p,'{MARKER-1}','{LANE-A}','{LANE-B}')
assert(ok,err)
assert(p.markers[1].lane==1 and p.markers[1].position==2.084123)
assert(calls.write==1 and calls.begin==1 and calls.finish==1)
assert(#a.read(p).lanes[2].markers==2)
local before=calls.write
ok,err=a.move(p,'{MARKER-1}','{LANE-A}','{LANE-B}')
assert(not ok and err and calls.write==before) -- stale origin
ok,err=a.move(p,'{MARKER-1}','{LANE-B}','{LANE-B}')
assert(not ok and calls.write==before) -- no self-drop
ok,err=a.move(p,'{MISSING}','{LANE-B}','{LANE-A}')
assert(not ok and calls.write==before)
ok,err=a.move(p,'{MARKER-1}','{LANE-B}','{DELETED}')
assert(not ok and calls.write==before)
ok,err=a.rename(p,'{LANE-B}','Effects')
assert(ok,err)
assert(p.lanes[2].name=='Effects' and calls.rename==1)
assert(calls.begin==2 and calls.finish==2)
ok,err=a.rename(p,'{REMOVED}','Nope')
assert(not ok and calls.rename==1)
-- External changes are visible on the next read; no native writes.
p.markers[2].lane=0
p.lanes[1].name='DX'
snap=a.read(p)
assert(snap.lanes[1].name=='DX' and snap.by_guid['{MARKER-2}'].lane==0)
assert(calls.write==before)
-- A lane's GUID, rather than a cached index, determines the target.
p.lanes[1],p.lanes[2]=p.lanes[2],p.lanes[1]
p.markers[1].lane=0 -- SFX
p.markers[2].lane=1 -- DX
ok,err=a.move(p,'{MARKER-1}','{LANE-B}','{LANE-A}')
assert(ok,err)
assert(p.markers[1].lane==1 and calls.write==before+1)
assert(calls.begin==3 and calls.finish==3)
print('G2 marker adapter: all mock tests passed')
