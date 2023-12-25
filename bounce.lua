-- bounce.lua
-- ball bounces around 
-- making tones when it hits walls
--

delay = include('lib/delay')
delay.init()


ball = {
  x=0, 
  y=0,
  vx=0,
  vy=0,
}
  
-- global parameters
vmax = 5
box = {xmin=0, ymin=0, xmax=128, ymax=64}

-- a reflection consists of a location (x,y) and an index. 
-- Increase the radius of the reflection each time to make a little splash 
-- that radiates outward and gradually fades away at each iteration.
reflections = {}


top_midi = 95
low_midi = 70
tones = {
  math.random(low_midi, top_midi), 
  math.random(low_midi, top_midi),
  math.random(low_midi, top_midi),
  math.random(low_midi, top_midi),
}  -- pick 4 random tones

-- menu params
index = 1
menu_labels = {"tape spd", "cut", "rel", "pw", "gain", "fdbk", }
menu_items = {"delay_rate", "cutoff", "release", "pw", "gain", "delay_feedback", }

params:add_control("cutoff","cutoff",controlspec.new(50,10000,'exp',0,555,'hz'))
params:set_action("cutoff", function(x) engine.cutoff(x) end)
params:add_control("release","release",controlspec.new(0.1,10,'exp',0.01,0.5,'s'))
params:set_action("release", function(x) engine.release(x) end)
params:add_control("pw","pw",controlspec.new(0.0,1.0,'lin', 0.01, 0.5,'%'))
params:set_action("pw", function(x) engine.pw(x) end)
params:add_control("gain","gain",controlspec.new(0.0,3.0,'lin', 0.01, 1.0,''))
params:set_action("gain", function(x) engine.gain(x) end)
time_of_last_menu_update = util.time()
menu_label_timeout = 1.5 -- [s]
pan_width = 0.5 -- number between 0 and 1 describing stereo width for the box

  
engine.name = "PolyPerc"

function init() 
  print("init")
  
  params:bang()

  screen.level(10)
  screen.aa(1)
  redraw()
  
  re = metro.init()
  re.time = 1.0 / 30
  re.event = function()
    update()
  end
  re:start()
  launch_ball(64, 32)
end

function update()
  local next_pos = {
    x=ball.x + ball.vx*params:get("delay_rate"),
    y=ball.y + ball.vy*params:get("delay_rate")
  }
  
  -- calculate bounces
  if (next_pos.x < box.xmin) then
    ball.vx = -ball.vx
    play_tone(1, next_pos.x)
    add_reflection(next_pos.x, next_pos.y)
  else if(next_pos.x > box.xmax) then
    ball.vx = -ball.vx
    play_tone(2, next_pos.x)
    add_reflection(next_pos.x, next_pos.y)
  end
  end
  if (next_pos.y < box.ymin) then
    ball.vy = -ball.vy
    play_tone(3, next_pos.x)
    add_reflection(next_pos.x, next_pos.y)
  else if (next_pos.y > box.ymax) then
    ball.vy = -ball.vy
    play_tone(4, next_pos.x)
    add_reflection(next_pos.x, next_pos.y)
  end
  end
  
  -- update position
  ball.x = next_pos.x
  ball.y = next_pos.y
  
  -- update reflections
  for i=1, #reflections do
    -- increase the size of the reflection each update
    reflections[i].radius = reflections[i].radius + 2*math.exp(-0.01*reflections[i].radius) 
  end
  
  -- remove reflection once they're so big they can't be seen.
  local n = #reflections
  for i=1, n do
    if reflections[i] ~= nil then
      if reflections[i].radius > 128 then
        table.remove(reflections, i)
      end
    end
  end

  redraw()
end


function redraw()
  screen.clear()
  screen.level(15)
  
  -- ball
  local x = math.floor(ball.x)
  local y = math.floor(ball.y)
  screen.move(x, y)
  screen.circle(x, y, 3)
  screen.fill()
  
  -- status
  screen.move(0, 60)
  screen.level(10)
  screen.text(string.format("% 3d,% 3d", x, y)) 
  
  -- parameter that you're editing, with menu timeout
  if util.time() - time_of_last_menu_update <= menu_label_timeout then
    screen.move(125, 60)
    screen.text_right(string.format("%s: %5.2f", menu_labels[index], params:get(menu_items[index])))
  end
  
  -- reflections
  for i=1,#reflections do
    local r = math.floor(reflections[i].radius)
    screen.circle(reflections[i].x, reflections[i].y, r)
    screen.level(math.floor((128-r)/128*10))
    screen.stroke()
    
  end
  

  screen.update()
end

function key(n, z)
  redraw()
  print(n .. ":".. z)
  if n == 2 and z == 1 then
    launch_ball()
  end
end

function enc(n, d)
  print(n .. ":".. d )
  if n == 2 then
    index = util.clamp(index + d, 1, #menu_items)
  else if n == 3 then
    params:delta(menu_items[index], d)
  end
  end
  time_of_last_menu_update = util.time()
end  

function play_tone(index, x)
  local pan = (x/box.xmax)*2*pan_width - pan_width
  engine.pan(pan)
  engine.hz(midi_to_hz(tones[index])*params:get("delay_rate"))
end

function add_reflection(x, y)
  table.insert(reflections, {x=x, y=y, radius=0.0})
end


function launch_ball(x, y)
  ball.x = x or math.random(0, 128)
  ball.y = y or math.random(0, 64)
  ball.vx = math.random(-vmax, vmax)
  ball.vy = math.random(-vmax, vmax)
  
end 

function midi_to_hz(note)
  local hz = (440 / 32) * (2 ^ ((note - 9) / 12))
  return hz
end
