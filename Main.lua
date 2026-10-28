-- EPIC PLANETS - Tetris standalone add-on
-- Delta / Android | No external library or remote Main.lua required.
-- This is a self-contained Tetris GUI. It does not contain the full EPIC PLANETS hub.
local ENV = (type(getgenv) == "function" and getgenv()) or _G
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
if not player then error("Tetris: LocalPlayer unavailable") end
local playerGui = player:WaitForChild("PlayerGui")
if ENV.__EP_TETRIS_GUI then pcall(function() ENV.__EP_TETRIS_GUI:Destroy() end) end
if ENV.__EP_TETRIS_CONNECTIONS then
    for _, c in ipairs(ENV.__EP_TETRIS_CONNECTIONS) do pcall(function() c:Disconnect() end) end
end
local connections = {}
ENV.__EP_TETRIS_CONNECTIONS = connections
local function connect(signal, fn) local c = signal:Connect(fn); table.insert(connections, c); return c end
local function make(className, props, parent)
    local o = Instance.new(className)
    for k,v in pairs(props or {}) do o[k] = v end
    o.Parent = parent
    return o
end
local function corner(o, r) make("UICorner", {CornerRadius=UDim.new(0,r or 7)}, o) end
local function stroke(o, color)
    make("UIStroke", {Color=color or Color3.fromRGB(55,145,255), Thickness=1, Transparency=0.25}, o)
end
local bg = Color3.fromRGB(8,8,11)
local panel = Color3.fromRGB(17,17,22)
local alt = Color3.fromRGB(26,26,33)
local white = Color3.fromRGB(240,240,245)
local blue = Color3.fromRGB(55,145,255)
local gui = make("ScreenGui", {Name="EPIC_PLANETS_TETRIS", ResetOnSpawn=false, IgnoreGuiInset=true, DisplayOrder=1001}, playerGui)
ENV.__EP_TETRIS_GUI = gui
local window = make("Frame", {AnchorPoint=Vector2.new(.5,.5), Position=UDim2.fromScale(.5,.5), Size=UDim2.new(0.94,0,0.86,0), BackgroundColor3=panel, BorderSizePixel=0}, gui)
corner(window, 12); stroke(window, blue)
local sizeLimit = make("UISizeConstraint", {MinSize=Vector2.new(300,390), MaxSize=Vector2.new(500,650)}, window)
local title = make("TextLabel", {Position=UDim2.new(0,12,0,7), Size=UDim2.new(1,-54,0,30), BackgroundTransparency=1, Text="EPIC PLANETS  /  TETRIS", TextColor3=white, TextSize=16, Font=Enum.Font.GothamBlack, TextXAlignment=Enum.TextXAlignment.Left}, window)
local close = make("TextButton", {Position=UDim2.new(1,-39,0,7), Size=UDim2.fromOffset(29,29), BackgroundColor3=alt, BorderSizePixel=0, Text="×", TextColor3=white, TextSize=20, Font=Enum.Font.GothamBold}, window); corner(close,6)
local boardFrame = make("Frame", {Position=UDim2.new(0,12,0,45), Size=UDim2.new(0,164,0,324), BackgroundColor3=bg, BorderSizePixel=0, ClipsDescendants=true}, window); corner(boardFrame,6); stroke(boardFrame,blue)
local info = make("TextLabel", {Position=UDim2.new(0,188,0,48), Size=UDim2.new(1,-200,0,78), BackgroundTransparency=1, Text="Score: 0\nLines: 0\nLevel: 1", TextColor3=white, TextSize=13, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left, TextYAlignment=Enum.TextYAlignment.Top}, window)
local message = make("TextLabel", {Position=UDim2.new(0,188,0,125), Size=UDim2.new(1,-200,0,56), BackgroundTransparency=1, Text="Press START", TextColor3=Color3.fromRGB(157,157,170), TextSize=11, Font=Enum.Font.Gotham, TextWrapped=true, TextXAlignment=Enum.TextXAlignment.Left, TextYAlignment=Enum.TextYAlignment.Top}, window)
local W,H,CELL = 10,20,16
local shapes = {
 I={{0,1},{1,1},{2,1},{3,1}}, O={{1,0},{2,0},{1,1},{2,1}},
 T={{1,0},{0,1},{1,1},{2,1}}, S={{1,0},{2,0},{0,1},{1,1}},
 Z={{0,0},{1,0},{1,1},{2,1}}, J={{0,0},{0,1},{1,1},{2,1}}, L={{2,0},{0,1},{1,1},{2,1}},
}
local colors = {I=Color3.fromRGB(65,220,255),O=Color3.fromRGB(255,215,65),T=Color3.fromRGB(180,90,255),S=Color3.fromRGB(80,235,125),Z=Color3.fromRGB(255,85,100),J=Color3.fromRGB(70,120,255),L=Color3.fromRGB(255,155,65)}
local names={"I","O","T","S","Z","J","L"}
local board, cells = {}, {}
local active, score, lines, level = nil,0,0,1
local running, paused, gameOver = false,false,false
local accumulator=0
local function blankBoard()
 board={}; for y=1,H do board[y]={}; for x=1,W do board[y][x]=false end end
end
local function cellsFor(piece)
 local out={}; for _,p in ipairs(piece.shape) do table.insert(out,{x=piece.x+p[1],y=piece.y+p[2]}) end; return out
end
local function collides(piece, dx, dy, rotated)
 local shape=rotated or piece.shape
 for _,p in ipairs(shape) do
  local x=piece.x+p[1]+(dx or 0); local y=piece.y+p[2]+(dy or 0)
  if x<0 or x>=W or y>=H then return true end
  if y>=0 and board[y+1][x+1] then return true end
 end
 return false
end
local function rotateShape(shape)
 local out={}; for _,p in ipairs(shape) do table.insert(out,{-p[2],p[1]}) end
 local minX,minY=999,999; for _,p in ipairs(out) do minX=math.min(minX,p[1]); minY=math.min(minY,p[2]) end
 for _,p in ipairs(out) do p[1]=p[1]-minX; p[2]=p[2]-minY end
 return out
end
local function spawn()
 local name=names[math.random(1,#names)]
 active={name=name,shape=shapes[name],x=3,y=0}
 if collides(active,0,0) then gameOver=true; running=false; message.Text="GAME OVER\nTap RESTART to play again." end
end
local function drawBoard()
 for _,v in pairs(cells) do if v and v.Parent then v:Destroy() end end
 cells={}
 for y=0,H-1 do for x=0,W-1 do
  local color=board[y+1][x+1]
  if color then
   local c=make("Frame",{Position=UDim2.fromOffset(3+x*16,3+y*16),Size=UDim2.fromOffset(14,14),BackgroundColor3=color,BorderSizePixel=0},boardFrame); corner(c,3); table.insert(cells,c)
  end
 end end
 if active and not gameOver then
  for _,p in ipairs(cellsFor(active)) do
   if p.y>=0 and p.y<H and p.x>=0 and p.x<W then
    local c=make("Frame",{Position=UDim2.fromOffset(3+p.x*16,3+p.y*16),Size=UDim2.fromOffset(14,14),BackgroundColor3=colors[active.name],BorderSizePixel=0},boardFrame); corner(c,3); table.insert(cells,c)
   end
  end
 end
 info.Text="Score: "..score.."\nLines: "..lines.."\nLevel: "..level
end
local function lockPiece()
 for _,p in ipairs(cellsFor(active)) do if p.y>=0 and p.y<H and p.x>=0 and p.x<W then board[p.y+1][p.x+1]=colors[active.name] end end
 local cleared=0
 for y=H,1,-1 do
  local full=true; for x=1,W do if not board[y][x] then full=false; break end end
  if full then table.remove(board,y); local row={}; for x=1,W do row[x]=false end; table.insert(board,1,row); cleared=cleared+1; y=y+1 end
 end
 if cleared>0 then lines=lines+cleared; score=score+({[1]=100,[2]=300,[3]=500,[4]=800})[cleared]*level; level=math.floor(lines/10)+1 end
 spawn()
end
local function stepDown()
 if not active or gameOver then return end
 if not collides(active,0,1) then active.y=active.y+1 else lockPiece() end
 drawBoard()
end
local function move(dx)
 if running and not paused and active and not collides(active,dx,0) then active.x=active.x+dx; drawBoard() end
end
local function rotate()
 if not (running and not paused and active) then return end
 local shape=rotateShape(active.shape)
 if not collides(active,0,0,shape) then active.shape=shape; drawBoard() end
end
local function drop()
 if not (running and not paused and active) then return end
 while not collides(active,0,1) do active.y=active.y+1; score=score+2 end
 lockPiece(); drawBoard()
end
local function startGame()
 blankBoard(); active=nil; score=0; lines=0; level=1; gameOver=false; paused=false; running=true; accumulator=0; message.Text="Playing. Use touch controls below."; spawn(); drawBoard()
end
local function button(text, x, y, w, callback)
 local b=make("TextButton",{Position=UDim2.new(x,0,y,0),Size=UDim2.new(w,0,0,38),BackgroundColor3=alt,BorderSizePixel=0,Text=text,TextColor3=white,TextSize=11,Font=Enum.Font.GothamBold},window); corner(b,7); stroke(b,Color3.fromRGB(55,145,255)); connect(b.Activated,callback); return b
end
local controlsY=385
button("◀ LEFT",0.04,controlsY,0.28,function() move(-1) end)
button("ROTATE ↻",0.36,controlsY,0.28,rotate)
button("RIGHT ▶",0.68,controlsY,0.28,function() move(1) end)
button("▼ DOWN",0.04,controlsY+45,0.28,stepDown)
button("DROP ⤓",0.36,controlsY+45,0.28,drop)
button("PAUSE",0.68,controlsY+45,0.28,function() if running and not gameOver then paused=not paused; message.Text=paused and "Paused" or "Playing" end end)
button("START / RESTART",0.04,controlsY+90,0.92,function() startGame() end)
connect(UserInputService.InputBegan,function(input,processed)
 if processed or UserInputService:GetFocusedTextBox() then return end
 if input.KeyCode==Enum.KeyCode.Left or input.KeyCode==Enum.KeyCode.A then move(-1)
 elseif input.KeyCode==Enum.KeyCode.Right or input.KeyCode==Enum.KeyCode.D then move(1)
 elseif input.KeyCode==Enum.KeyCode.Up or input.KeyCode==Enum.KeyCode.W then rotate()
 elseif input.KeyCode==Enum.KeyCode.Down or input.KeyCode==Enum.KeyCode.S then stepDown()
 elseif input.KeyCode==Enum.KeyCode.Space then drop()
 elseif input.KeyCode==Enum.KeyCode.P then paused=not paused end
end)
connect(RunService.Heartbeat,function(dt)
 if not running or paused or gameOver then return end
 accumulator=accumulator+dt
 local interval=math.max(0.08,0.72-(level-1)*0.055)
 if accumulator>=interval then accumulator=0; stepDown() end
end)
connect(close.Activated,function()
 running=false
 for _,c in ipairs(connections) do pcall(function() c:Disconnect() end) end
 pcall(function() gui:Destroy() end)
 ENV.__EP_TETRIS_GUI=nil; ENV.__EP_TETRIS_CONNECTIONS=nil
end)
blankBoard(); drawBoard()
message.Text="Standalone version: no library required. Tap START / RESTART."
