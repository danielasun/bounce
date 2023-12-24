-- bounce.lua
-- ball bounces around 
-- making tones when it hits walls
--

ball = {
  x=0, 
  y=0,
  vx=0,
  vy=0,
}

  
box = {xmin=0, ymin=0, xmax=128, ymax=64}
tones = {70, 90, 80, 75}
vmax = 5

-- menu params
index = 1
menu_items = {"cutoff", "release", "pw", "gain"}

params:add_control("cutoff","cutoff",controlspec.new(50,5000,'exp',0,555,'hz'))
params:set_action("cutoff", function(x) engine.cutoff(x) end)
params:add_control("release","release",controlspec.new(0.1,10,'exp',0.01,0.3,'s'))
params:set_action("release", function(x) engine.release(x) end)
params:add_control("pw","pw",controlspec.new(0.0,1.0,'lin', 0.01, 0.5,'%'))
params:set_action("pw", function(x) engine.pw(x) end)
params:add_control("gain","gain",controlspec.new(0.0,3.0,'lin', 0.01, 1.0,''))
params:set_action("gain", function(x) engine.gain(x) end)

  
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
  -- keep from going outside of the bounds
  next_pos = {
    x=ball.x + ball.vx,
    y=ball.y + ball.vy
  }
  if (next_pos.x < box.xmin) then
    ball.vx = -ball.vx
    engine.hz(midi_to_hz(tones[1]))
  else if(next_pos.x > box.xmax) then
    ball.vx = -ball.vx
    engine.hz(midi_to_hz(tones[2]))
  end
  end
  if (next_pos.y < box.ymin) then
    ball.vy = -ball.vy
    engine.hz(tones[3])
  else if (next_pos.y > box.ymax) then
    ball.vy = -ball.vy
    engine.hz(tones[4])
  end
  end
  
  -- update position
  ball.x = next_pos.x
  ball.y = next_pos.y
  redraw()
end


function redraw()
  screen.clear()
  
  -- ball
  screen.move(ball.x, ball.y)
  screen.circle(ball.x, ball.y, 4)
  screen.fill()
  
  -- status
  screen.move(0, 60)
  screen.text(string.format("x: %3d y: %3d", ball.x, ball.y)) 

  -- parameter that you're editing
  screen.move(125, 60)
  screen.text_right(string.format("%s: %5.2f", menu_items[index], params:get(menu_items[index])))

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
