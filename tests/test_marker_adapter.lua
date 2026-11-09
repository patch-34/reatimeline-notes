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
  }
}
local calls={begin=0,finish=0,write=0,rename=0,update=0}
local r={}
function r.GetSetProjectInfo(project,key,value,set)
  assert(project==p)
  if key=='RULER_LANE_COUNT' and not set then return #p.lanes end
  local ci=key:match('^RULER_LANE_COLOR:(%d+)
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
ok,err=a.rename(p,'{LANE-B}','Overwrite stale value','SFX')
assert(not ok and calls.rename==1 and p.lanes[2].name=='Effects')
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

-- G2.2: lane default colors do not change marker identity or position.
local color=0x1000000|0x123456
ok,err=a.set_color(p,'{LANE-A}',color,0)
assert(ok,err)
assert(a.read(p).lanes[2].color==color)
ok,err=a.set_color(p,'{LANE-A}',0,0)
assert(not ok and err=='Lane color changed externally; reopen the menu')
assert(a.read(p).lanes[2].color==color)
ok,err=a.set_color(p,'{MISSING}',color)
assert(not ok)
local guid_before=p.markers[1].guid
local pos_before=p.markers[1].position
ok,err=a.create_lane(p,2)
assert(ok,err)
assert(#a.read(p).lanes==3 and err=='{NEW-LANE-3}')
assert(p.markers[1].guid==guid_before and p.markers[1].position==pos_before)
ok,err=a.create_lane(p,2)
assert(not ok and err=='Lane list changed externally')
ok,err=a.move_lane(p,'{LANE-A}',0,1)
assert(ok,err)
assert(a.read(p).lanes[1].guid=='{LANE-A}')
assert(a.read(p).by_guid['{MARKER-1}'].lane==0)
assert(p.markers[1].guid==guid_before and p.markers[1].position==pos_before)
ok,err=a.move_lane(p,'{LANE-B}',2,0)
assert(not ok and err=='Lane order changed externally; reopen the menu')
ok,err=a.move_lane(p,'{NONEXISTENT}',0)
assert(not ok)
assert(calls.begin==6 and calls.finish==6)

print('G2 marker adapter: all mock tests passed')
)
  if ci then
    local lane=assert(p.lanes[tonumber(ci)+1])
    if set then lane.color=value end
    return lane.color or 0
  end
  local oi=key:match('^RULER_LANE_ORDER:(-?%d+)
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
ok,err=a.rename(p,'{LANE-B}','Overwrite stale value','SFX')
assert(not ok and calls.rename==1 and p.lanes[2].name=='Effects')
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
)
  if oi then
    assert(set and type(value)=='number')
    if tonumber(oi)==-1 then
      assert(value==#p.lanes)
      p.lanes[#p.lanes+1]={guid='{NEW-LANE-3}',name='',color=0}
      return #p.lanes-1
    end
    local old=tonumber(oi)
    assert(old>=0 and old<#p.lanes and value>=0 and value<#p.lanes)
    local ownership={}
    for _,m in ipairs(p.markers) do ownership[m]=p.lanes[m.lane+1].guid end
    local moved=table.remove(p.lanes,old+1)
    table.insert(p.lanes,value+1,moved)
    for m,guid in pairs(ownership) do
      for i,lane in ipairs(p.lanes) do
        if lane.guid==guid then m.lane=i-1;break end
      end
    end
    return value
  end
  error('Unknown project info key '..key)
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
ok,err=a.rename(p,'{LANE-B}','Overwrite stale value','SFX')
assert(not ok and calls.rename==1 and p.lanes[2].name=='Effects')
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
