pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- game

facing = 0
north = 1
east = 2
south = 3
west = 4

inv = {
 [north] = south,
 [east] = west,
 [south] = north,
 [west] = east
}

function _init()
 dt = 1 / 60
 level = 1

 grid = {}
 nodes = {}
 pac_dots = {}
 power_pellets = {}
 pacman = {}
 ghosts = {}
 pickup_time = 0
 big_pickup_time = 0
 freeze = 0
 door = 1 -- 1 = closed, 0 = open
 door_open = false
 shinay = 0 -- jemaine clement
 
 -- build the map
 grid = {}
 for y = -1, 32 do
  grid[y] = {}
  for x = -1, 32 do
   local tile = {
   }
   grid[y][x] = tile
   
   if x == -1 or y == -1 or
      x == 32 or y == 32 then
    tile.wall = true
    goto continue
   end
   
   local id = sget(x, y + 64)
   
   -- wall
   if id == 13 then
    tile.wall = true
    
   -- pac-dot
   elseif id == 9 then
    add(pac_dots, {
     x = x * 4 + 2,
     y = y * 4 + 2
    })
    
   -- power pellets
   elseif id == 12 then
    add(power_pellets, {
     x = x * 4 + 2,
     y = y * 4 + 2
    })
    
   -- pac-man
   elseif id == 10 then
    pacman = new_pacman(x * 4 + 4, y * 4 + 2)
    
   -- ghosts
   elseif id == 8 then
    local ghost = new_ghost(x * 4 + 4, y * 4 + 2, blinky)
    add(ghosts, ghost)
   elseif id == 14 then
    local ghost = new_ghost(x * 4 + 4, y * 4 + 2, pinky)
    add(ghosts, ghost)
   elseif id == 11 then
    local ghost = new_ghost(x * 4 + 4, y * 4 + 2, inky)
    add(ghosts, ghost)
   elseif id == 15 then
    local ghost = new_ghost(x * 4 + 4, y * 4 + 2, clyde)
    add(ghosts, ghost)
    
   end
   
::continue::
  end
 end
 
 -- pass on the extras
 for y = 0, 31 do
  for x = 0, 31 do
   local tile = grid[y][x]
   local id = sget(x + 32, y + 64)
    
   -- path node
   if id == 11 then
   	local node = new_node(x, y)
    add(nodes, node)
    tile.node = node
    
   -- node preventing going up
   elseif id == 10 then
   	local node = new_node(x, y)
   	node.prevent_north = true
    add(nodes, node)
    tile.node = node
    
   -- mid path node
   elseif id == 9 then
   	local node = new_node(x + .5, y)
    add(nodes, node)
    tile.node = node
   end
  end
 end

 -- manually connect the 2
 -- teleport nodes
 local teleport_node1,
       teleport_node2 =
  grid[14][0].node,
  grid[14][31].node
 teleport_node1.teleport = teleport_node2
 teleport_node2.teleport = teleport_node1
 
 set_state(pacman, pacman_idle)
 for ghost in all(ghosts) do
  set_state(ghost, 
   ghost_starting_state[ghost.typ])
 end
end

function map_pos(x, y)
 return flr(x / 4), flr(y / 4)
end

function wall_at(x, y)
 local mx, my = map_pos(x, y)
 return grid[my][mx].wall
end

function node_at_exact(x, y)
 for node in all(nodes) do
  local nx, ny = 
   node.x * 4 + 2,
   node.y * 4 + 2
  if flr(x + .5) == nx and
     flr(y + .5) == ny then
   return node
  end
 end
 return nil
end

function dis(x1, y1, x2, y2)
 local q, w =
  x2 - x1, y2 - y1
 return sqrt(q*q + w*w)
end

function _update60()
 freeze -= dt
 pickup_time -= dt
 big_pickup_time -= dt
 
 if freeze <= 0 then
  door_open = false
  foreach(ghosts, update)
  if door_open then
   door = max(0, door - dt * 4)
  elseif not door_open then
   door = min(1, door + dt * 4)
  end
  if pacman.freeze_frames > 0 then
   pacman.freeze_frames -= 1
  else
	  update(pacman)
	 end
 end
end

function _draw()
 cls(0)
 clip(8, 0, 112, 128)
 camera(0, -2)
 if big_pickup_time > 0 and
    big_pickup_time % .2 > .1 or
    shinay > 31 and shinay < 34 then
  pal(13, 6)
 end
 map()
 
 if shinay < 32 then
  pal(13, 7)
  for i = 0, 31 do
   map(shinay - i, i,
    (shinay - i) * 8, 
    i * 8,
    1, 1)
  end
 end
 shinay += 1
 
 pal(13, 13)
 foreach(pac_dots, draw_pacdot)
 foreach(power_pellets, draw_powerpellet)
 
 -- prison door
 local door = door % 2
 if door > 1 then
  door = 2 - door
 end
 door = flr(door * 4) / 4
 rectfill(60, 50, 60 + 4 * door, 
  50, 14)
 rectfill(64 + 3 * (1 - door), 50, 67, 
  50, 14)
 rectfill(60, 51, 60 + 4 * door, 
  51, 2)
 rectfill(64 + 3 * (1 - door),
  51, 67, 
  51, 2)
 
 foreach(ghosts, draw)
 draw(pacman)
 clip()
 
 -- hud
 for i = 1, pacman.life do
  spr(50, 0, 0 + (i - 1) * 8)
 end
 
 local spd = dat(dat_ghost_spd)
 print(ref_spd, 0, 0, 7)
 print(spd, 0, 10)
 print(spd * ref_spd * dt, 0, 20)
 
 local spd = dat(dat_pacman_spd)
 print(ref_spd, 0, 30, 7)
 print(spd, 0, 40)
 print(spd * ref_spd * dt, 0, 50)
 print("")
 
 --draw_nodes(nodes)
end

-->8
-- node

function new_node(x, y)
 local node = {
  x = x,
  y = y,
  nbh = {}
 }
 return node
end

function draw_nodes(nodes)
 for node in all(nodes) do
  rect(
   node.x * 4, node.y * 4,
   node.x * 4 + 3, node.y * 4 + 3,
   11)
 end
end

-->8
-- pacman

function new_pacman(x, y)
 local pacman = {
  x = x,
  y = y,
  direction = facing,
  dot_cnt = 0,
  dirp = facing,
  dirp_time = 0,
  power_time = 0,
  life = 3,
  freeze_frames = 0
 }
 return pacman
end

function can_move_north(x, y)
 return
  not wall_at(x, y - 3) and
  flr(x + .5) % 4 == 2
end

function can_move_east(x, y)
 return
  not wall_at(x + 2, y) and
  flr(y + .5) % 4 == 2
end

function can_move_south(x, y)
 return
  not wall_at(x, y + 2) and
  flr(x + .5) % 4 == 2
end

function can_move_west(x, y)
 return
  not wall_at(x - 3, y) and
  flr(y + .5) % 4 == 2
end

pacman_idle = {
 update = function(o)
  if btnp(⬆️) and 
     can_move_north(o.x, o.y) then
   o.direction = north
   set_state(o, pacman_run)
   o.x = flr(o.x / 4) * 4 + 2
  elseif btnp(➡️) and 
     can_move_east(o.x, o.y) then
   o.direction = east
   set_state(o, pacman_run)
   o.y = flr(o.y / 4) * 4 + 2
  elseif btnp(⬇️) and 
     can_move_south(o.x, o.y) then
   o.direction = south
   set_state(o, pacman_run)
   o.x = flr(o.x / 4) * 4 + 2
  elseif btnp(⬅️) and 
     can_move_west(o.x, o.y) then
   o.direction = west
   set_state(o, pacman_run)
   o.y = flr(o.y / 4) * 4 + 2
  end
 end,
 
 draw = function(o)
  spr(32, o.x - 4, o.y - 4)
 end
}

pacman_run = {
 enter = function(o)
  o.anim = 0
 end,
 
 update = function(o)
  o.dirp_time -= dt
  if btn(⬆️) then
   o.dirp_time = .5
   o.dirp = north
  end
  if btn(➡️) then
   o.dirp_time = .5
   o.dirp = east
  end
  if btn(⬇️) then
   o.dirp_time = .5
   o.dirp = south
  end
  if btn(⬅️) then
   o.dirp_time = .5
   o.dirp = west
  end
 
  if o.dirp == north and
     o.dirp_time > 0 and 
     can_move_north(o.x, o.y) then
   o.direction = north
   o.x = flr(o.x / 4) * 4 + 2
   o.dirp_time = 0
  elseif o.dirp == east and
     o.dirp_time > 0 and 
     can_move_east(o.x, o.y) then
   o.direction = east
   o.y = flr(o.y / 4) * 4 + 2
   o.dirp_time = 0
  elseif o.dirp == south and
     o.dirp_time > 0 and 
     can_move_south(o.x, o.y) then
   o.direction = south
   o.x = flr(o.x / 4) * 4 + 2
   o.dirp_time = 0
  elseif o.dirp == west and
     o.dirp_time > 0 and 
     can_move_west(o.x, o.y) then
   o.direction = west
   o.y = flr(o.y / 4) * 4 + 2
   o.dirp_time = 0
  end

  local vx, vy = dir_to_vec(o.direction)
  
  if wall_at(o.x + vx * 2, o.y + vy * 2) then
   o.x = flr(o.x / 4) * 4 + 2
   o.y = flr(o.y / 4) * 4 + 2
   set_state(o, pacman_idle)
   return
  end
  
  local spd = dat(dat_pacman_spd)
  o.x += vx * ref_spd * spd * dt
  o.y += vy * ref_spd * spd * dt
  o.anim += spd * 15 * dt
  
  -- pickup items
  for dot in all(pac_dots) do
   if touchy(dot, o) then
    pickup_pacdot(dot, o)
   end
  end
  for pp in all(power_pellets) do
   if touchy(pp, o) then
    pickup_powerpellet(pp, o)
   end
  end
 end,
 
 draw = function(o)
  local frames = _pacman_run_frames[o.direction]
  local frame = flr(o.anim % #frames) + 1
  spr(frames[frame], o.x - 4, o.y - 4)
 end
}

pacman_die = {
 enter = function(o)
  freeze = 6
  o.anim = 0
  sfx(2)
 end,
 
 draw = function(o)
  local frames = _pacman_die_frames
  local frame = min(flr(o.anim), #frames - 1) + 1
  frame = frames[frame]
  if frame then
   spr(frame, o.x - 4, o.y - 4)
  end
  o.anim += .2
  
  if o.anim >= #frames + 8 then
   _init()
  end
 end
}

-->8
-- pac-dot

function draw_pacdot(pacdot)
 spr(0, pacdot.x - 4, pacdot.y - 4)
end

function pickup_pacdot(pacdot, o)
 o.dot_cnt += 1
 del(pac_dots, pacdot)
 sfx(0)
 pickup_time = .1
 o.freeze_frames = 1
end

-->8
-- power pellet

function draw_powerpellet(powerpellet)
 spr(16, powerpellet.x - 4, powerpellet.y - 4)
end

function pickup_powerpellet(pp, o)
 o.power_time = 10
 del(power_pellets, pp)
 sfx(1)
 freeze = .5
 pickup_time = .1
 big_pickup_time = .5
 shinay = 0
 o.freeze_frames = 3
 
 foreach(ghosts, frighten)
end

-->8
-- ghost
blinky = 0
pinky = 16
inky = 32
clyde = 48

ghost_colours = {
 [blinky] = 8,
 [pinky] = 14,
 [inky] = 12,
 [clyde] = 9
}

ghost_prison_time = {
 [blinky] = 0,
 [pinky] = 7,
 [inky] = 17,
 [clyde] = 32
}

ghost_by_typ = {}

function new_ghost(x, y, typ)
 local ghost = {
  x = x,
  y = y,
  typ = typ,
  direction = east
 }
 ghost_by_typ[typ] = ghost
 return ghost
end

function draw_frightened_ghost(o)
 local frames = _ghost_frightened_frames
 local frame = frames[flr(o.anim) % #frames + 1]
 if o.free_time < 1.8 then
  if o.free_time % .6 > .3 then
   frame += 16
  end
 end
 spr(frame, o.x - 4, o.y - 4)
end

function draw_eyes(o)
 local frame = _eyes_frames[o.direction]
 spr(frame, o.x - 4, o.y - 4)
end

function draw_ghost(o)
 local frames = _ghost_frames[o.direction]
 local frame = frames[flr(o.anim) % #frames + 1]
 frame += o.typ
 spr(frame, o.x - 4, o.y - 4)
  
  -- debug ghost target
  --local x, y = get_target(o)
  --x *= 4
  --y *= 4
  --rect(x - 1, y - 1, x + 4, y + 4, ghost_colours[o.typ])
end

function get_possible_dirs(o, except)
 local dirs = {}
 local x, y = flr(o.x + .5), flr(o.y + .5)
 if not wall_at(x - 2, y - 4) and
    not wall_at(x + 1, y - 4) and
    not has(except, north) then
  add(dirs, north)
 end
 if not wall_at(x + 4, y - 2) and
    not wall_at(x + 4, y + 1) and
    not has(except, east) then
  add(dirs, east)
 end
 if not wall_at(x - 2, y + 4) and
    not wall_at(x + 1, y + 4) and
    not has(except, south) then
  add(dirs, south)
 end
 if not wall_at(x - 4, y - 2) and
    not wall_at(x - 4, y + 1) and
    not has(except, west) then
  add(dirs, west)
 end
 return dirs
end

ghost_prison = {
 enter = function(o)
  o.anim = 0
  o.dots_start = #pac_dots
  o.direction = flr(rnd(4)) + 1
 end,
 
 update = function(o)
  if o.direction == north and
     wall_at(o.x, o.y - 4) then
   local dirs = get_possible_dirs(o, {north})
   o.direction = dirs[flr(rnd(#dirs)) + 1]
  elseif o.direction == east and
     wall_at(o.x + 3, o.y) then
   local dirs = get_possible_dirs(o, {east})
   o.direction = dirs[flr(rnd(#dirs)) + 1]
  elseif o.direction == south and
     wall_at(o.x, o.y + 3) then
   local dirs = get_possible_dirs(o, {south})
   o.direction = dirs[flr(rnd(#dirs)) + 1]
  elseif o.direction == west and
     wall_at(o.x - 4, o.y) then
   local dirs = get_possible_dirs(o, {westrth})
   o.direction = dirs[flr(rnd(#dirs)) + 1]
  end
 
  local vx, vy = dir_to_vec(o.direction)
  local spd = dat(dat_ghost_spd)
  o.x += vx * ref_spd * spd * dt
  o.y += vy * ref_spd * spd * dt

  o.anim += spd * 15 * dt
  
  -- check if we can exit the prison
  local dot_cnt = o.dots_start - #pac_dots
  if dot_cnt >= ghost_prison_time[o.typ] then
   set_state(o, ghost_leave_prison)
   return
  end
 end,
 
 draw = draw_ghost
}

function get_target(o)
 if o.typ == blinky then
  return map_pos(pacman.x, pacman.y)
 elseif o.typ == pinky then
  local vx, vy = dir_to_vec(pacman.direction)
  if pacman.direction == north then
   vx = -1
  end
  local mx, my = map_pos(pacman.x, pacman.y)
  return mx + vx * 4, my + vy * 4
 elseif o.typ == inky then
  local vx, vy = dir_to_vec(pacman.direction)
  local mx, my = map_pos(pacman.x, pacman.y)
  if pacman.direction == north then
   vx = -1
  end
  local ax, ay = mx + vx * 2, my + vy * 2
  local blinky = ghost_by_typ[blinky]
  mx, my = map_pos(blinky.x, blinky.y)
  return
     mx + (ax - mx) * 2,
     my + (ay - my) * 2
 elseif o.typ == clyde then
  local px, py = map_pos(pacman.x, pacman.y)
  local mx, my = map_pos(o.x, o.y)
  local d = dis(mx, my, px, py)
  if d <= 8 then
   return 0, 32
  else
   return px, py
  end
 end
 
 return 0, 0
end

-- with all possible directions,
-- pick the closest one to target tx,ty
function chose_dir(o, dirs, tx, ty)
 local mx, my = map_pos(o.x, o.y)
 local vx, vy = dir_to_vec(dirs[1])
 local best = dis(tx, ty, mx + vx, my + vy)
 local best_dir = dirs[1]
 for i = 2, #dirs do
  vx, vy = dir_to_vec(dirs[i])
  local d = dis(tx, ty, mx + vx, my + vy)
  if d < best then
   best = d
   best_dir = dirs[i]
  end
 end
 return best_dir
end

ghost_seek = {
 enter = function(o)
  o.anim = 0
  local tx, ty = get_target(o)
  o.direction = chose_dir(
   o, 
   get_possible_dirs(o, {}),
   tx, ty)
 end,
 
 update = function(o)
  local vx, vy = dir_to_vec(o.direction)
  local prev_node = node_at_exact(o.x, o.y)
  local spd = dat(dat_ghost_spd)
  o.x += vx * spd * dt * ref_spd
  o.y += vy * spd * dt * ref_spd
  local node = node_at_exact(o.x, o.y)
  if node and node != prev_node then
   if node.teleport then
    node = node.teleport
    o.x = node.x * 4 + 2
    o.y = node.y * 4 + 2
   end
   o.x = flr(o.x / 4) * 4 + 2
   o.y = flr(o.y / 4) * 4 + 2
   local tx, ty = get_target(o)
   local dir_exclude = {
    inv[o.direction]
   }
   if node.prevent_north then
    add(dir_exclude, north)
   end
   o.direction = chose_dir(o, 
    get_possible_dirs(o, dir_exclude),
    tx, ty)
  end
  o.anim += dt * spd * 15
  
  if touch(o, pacman) then
   set_state(pacman, pacman_die)
  end
 end,
 
 draw = draw_ghost
}

ghost_flee = {
 enter = function(o)
  o.free_time = 6
  o.direction = inv[o.direction]
  o.anim = 0
 end,
 
 update = function(o)
  local vx, vy = dir_to_vec(o.direction)
  local prev_node = node_at_exact(o.x, o.y)
  local spd = dat(dat_fright_ghost_spd)
  o.x += vx * spd * dt * ref_spd
  o.y += vy * spd * dt * ref_spd
  local node = node_at_exact(o.x, o.y)
  if node and node != prev_node then
   if node.teleport then
    node = node.teleport
    o.x = node.x * 4 + 2
    o.y = node.y * 4 + 2
   else
    o.x = flr(o.x / 4) * 4 + 2
    o.y = flr(o.y / 4) * 4 + 2
    local dirs = get_possible_dirs(o, {})
    o.direction = dirs[flr(rnd(#dirs)) + 1]
   end
  end 
 
  o.anim += spd * 15 * dt
  o.free_time -= dt
  if o.free_time < 0 then
   set_state(o, ghost_seek)
   if shinay > 32 then
    shinay = 0
   end
   sfx(4)
   return
  end
  
  if touch(o, pacman) then
   set_state(o, ghost_go_prison)
   return
  end
 end,
 
 draw = draw_frightened_ghost
}

ghost_corner = {
}

function get_prison(o)
 if o.y > 64 then
  return 15, 0
 elseif o.y < 40 then
  return 32, 32
 end
 return 16, 11
end

ghost_enter_prison = {
 update = function(o)
  door_open = true
  local spd = dat(dat_ghost_spd)
  o.y += ref_spd * spd * dt
  if o.y >= 54 then
   set_state(o, ghost_prison)
  end
  o.anim += 15 * spd * dt
 end,
 
 draw = draw_eyes
}

ghost_go_prison = {
 enter = function(o)
  freeze = .2
  sfx(3)
  local tx, ty = get_prison(o)
  o.direction = chose_dir(
   o, 
   get_possible_dirs(o, {}),
   tx, ty)
 end,
 
 update = function(o)
  local vx, vy = dir_to_vec(o.direction)
  local prev_node = node_at_exact(o.x, o.y)
  local spd = dat(dat_ghost_spd)
  o.x += vx * spd * dt * ref_spd
  o.y += vy * spd * dt * ref_spd
  local node = node_at_exact(o.x, o.y)
  if node and node != prev_node then
   if node.teleport then
    node = node.teleport
    o.x = node.x * 4 + 2
    o.y = node.y * 4 + 2
   end
   o.x = flr(o.x / 4) * 4 + 2
   o.y = flr(o.y / 4) * 4 + 2
   local tx, ty = get_prison(o)
   o.direction = chose_dir(o, 
    get_possible_dirs(o, {}),
    tx, ty)
  end
  o.anim += spd * 15 * dt
  if flr(o.x) == 64 and
     flr(o.y) == 46 then
   set_state(o, ghost_enter_prison)
  end
 end,
 
 draw = draw_eyes
}

ghost_leave_prison = {
 update = function(o)
  local spd = dat(dat_ghost_spd)
  -- align horizontally
  if o.x < 64 then
   o.direction = east
   o.x += spd * ref_spd * dt
   if o.x >= 64 then
    o.x = 64
   end
  elseif o.x > 64 then
   o.direction = west
   o.x -= spd * ref_spd * dt
   if o.x <= 64 then
    o.x = 64
   end
  else
   door_open = true
   o.y -= spd * ref_spd * dt
   if o.y <= 46 then
    o.y = 46
    set_state(o, ghost_seek)
    return
   end
  end

  o.anim += dt * 15 * spd
 end,
 
 draw = draw_ghost
}

ghost_starting_state = {
 [blinky] = ghost_seek,
 [pinky] = ghost_prison,
 [inky] = ghost_prison,
 [clyde] = ghost_prison
}

function frighten(o)
 if o.state == ghost_seek or
    o.state == ghost_corner then
  set_state(o, ghost_flee)
 elseif o.state == ghost_flee then 
  o.free_time = 6
 end
end
-->8
-- helpers
function has(t, i)
 for j in all(t) do
  if j == i then
   return true
  end
 end
 return false
end

-- small touch detection
function touchy(a, b)
	return 
	 a.x >= b.x - 1 and
  a.x <= b.x + 1 and
  a.y >= b.y - 1 and
  a.y <= b.y + 1
end

-- larger touch
function touch(a, b)
	return 
	 a.x >= b.x - 3 and
  a.x <= b.x + 3 and
  a.y >= b.y - 3 and
  a.y <= b.y + 3
end

function dir_to_vec(direction)
 if direction == north then
  return 0, -1
 elseif direction == east then
  return 1, 0
 elseif direction == south then
  return 0, 1
 elseif direction == west then
  return -1, 0
 end
 return 0, 0
end

-->8
-- states and anims

function update(obj)
 if obj.state then
  if obj.state.update then
   obj.state.update(obj)
  end
 end
end

function draw(obj)
 if obj.state then
  if obj.state.draw then
   obj.state.draw(obj)
  end
 end
end

function set_state(obj, state)
 if obj.state == state then
  return
 end
 
 if obj.state then
  if obj.state.leave then
   obj.state.leave(obj, state)
  end
 end
 
 obj.state = state
 
 if obj.state then
  if obj.state.enter then
   obj.state.enter(obj, state)
  end
 end
end

-- anims
_pacman_run_frames = {
 [north] = {32, 35, 36, 35},
 [east] = {32, 33, 34, 33},
 [south] = {32, 48, 49, 48},
 [west] = {32, 50, 51, 50}
}

_pacman_die_frames = {
 32, 35, 36, 52, 5, 21, 37, 
 53, nil, 53, nil, 53, nil
}

_ghost_frames = {
 [north] = {12, 13},
 [east] = {8, 9},
 [south] = {14, 15},
 [west] = {10, 11}
}
_ghost_frightened_frames = {6, 7}
_eyes_frames = {
 [north] = 54,
 [east] = 38,
 [south] = 55,
 [west] = 39
}

-- pac data
ref_spd = 44

spr_cherries = 1
spr_strawberry = 2
spr_peach = 3
spr_apple = 4
spr_grapes = 17
spr_galaxian = 18
spr_bell = 19
spr_key = 20

dat_bonus_symbol = {
 spr_cherries,
 spr_strawberry,
 spr_peach,
 spr_peach,
 spr_apple,
 spr_apple,
 spr_grapes,
 spr_grapes,
 spr_galaxian,
 spr_galaxian,
 spr_bell,
 spr_bell,
 spr_key
}

dat_bonus_pts = {
 100, 300, 500, 500,
 700, 700, 1000, 1000,
 2000, 2000, 3000, 3000,
 5000
}

dat_pacman_spd = {
 .8, .9, .9, .9,
 1, 1, 1, 1,
 1, 1, 1, 1,
 1, 1, 1, 1,
 1, 1, 1, 1,
 .9
}

dat_pac_dot_spd = {
 .71, .79, .79, .79,
 .87, .87, .87, .87,
 .87, .87, .87, .87,
 .87, .87, .87, .87,
 .87, .87, .87, .87,
 .79
}

dat_ghost_spd = {
 .75, .85, .85, .85,
 .95
}

dat_ghost_tunnel_spd = {
 .4, .45, .45, .45, .5
}

dat_elrow_1_dot_left = {
 20, 30, 40, 40, 
 40, 50, 50, 50, 
 60, 60, 60, 80,
 80, 80, 100, 100,
 100, 100, 120
}

dat_elroy_1_dot_spd = {
 .8, .9, .9, .9, 1
}

dat_elrow_2_dot_left = {
 10, 15, 20, 20,
 20, 25, 25, 25,
 30, 30, 30, 40,
 40, 40, 50, 50,
 50, 50, 60, 60,
 60
}

dat_elrow_2_spd = {
 .85, .95, .95, .95, 1.05
}

dat_fright_pm_spd = {
 .9, .95, .95, .95,
 1, 1, 1, 1,
 1, 1, 1, 1,
 1, 1, 1, 1,
 nil, 1, nil
}

dat_fright_pm_dot_spd = {
 .79, .83, .83, .83,
 .87, .87, .87, .87,
 .87, .87, .87, .87,
 .87, .87, .87, .87,
 nil, .87, nil
}

dat_fright_ghost_spd = {
 .5, .55, .55, .55,
 .6, .6, .6, .6,
 .6, .6, .6, .6,
 .6, .6, .6, .6,
 nil, .6, nil
}

dat_fright_time = {
 6, 5, 4, 3,
 2, 5, 2, 2, 
 1, 5, 2, 1,
 1, 3, 1, 1,
 nil, 1, nil
}

dat_num_flashes = {
 5, 5, 5, 5,
 5, 5, 5, 5,
 3, 5, 5, 3,
 3, 5, 3, 3,
 nil, 3, nil
}

function dat(d)
 return d[min(#d, level)]
end

__gfx__
00000000000000000000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000090003bb30000004b30000900000000000000111100001111000028880000288800002888000028880000288800002888000028880000288800
0000000000009940088b8e80009499000088880000000000018e18e0018e18e00277877002778770077877800778778002748470027484700288888002888880
0009a0000289090008e8e88004999a9002888e800000000001ee1ee001ee1ee00274874002748740047847800478478002778770027787700277877002778770
000990000e82842002888e800999999002888e8000aa0a0001181810018181100288888002888880028888800288888002888880028888800274847002748470
000220000282e88000e8e800049999900288888009aaaa9001818110011818100288888002888880028888800288888002888880028888800288888002888880
00000000000028200002800000494900002828000099990001011010011001100202808002800280020280800280028002028080028002800202808002800280
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000033000001080100009a000000cc000000000000066660000666600008eee00008eee00008eee00008eee00008eee00008eee00008eee00008eee00
000cc00000bbbb000098a8a00094aa0000d0dc0000000000068e68e0068e68e00877e7700877e770077e77e0077e77e00872e2700872e27008eeeee008eeeee0
00c67c0003b393b00019aa100094aa0000dccc000000000006ee6ee006ee6ee00872e7200872e720027e27e0027e27e00877e7700877e7700877e7700877e770
00c66c00033b3bb00001a100009aaa0000066000000a0000068686600668686008eeeee008eeeee008eeeee008eeeee008eeeee008eeeee00872e2700872e270
001cc1000393b3b00000a000094aaaa00006000000aaa000066868600686866008eeeee008eeeee008eeeee008eeeee008eeeee008eeeee008eeeee008eeeee0
0001100000333b000000900009cc9ca0000d60000099990006066060066006600808e0e008e008e00808e0e008e008e00808e0e008e008e00808e0e008e008e0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00aaa70000aaa70000aaa70000a007000000000000000000000000000000000000dccc0000dccc0000dccc0000dccc0000dccc0000dccc0000dccc0000dccc00
0aaaaa700aaaaa700aaaa0000aaa0a700a0000700000000000770770077077000d77c7700d77c770077c77c0077c77c00d71c1700d71c1700dccccc00dccccc0
0aaaaaa00aaaaa000aaa00000aaa0aa00aa00aa00000000000750750057057000d71c7100d71c710017c17c0017c17c00d77c7700d77c7700d77c7700d77c770
09aaaaa009aa000009a0000009aaaaa009aa0aa0000a000000000000000000000dccccc00dccccc00dccccc00dccccc00dccccc00dccccc00d71c1700d71c170
09aaaa9009aaaa9009aaa00009aaaa9009aaaa90000a000000000000000000000dccccc00dccccc00dccccc00dccccc00dccccc00dccccc00dccccc00dccccc0
00999900009999000099990000999900009999000009000000110110011011000d0dc0c00dc00dc00d0dc0c00dc00dc00d0dc0c00dc00dc00d0dc0c00dc00dc0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00aaa70000aaa70000aaa70000aaa700000000000090a00000000000000000000049990000499900004999000049990000499900004999000049990000499900
0aaaaa700aaaaaa00aaaaa70000aaa700000000000000090007505700000000004779770047797700779779007797790047c9c70047c9c700499999004999990
0aaaaaa00aa0aaa000aaaaa00000aaa00a0000a00a0000000077077000770770047c97c0047c97c00c79c7900c79c79004779770047797700477977004779770
09a0aaa009a00aa00000aaa000000aa009aa0aa0000000a00000000000750570049999900499999004999990049999900499999004999990047c9c70047c9c70
09a0aa900900009009aaaa90000aaa9009aaaa900900000000000000000000000499999004999990049999900499999004999990049999900499999004999990
0090090000000000009999000099990000999900000a090000110110001101100404909004900490040490900490049004049090049004900404909004900490
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ddddddddddddddddddd60000000000000000000000000000000000000000000d2222d000000000000000000000000000000000000000000000000000000000
0d111111111111111111117000000000000000000000000000000000000000000d2222d00ddddddddddddd60000000ddd600000000ddddddddddddddddddd600
d12ddddddddddddddddd621600000000000000000000000000000000000000000d2222d00d111111111111d000000d11116000000d1111111111111111111160
d2d111111111111111111d2d00000000000000000000000000000000000000000d2222d00d2ddddddddd62d000000d2222d000000d22222222222222222222d0
d2d000000000000000000d2d00000000000000000000000000000000000000000d2222d00d2d11111111d2d000000d2222d000000d22222222222222222222d0
d2d000000000000000000d2d000000ddd600000000ddddddddddddddddddd6000d2222d00d2d00000000d2d000000d2222d000000d22222222222222222222d0
d2d000000000000000000d2d00000d11116000000d111111111111111111116001dddd100d2d00000000d2d0000001dddd1000000d22222222222222222222d0
d2d000000000000000000d2d00000d2222d000000d22222222222222222222d0001111000d2d00000000d2d000000011110000000d22222222222222222222d0
d2d000000000000000000d2d00000d2222d000000d22222222222222222222d0000000000000000000000000000000000d2dddddddddd2d00d222222222222d0
d2d00000dddddddd00000d2d00000d2222d000000d22222222222222222222d00000000000000000000000ddd60000000d211111111112d00d222222222222d0
d2d000001111111100000d2d0000016ddd10000001dddddddddddddddddddd10000000000000000000000d11116000000dddddddddddddd00d22222d622222d0
d2d00000dddddddd00000d2d0000001111000000001111111111111111111100000000000000000000000d2222d0000001111111111111100d2222d1162222d0
d2d000001111111100000d2d0000000000000000000000000000000000000000000000000000000000000d2222d0000000000000000000000d2222d00d2222d0
d2d000000000000000000d2d0000000000000000000000000000000000000000000ddddddddd600000000d2222d0000000000000000000000d2222d00d2222d0
d2d000000000000000000d2d000000000000000000000000000000000000000000d111111111170000000d2222d0000000000000000000000d2222d00d2222d0
d2d000000000000000000d2d00000000000000000000000000000000000000000d12ddddddd6216000000d2222d0000000000000000000000d2222d00d2222d0
d2d000000000000000000d2d00000000000000000000000000000000000000000d2d00000000d2d000000d2222d0000000000d2222d000000000000000000000
d2d000000000000000000d2d0000000000ddddddddddd60000000000000000000d2d00000000d2d000000d2222d0000000000d2222d00000dddddddddddddddd
d2d000000000000000000d2d000000000d1111111111116000000000000000000d2d00000000d2d000000d2222d0000000000d2222d000001111111111111111
d2d000000000000000000d2d000000000d222222222222d000000000000000000d2d00000000d2d000000d2222d0000000000d2222d000002222222222222222
d2d000000000000000000d2ddddddddd0d222222222222d000ddddddddddd6000d2d00000000d2d000000d2222d0000000000d2222d000002222222222222222
d216ddddddddddddddddd12d111111110d222222222222d00d111111111111700d2d00000000d2d000000d2222d00000ddddd1222216dddd2222222222222222
1d21111111111111111112d1dddddddd01dddddddddddd10d12ddddddddd62160d2d00000000d2d000000d2222d000001111122222211111dddd6222222ddddd
01dddddddddddddddddddd10111111110011111111111100d2d1111111111d2d0d2d00000000d2d000000d2222d00000222222222222222211111d2222d11111
d1d0000000000d1d0000000000000000ddddddddddddddddd2d0000000000d2d0d2d00000000d2d000000d2222d00000222222222222222200000d2222d00000
d216ddddddddd12dddd600000000dddd1111111111111111d21dddddddddd12d0d2d00000000d2d000000d2222d00000222222222222222200000d2222d00000
d22111111111122d111d00000000d111dddd6222222ddddd1d211111111112d10d2d00000000d2d000000d2222d00000dddd6222222ddddd00000d2222d00000
d22222222222222ddddd00000000dddd11111d2222d1111101dddddddddddd100d2d00000000d2d000000d2222d0000011111d2222d1111100000d2222d00000
d22222222222222d111100000000111100000d2222d0000000111111111111000d21dddddddd12d000000d2222d0000000000d2222d0000000000d2222d00000
d22222222222222d000000000000000000000d2222d00000000000000000000001d2111111112d1000000d2222d0000000000d2222d00000ddddd1222216dddd
d22ddddddddd622d000000000000000000000d2222d000000000000000000000001dddddddddd1000000016ddd10000000000d2222d000001111122222211111
d2d1111111111d2d000000000000000000000d2222d0000000000000000000000001111111111000000000111100000000000d2222d000002222222222222222
00dddddddddddddddddddddddddddd0000dddddddddddddddddddddddddddd000000000000000000000000000000000000000000000000000000000000000000
00d999999999999dd999999999999d0000db0000b00000bddb00000b0000bd000000000000000000000000000000000000000000000000000000000000000000
00d9dddd9ddddd9dd9ddddd9dddd9d0000d0dddd0ddddd0dd0ddddd0dddd0d000000000000000000000000000000000000000000000000000000000000000000
00dcdddd9ddddd9dd9ddddd9ddddcd0000d0dddd0ddddd0dd0ddddd0dddd0d000000000000000000000000000000000000000000000000000000000000000000
00d9dddd9ddddd9dd9ddddd9dddd9d0000d0dddd0ddddd0dd0ddddd0dddd0d000000000000000000000000000000000000000000000000000000000000000000
00d99999999999999999999999999d0000db0000b00b00b00b00b00b0000bd000000000000000000000000000000000000000000000000000000000000000000
00d9dddd9dd9dddddddd9dd9dddd9d0000d0dddd0dd0dddddddd0dd0dddd0d000000000000000000000000000000000000000000000000000000000000000000
00d9dddd9dd9dddddddd9dd9dddd9d0000d0dddd0dd0dddddddd0dd0dddd0d000000000000000000000000000000000000000000000000000000000000000000
00d999999dd9999dd9999dd999999d0000db0000bddb00bddb00bddb0000bd000000000000000000000000000000000000000000000000000000000000000000
00dddddd9ddddd0dd0ddddd9dddddd0000dddddd0ddddd0dd0ddddd0dddddd000000000000000000000000000000000000000000000000000000000000000000
0000000d9ddddd0dd0ddddd9d00000000000000d0ddddd0dd0ddddd0d00000000000000000000000000000000000000000000000000000000000000000000000
0000000d9dd0000800000dd9d00000000000000d0ddb00a00a00bdd0d00000000000000000000000000000000000000000000000000000000000000000000000
0000000d9dd0dddddddd0dd9d00000000000000d0dd0ddd00ddd0dd0d00000000000000000000000000000000000000000000000000000000000000000000000
dddddddd9dd0d000000d0dd9dddddddddddddddd0dd0d000000d0dd0dddddddd0000000000000000000000000000000000000000000000000000000000000000
000000009000db0e0f0d000900000000b0000000b00bd000000db00b0000000b0000000000000000000000000000000000000000000000000000000000000000
dddddddd9dd0d000000d0dd9dddddddddddddddd0dd0d000000d0dd0dddddddd0000000000000000000000000000000000000000000000000000000000000000
0000000d9dd0dddddddd0dd9d00000000000000d0dd0dddddddd0dd0d00000000000000000000000000000000000000000000000000000000000000000000000
0000000d9dd0000000000dd9d00000000000000d0ddb00000000bdd0d00000000000000000000000000000000000000000000000000000000000000000000000
0000000d9dd0dddddddd0dd9d00000000000000d0dd0dddddddd0dd0d00000000000000000000000000000000000000000000000000000000000000000000000
00dddddd9dd0dddddddd0dd9dddddd0000dddddd0dd0dddddddd0dd0dddddd000000000000000000000000000000000000000000000000000000000000000000
00d999999999999dd999999999999d0000db0000b00b00bddb00b00b0000bd000000000000000000000000000000000000000000000000000000000000000000
00d9dddd9ddddd9dd9ddddd9dddd9d0000d0dddd0ddddd0dd0ddddd0dddd0d000000000000000000000000000000000000000000000000000000000000000000
00d9dddd9ddddd9dd9ddddd9dddd9d0000d0dddd0ddddd0dd0ddddd0dddd0d000000000000000000000000000000000000000000000000000000000000000000
00dc99dd9999999a09999999dd99cd0000db0bddb00b00a00a00b00bddb0bd000000000000000000000000000000000000000000000000000000000000000000
00ddd9dd9dd9dddddddd9dd9dd9ddd0000ddd0dd0dd0dddddddd0dd0dd0ddd000000000000000000000000000000000000000000000000000000000000000000
00ddd9dd9dd9dddddddd9dd9dd9ddd0000ddd0dd0dd0dddddddd0dd0dd0ddd000000000000000000000000000000000000000000000000000000000000000000
00d999999dd9999dd9999dd999999d0000db0b00bddb00bddb00bddb00b0bd000000000000000000000000000000000000000000000000000000000000000000
00d9dddddddddd9dd9dddddddddd9d0000d0dddddddddd0dd0dddddddddd0d000000000000000000000000000000000000000000000000000000000000000000
00d9dddddddddd9dd9dddddddddd9d0000d0dddddddddd0dd0dddddddddd0d000000000000000000000000000000000000000000000000000000000000000000
00d99999999999999999999999999d0000db0000000000b00b0000000000bd000000000000000000000000000000000000000000000000000000000000000000
00dddddddddddddddddddddddddddd0000dddddddddddddddddddddddddddd000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d2d11111111d2d01111111100111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d2d00000000d2d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d2d00000000d2d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d2d00000000d2d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d2d00000000d2d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d2d00000000d2d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d2d00000000d2d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d2d00000000d2d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
0000000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd0000000000
000000000d111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111d000000000
00000000d11dddddddddddddddddddddddddddddddddddddddddddddddddd111111dddddddddddddddddddddddddddddddddddddddddddddddddd11d00000000
00000000d1d00000000000000000000000000000000000000000000000000d1111d00000000000000000000000000000000000000000000000000d1d00000000
00000000d1d00000000000000000000000000000000000000000000000000d1111d00000000000000000000000000000000000000000000000000d1d00000000
00000000d1d00990099009900990099009900990099009900990099009900d1111d00990099009900990099009900990099009900990099009900d1d00000000
00000000d1d00990099009900990099009900990099009900990099009900d1111d00990099009900990099009900990099009900990099009900d1d00000000
00000000d1d00220022002200220022002200220022002200220022002200d1111d00220022002200220022002200220022002200220022002200d1d00000000
00000000d1d00000000000000000000000000000000000000000000000000d1111d00000000000000000000000000000000000000000000000000d1d00000000
00000000d1d0099000dddddddddddd00099000dddddddddddddddd0009900d1111d0099000dddddddddddddddd00099000dddddddddddd0009900d1d00000000
00000000d1d009900d111111111111d009900d1111111111111111d009900d1111d009900d1111111111111111d009900d111111111111d009900d1d00000000
00000000d1d002200d111111111111d002200d1111111111111111d002200d1111d002200d1111111111111111d002200d111111111111d002200d1d00000000
00000000d1d00cc00d111111111111d000000d1111111111111111d000000d1111d000000d1111111111111111d000000d111111111111d00cc00d1d00000000
00000000d1d0cccc0d111111111111d009900d1111111111111111d009900d1111d009900d1111111111111111d009900d111111111111d0cccc0d1d00000000
00000000d1d0cccc0d111111111111d009900d1111111111111111d009900d1111d009900d1111111111111111d009900d111111111111d0cccc0d1d00000000
00000000d1d01cc10d111111111111d002200d1111111111111111d002200d1111d002200d1111111111111111d002200d111111111111d01cc10d1d00000000
00000000d1d001100d111111111111d000000d1111111111111111d000000d1111d000000d1111111111111111d000000d111111111111d001100d1d00000000
00000000d1d009900d111111111111d009900d1111111111111111d009900d1111d009900d1111111111111111d009900d111111111111d009900d1d00000000
00000000d1d0099000dddddddddddd00099000dddddddddddddddd00099000dddd00099000dddddddddddddddd00099000dddddddddddd0009900d1d00000000
00000000d1d0022000000000000000000220000000000000000000000220000000000220000000000000000000000220000000000000000002200d1d00000000
00000000d1d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d1d00000000
00000000d1d0099009900990099009900990099009900990099009900990099009900990099009900990099009900990099009900990099009900d1d00000000
00000000d1d0099009900990099009900990099009900990099009900990099009900990099009900990099009900990099009900990099009900d1d00000000
00000000d1d0022002200220022002200220022002200220022002200220022002200220022002200220022002200220022002200220022002200d1d00000000
00000000d1d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d1d00000000
00000000d1d0099000dddddddddddd00099000dddd00099000dddddddddddddddddddddddddddd00099000dddd00099000dddddddddddd0009900d1d00000000
00000000d1d009900d111111111111d009900d1111d009900d1111111111111111111111111111d009900d1111d009900d111111111111d009900d1d00000000
00000000d1d002200d111111111111d002200d1111d002200d1111111111111111111111111111d002200d1111d002200d111111111111d002200d1d00000000
00000000d1d000000d111111111111d000000d1111d000000d1111111111111111111111111111d000000d1111d000000d111111111111d000000d1d00000000
00000000d1d009900d111111111111d009900d1111d009900d1111111111111111111111111111d009900d1111d009900d111111111111d009900d1d00000000
00000000d1d0099000dddddddddddd0009900d1111d0099000ddddddddddd111111ddddddddddd0009900d1111d0099000dddddddddddd0009900d1d00000000
00000000d1d00220000000000000000002200d1111d002200000000000000d1111d000000000000002200d1111d00220000000000000000002200d1d00000000
00000000d1d00000000000000000000000000d1111d000000000000000000d1111d000000000000000000d1111d00000000000000000000000000d1d00000000
00000000d1d00990099009900990099009900d1111d009900990099009900d1111d009900990099009900d1111d00990099009900990099009900d1d00000000
00000000d1d00990099009900990099009900d1111d009900990099009900d1111d009900990099009900d1111d00990099009900990099009900d1d00000000
00000000d1d00220022002200220022002200d1111d002200220022002200d1111d002200220022002200d1111d00220022002200220022002200d1d00000000
00000000d1d00000000000000000000000000d1111d000000000000000000d1111d000000000000000000d1111d00000000000000000000000000d1d00000000
00000000d11dddddddddddddddddd00009900d11111ddddddddddd0000000d1111d0000000ddddddddddd11111d00990000dddddddddddddddddd11d00000000
000000000d1111111111111111111d0009900d1111111111111111d000000d1111d000000d1111111111111111d0099000d1111111111111111111d000000000
0000000000dddddddddddddddddd11d002200d1111111111111111d000000d1111d000000d1111111111111111d002200d11dddddddddddddddddd0000000000
0000000000000000000000000000d1d000000d1111111111111111d000000d1111d000000d1111111111111111d000000d1d0000000000000000000000000000
0000000000000000000000000000d1d009900d1111111111111111d000000d1111d000000d1111111111111111d009900d1d0000000000000000000000000000
0000000000000000000000000000d1d009900d11111ddddddddddd00000000dddd00000000ddddddddddd11111d009900d1d0000000000000000000000000000
0000000000000000000000000000d1d002200d1111d000000000000000000000000000000000000000000d1111d002200d1d0000000000000000000000000000
0000000000000000000000000000d1d000000d1111d000000000000000000000000000000000000000000d1111d000000d1d0000000000000000000000000000
0000000000000000000000000000d1d009900d1111d000000000000000000000000000000000000000000d1111d009900d1d0000000000000000000000000000
0000000000000000000000000000d1d009900d1111d000000000000000000000000000000000000000000d1111d009900d1d0000000000000000000000000000
0000000000000000000000000000d1d002200d1111d000000000000000000000000000000000000000000d1111d002200d1d0000000000000000000000000000
0000000000000000000000000000d1d000000d1111d000000000000000000000000000000000000000000d1111d000000d1d0000000000000000000000000000
0000000000000000000000000000d1d009900d1111d000000ddddddddddd00000000ddddddddddd000000d1111d009900d1d0000000000000000000000000000
0000000000000000000000000000d1d009900d1111d000000d111111111d00000000d111111111d000000d1111d009900d1d0000000000000000000000000000
0000000000000000000000000000d1d002200d1111d000000d1ddddddddd00000000ddddddddd1d000000d1111d002200d1d0000000000000000000000000000
00000000dddddddddddddddddddd11d000000d1111d000000d1d000000000000000000000000d1d000000d1111d000000d11dddddddddddddddddddd00000000
00000000111111111111111111111d0009900d1111d000000d1d000000000000000000000000d1d000000d1111d0099000d11111111111111111111100000000
00000000ddddddddddddddddddddd000099000dddd0000000d1d000000000000000000000000d1d0000000dddd000990000ddddddddddddddddddddd00000000
0000000000000000000000000000000002200000000000000d1d000000000000000000000000d1d0000000000000022000000000000000000000000000000000
0000000000000000000000000000000000000000000000000d1d000000000000000000000000d1d0000000000000000000000000000000000000000000000000
0000000000000000000000000000000009900000000000000d1d000000000000000000000000d1d0000000000000099000000000000000000000000000000000
0000000000000000000000000000000009900000000000000d1d000000000000000000000000d1d0000000000000099000000000000000000000000000000000
0000000000000000000000000000000002200000000000000d1d000000000000000000000000d1d0000000000000022000000000000000000000000000000000
0000000000000000000000000000000000000000000000000d1d000000000000000000000000d1d0000000000000000000000000000000000000000000000000
00000000ddddddddddddddddddddd000099000dddd0000000d1d000000000000000000000000d1d0000000dddd000990000ddddddddddddddddddddd00000000
00000000111111111111111111111d0009900d1111d000000d1d000000000000000000000000d1d000000d1111d0099000d11111111111111111111100000000
00000000dddddddddddddddddddd11d002200d1111d000000d1d000000000000000000000000d1d000000d1111d002200d11dddddddddddddddddddd00000000
0000000000000000000000000000d1d000000d1111d000000d1dddddddddddddddddddddddddd1d000000d1111d000000d1d0000000000000000000000000000
0000000000000000000000000000d1d009900d1111d000000d1111111111111111111111111111d000000d1111d009900d1d0000000000000000000000000000
0000000000000000000000000000d1d009900d1111d000000dddddddddddddddddddddddddddddd000000d1111d009900d1d0000000000000000000000000000
0000000000000000000000000000d1d002200d1111d000000000000000000000000000000000000000000d1111d002200d1d0000000000000000000000000000
0000000000000000000000000000d1d000000d1111d000000000000000000000000000000000000000000d1111d000000d1d0000000000000000000000000000
0000000000000000000000000000d1d009900d1111d000000000000000000000000000000000000000000d1111d009900d1d0000000000000000000000000000
0000000000000000000000000000d1d009900d1111d000000000000000000000000000000000000000000d1111d009900d1d0000000000000000000000000000
0000000000000000000000000000d1d002200d1111d000000000000000000000000000000000000000000d1111d002200d1d0000000000000000000000000000
0000000000000000000000000000d1d000000d1111d000000000000000000000000000000000000000000d1111d000000d1d0000000000000000000000000000
0000000000000000000000000000d1d009900d1111d0000000dddddddddddddddddddddddddddd0000000d1111d009900d1d0000000000000000000000000000
0000000000000000000000000000d1d009900d1111d000000d1111111111111111111111111111d000000d1111d009900d1d0000000000000000000000000000
0000000000000000000000000000d1d002200d1111d000000d1111111111111111111111111111d000000d1111d002200d1d0000000000000000000000000000
0000000000dddddddddddddddddd11d000000d1111d000000d1111111111111111111111111111d000000d1111d000000d11dddddddddddddddddd0000000000
000000000d1111111111111111111d0009900d1111d000000d1111111111111111111111111111d000000d1111d0099000d1111111111111111111d000000000
00000000d11dddddddddddddddddd000099000dddd00000000ddddddddddd111111ddddddddddd00000000dddd000990000dddddddddddddddddd11d00000000
00000000d1d00000000000000000000002200000000000000000000000000d1111d00000000000000000000000000220000000000000000000000d1d00000000
00000000d1d00000000000000000000000000000000000000000000000000d1111d00000000000000000000000000000000000000000000000000d1d00000000
00000000d1d00990099009900990099009900990099009900990099009900d1111d00990099009900990099009900990099009900990099009900d1d00000000
00000000d1d00990099009900990099009900990099009900990099009900d1111d00990099009900990099009900990099009900990099009900d1d00000000
00000000d1d00220022002200220022002200220022002200220022002200d1111d00220022002200220022002200220022002200220022002200d1d00000000
00000000d1d00000000000000000000000000000000000000000000000000d1111d00000000000000000000000000000000000000000000000000d1d00000000
00000000d1d0099000dddddddddddd00099000dddddddddddddddd0009900d1111d0099000dddddddddddddddd00099000dddddddddddd0009900d1d00000000
00000000d1d009900d111111111111d009900d1111111111111111d009900d1111d009900d1111111111111111d009900d111111111111d009900d1d00000000
00000000d1d002200d111111111111d002200d1111111111111111d002200d1111d002200d1111111111111111d002200d111111111111d002200d1d00000000
00000000d1d000000d111111111111d000000d1111111111111111d000000d1111d000000d1111111111111111d000000d111111111111d000000d1d00000000
00000000d1d009900d111111111111d009900d1111111111111111d009900d1111d009900d1111111111111111d009900d111111111111d009900d1d00000000
00000000d1d0099000ddddddd11111d0099000dddddddddddddddd00099000dddd00099000dddddddddddddddd0009900d11111ddddddd0009900d1d00000000
00000000d1d00220000000000d1111d0022000000000000000000000022000aaaa0002200000000000000000000002200d1111d00000000002200d1d00000000
00000000d1d00cc0000000000d1111d000000000000000000000000000000aaaaaa000000000000000000000000000000d1111d0000000000cc00d1d00000000
00000000d1d0cccc099009900d1111d009900990099009900990099009900aaaaaa009900990099009900990099009900d1111d009900990cccc0d1d00000000
00000000d1d0cccc099009900d1111d009900990099009900990099009900aaaaaa009900990099009900990099009900d1111d009900990cccc0d1d00000000
00000000d1d01cc1022002200d1111d002200220022002200220022002200aaaaaa002200220022002200220022002200d1111d0022002201cc10d1d00000000
00000000d1d00110000000000d1111d0000000000000000000000000000000aaaa0000000000000000000000000000000d1111d00000000001100d1d00000000
00000000d11ddddddd0009900d1111d0099000dddd00099000dddddddddddddddddddddddddddd00099000dddd0009900d1111d0099000ddddddd11d00000000
00000000d111111111d009900d1111d009900d1111d009900d1111111111111111111111111111d009900d1111d009900d1111d009900d111111111d00000000
00000000d111111111d002200d1111d002200d1111d002200d1111111111111111111111111111d002200d1111d002200d1111d002200d111111111d00000000
00000000d111111111d000000d1111d000000d1111d000000d1111111111111111111111111111d000000d1111d000000d1111d000000d111111111d00000000
00000000d111111111d009900d1111d009900d1111d009900d1111111111111111111111111111d009900d1111d009900d1111d009900d111111111d00000000
00000000d11ddddddd00099000dddd0009900d1111d0099000ddddddddddd111111ddddddddddd0009900d1111d0099000dddd00099000ddddddd11d00000000
00000000d1d00000000002200000000002200d1111d002200000000000000d1111d000000000000002200d1111d00220000000000220000000000d1d00000000
00000000d1d00000000000000000000000000d1111d000000000000000000d1111d000000000000000000d1111d00000000000000000000000000d1d00000000
00000000d1d00990099009900990099009900d1111d009900990099009900d1111d009900990099009900d1111d00990099009900990099009900d1d00000000
00000000d1d00990099009900990099009900d1111d009900990099009900d1111d009900990099009900d1111d00990099009900990099009900d1d00000000
00000000d1d00220022002200220022002200d1111d002200220022002200d1111d002200220022002200d1111d00220022002200220022002200d1d00000000
00000000d1d00000000000000000000000000d1111d000000000000000000d1111d000000000000000000d1111d00000000000000000000000000d1d00000000
00000000d1d0099000ddddddddddddddddddd111111ddddddddddd0009900d1111d0099000ddddddddddd111111ddddddddddddddddddd0009900d1d00000000
00000000d1d009900d111111111111111111111111111111111111d009900d1111d009900d111111111111111111111111111111111111d009900d1d00000000
00000000d1d002200d111111111111111111111111111111111111d002200d1111d002200d111111111111111111111111111111111111d002200d1d00000000
00000000d1d000000d111111111111111111111111111111111111d000000d1111d000000d111111111111111111111111111111111111d000000d1d00000000
00000000d1d009900d111111111111111111111111111111111111d009900d1111d009900d111111111111111111111111111111111111d009900d1d00000000
00000000d1d0099000dddddddddddddddddddddddddddddddddddd00099000dddd00099000dddddddddddddddddddddddddddddddddddd0009900d1d00000000
00000000d1d0022000000000000000000000000000000000000000000220000000000220000000000000000000000000000000000000000002200d1d00000000
00000000d1d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d1d00000000
00000000d1d0099009900990099009900990099009900990099009900990099009900990099009900990099009900990099009900990099009900d1d00000000
00000000d1d0099009900990099009900990099009900990099009900990099009900990099009900990099009900990099009900990099009900d1d00000000
00000000d1d0022002200220022002200220022002200220022002200220022002200220022002200220022002200220022002200220022002200d1d00000000
00000000d1d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d1d00000000
00000000d11dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd11d00000000
000000000d111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111d000000000
0000000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd0000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__map__
0040414141414174754141414141420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00504d4f5a4e4f6a6b4d4e5b4d4f520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0050555753565753545556545557520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
005064655a5b646e6f655a5b6465520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
006061596a6d476a6b456c6b5861620000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00c3c2c16a7d575354557c6bc0c2c40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
006363797a7b4972734a7a7b7863630000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0061615943446800006943445861610000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00c2c2c16a6b5c41415d6a6bc0c2c20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
006663797a7b646e6f657a7b7863670000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
005045474346476a6b4546444547520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0050555f53565753545556545e57520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00704c485a5b646e6f655a5b484b710000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
005045466c6d476a6b456c6d4647520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0050555656565753545556565657520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0076515151515151515151515151770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0002000017750197501a7401b7301e720227102b70008700107001f700217502274023740267302b7202f7102d70007700087000a7000c7000070000700007000070000700007000070000700007000070000700
000300001d1502115024150191501c1501f15024150281502c1501b1501d1501f1502315025150281502b1502f150301501f1502215025150291502c150301503315036150291002d10035100391003c1003f100
0005000035350383503c3503e3502c3502f35032350333501e3502235026350273501a3501d3501f350203500f3501135014350173500e3500c35009350073500135001300013000030000300003000030000300
000200001d570215701e570195002b5001f5001a57019570145701b5002f5001550015570155701457012570115700f5701f5003550025500295000e5700f5701357016570295002d5003d500395003c5003f500
000300000f5500f5500f5500f5500f55023500215001a500145000c5500c5500b5500a550095500a5000a5000c500075000655005550045500255001550045000150031500335003350034500355003550035500
