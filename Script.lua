--[[
    Roblox Local Script - Menu Drag com Funções
    Criado por Manus
    
    Instruções de Uso:
    Este é um LocalScript. Ele deve ser injetado no jogo usando um executor (exploit)
    ou colocado em StarterPlayerScripts se você for o desenvolvedor do jogo.
    O ESP utiliza a API 'Drawing', comum em executores.
--]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui") -- Usar CoreGui para que o menu não seja afetado por resets de tela ou scripts de terceiros

-- Variáveis de Estado
local isESPEnabled = false
local currentSpeedValue = 16 -- Velocidade padrão do Roblox
local isJumpEnabled = false
local currentJumpValue = 50 -- JumpPower padrão do Roblox é 50

local isAutoClickerEnabled = false
local autoClickerConnection = nil
local currentCPS = 10 -- CPS padrão

-- Configurações do Menu
local menuWidth = 300
local menuHeight = 400
local minimizedSize = 50

-- ====================================================================================================
-- 1. Criação da GUI
-- ====================================================================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ManusMenuGUI"
ScreenGui.Parent = CoreGui -- Usar CoreGui para maior persistência

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainMenu"
MainFrame.Size = UDim2.new(0, menuWidth, 0, menuHeight)
MainFrame.Position = UDim2.new(0.5, -menuWidth/2, 0.5, -menuHeight/2) -- Centralizado
MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MainFrame.BorderColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true -- Essencial para o drag
MainFrame.Draggable = true -- Usar drag nativo do Roblox
MainFrame.Parent = ScreenGui

local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 30)
TitleBar.Position = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
TitleBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(1, -60, 1, 0)
TitleLabel.Position = UDim2.new(0, 0, 0, 0)
TitleLabel.BackgroundColor3 = Color3.new(0, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Manus Local Executor"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 18
TitleLabel.Parent = TitleBar

-- Botão de Minimizar
local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Name = "MinimizeButton"
MinimizeButton.Size = UDim2.new(0, 30, 0, 30)
MinimizeButton.Position = UDim2.new(1, -30, 0, 0)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
MinimizeButton.Text = "-"
MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeButton.Font = Enum.Font.SourceSansBold
MinimizeButton.TextSize = 24
MinimizeButton.Parent = TitleBar

-- Frame do Conteúdo
local ContentFrame = Instance.new("Frame")
ContentFrame.Name = "ContentFrame"
ContentFrame.Size = UDim2.new(1, 0, 1, -30)
ContentFrame.Position = UDim2.new(0, 0, 0, 30)
ContentFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ContentFrame.Parent = MainFrame

-- Bolinha Minimizada (Drag)
local MinimizedBall = Instance.new("TextButton")
MinimizedBall.Name = "MinimizedBall"
MinimizedBall.Size = UDim2.new(0, minimizedSize, 0, minimizedSize)
MinimizedBall.Position = UDim2.new(0.1, 0, 0.1, 0) -- Posição inicial
MinimizedBall.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
MinimizedBall.Text = "M"
MinimizedBall.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizedBall.Font = Enum.Font.SourceSansBold
MinimizedBall.TextSize = 30
-- MinimizedBall.CornerRadius = UDim.new(1, 0) -- REMOVIDO: CornerRadius não é membro direto de TextButton

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(1, 0) -- Transforma em bolinha
Corner.Parent = MinimizedBall
MinimizedBall.Active = true
MinimizedBall.Draggable = true -- Usar drag nativo do Roblox
MinimizedBall.Visible = false
MinimizedBall.Parent = ScreenGui

-- ====================================================================================================
-- 2. Funcionalidade de Drag (Arrastar)
-- ====================================================================================================

local dragStart = Vector2.new(0, 0)
local startPos = UDim2.new(0, 0, 0, 0)

-- Função para arrastar o menu principal
-- As funções startDrag e endDrag foram movidas para a seção de conexão para melhor controle de escopo e desconexão.
-- Apenas o drag da bolinha precisa ser corrigido.


local dragConnection

-- Drag do MainFrame agora é nativo (MainFr-- Drag do MainFrame agora é nativo (MainFrame.Draggable = true)
TitleBar.InputBegan:Connect(function(input)
    -- Apenas para garantir que o drag nativo seja ativado na TitleBar
    if input.UserInputType == Enum.UserInputType.MouseButton1 and not isMinimized then
        MainFrame.Draggable = true
    end
end)

-- Drag do MinimizedBall agora é nativo (MinimizedBall.Draggable = true)
MinimizedBall.InputBegan:Connect(function(input)
    -- Apenas para garantir que o drag nativo seja ativado
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        MinimizedBall.Draggable = true
    end
end)

-- ====================================================================================================
-- 3. Funcionalidade de Minimizar/Maximizar
-- ====================================================================================================

local function minimizeMenu()
    isMinimized = true
    MainFrame.Visible = false
    MinimizedBall.Visible = true
    -- Salva a posição do MainFrame para restaurar
    MinimizedBall:SetAttribute("LastPosition", MainFrame.Position)
    -- Move a bolinha para a posição do botão de minimizar (opcional, mas visualmente agradável)
    local absPos = MainFrame.AbsolutePosition + Vector2.new(MainFrame.AbsoluteSize.X - minimizedSize, 0)
    MinimizedBall.Position = UDim2.new(0, absPos.X, 0, absPos.Y)
end

local function maximizeMenu()
    isMinimized = false
    MainFrame.Visible = true
    MinimizedBall.Visible = false
    -- Restaura a posição do MainFrame
    local lastPos = MinimizedBall:GetAttribute("LastPosition")
    if lastPos then
        MainFrame.Position = lastPos
    end
end

MinimizeButton.MouseButton1Click:Connect(minimizeMenu)
MinimizedBall.MouseButton1Click:Connect(maximizeMenu)

-- ====================================================================================================
-- 4. Funções e Controles do Menu
-- ================================================================================================local function createToggle(parent, text, callback)
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Size = UDim2.new(1, -20, 0, 30)
    ToggleFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    ToggleFrame.Parent = parent   local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -40, 1, 0)
    Label.Position = UDim2.new(0, 0, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.Font = Enum.Font.SourceSans
    Label.TextSize = 16
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextWrapped = true
    Label.Parent = ToggleFrame

    local Button = Instance.new("TextButton")
    Button.Name = "Toggle"
    Button.Size = UDim2.new(0, 30, 0, 20)
    Button.Position = UDim2.new(1, -35, 0, 5)
    Button.BackgroundColor3 = Color3.fromRGB(150, 50, 50) -- Cor inicial: Desativado (Vermelho)
    Button.Text = "OFF"
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.Font = Enum.Font.SourceSansBold
    Button.TextSize = 14
    Button.Parent = ToggleFrame

    local isToggled = false
    Button.MouseButton1Click:Connect(function()
        isToggled = not isToggled
        if isToggled then
            Button.BackgroundColor3 = Color3.fromRGB(50, 150, 50) -- Ativado (Verde)
            Button.Text = "ON"
        else
            Button.BackgroundColor3 = Color3.fromRGB(150, 50, 50) -- Desativado (Vermelho)
            Button.Text = "OFF"
        end
        callback(isToggled)
    end)
    
    return Button, ToggleFrame
end

local function createTextBox(parent, text, initialValue, callback)
    local TextBoxFrame = Instance.new("Frame")
    TextBoxFrame.Size = UDim2.new(1, -20, 0, 30)
    TextBoxFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    TextBoxFrame.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.5, -5, 1, 0)
    Label.Position = UDim2.new(0, 0, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.Font = Enum.Font.SourceSans
    Label.TextSize = 16
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = TextBoxFrame

    local TextBox = Instance.new("TextBox")
    TextBox.Name = "InputBox"
    TextBox.Size = UDim2.new(0.5, -5, 0, 20)
    TextBox.Position = UDim2.new(0.5, 5, 0, 5)
    TextBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    TextBox.Text = initialValue
    TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    TextBox.TextSize = 16
    TextBox.TextXAlignment = Enum.TextXAlignment.Center
    TextBox.Font = Enum.Font.SourceSans
    TextBox.Parent = TextBoxFrame

    TextBox.FocusLost:Connect(function(enterPressed)
        local value = tonumber(TextBox.Text)
        local isJumpInput = string.find(text, "Jump")
        local isCPSInput = string.find(text, "CPS")
        local currentValue, minValue, maxValue

        if isJumpInput then
            currentValue = currentJumpValue
            minValue = 50
            maxValue = 500
        elseif isCPSInput then
            currentValue = currentCPS
            minValue = 1
            maxValue = 100 -- Limitar a 100 CPS para evitar problemas
        else -- Speed
            currentValue = currentSpeedValue
            minValue = 16
            maxValue = 500
        end

        if value and value >= minValue and value <= maxValue then
            callback(value)
        else
            -- Se o valor for inválido, reseta para o valor atual
            TextBox.Text = tostring(currentValue)
        end
    end)

    return TextBox, TextBoxFrame
end

-- ====================================================================================================
-- Implementação da Função Speed
-- ====================================================================================================

local function onSpeedChange(value)
    currentSpeedValue = value
    if isSpeedEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = value
    end
end

local function onSpeedToggle(isToggled)
    isSpeedEnabled = isToggled
    if isToggled then
        -- Aplica a velocidade atual imediatamente ao ativar
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = currentSpeedValue
        end
    else
        -- Reseta a velocidade para o valor padrão do jogo (16)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = 16
        end
    end
    return isToggled
end

-- Aplica a velocidade sempre que o personagem for carregado, se o speed estiver ativo
LocalPlayer.CharacterAdded:Connect(function(character)
    local humanoid = character:WaitForChild("Humanoid")
    if isSpeedEnabled then
        humanoid.WalkSpeed = currentSpeedValue
    end
end)

-- ====================================================================================================
-- Implementação da Função JumpPower (Altura de Pulo)
-- ====================================================================================================

local function onJumpChange(value)
    currentJumpValue = value
    if isJumpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.JumpPower = value
    end
end

local function onJumpToggle(isToggled)
    isJumpEnabled = isToggled
    if isToggled then
        -- Aplica o JumpPower atual imediatamente ao ativar
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.JumpPower = currentJumpValue
        end
    else
        -- Reseta o JumpPower para o valor padrão do jogo (50)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.JumpPower = 50
        end
    end
    return isToggled
end

-- Aplica o JumpPower sempre que o personagem for carregado, se o jump estiver ativo
LocalPlayer.CharacterAdded:Connect(function(character)
    local humanoid = character:WaitForChild("Humanoid")
    if isJumpEnabled then
        humanoid.JumpPower = currentJumpValue
    end
end)

-- Cria os controles de Speed
local speedToggle, speedFrame = createToggle(ContentFrame, "Ativar Speed Hack", onSpeedToggle)
local speedTextBox, speedTextBoxFrame = createTextBox(ContentFrame, "Valor do Speed", tostring(currentSpeedValue), onSpeedChange)

-- Cria os controles de JumpPower
local jumpToggle, jumpFrame = createToggle(ContentFrame, "Ativar Jump Hack", onJumpToggle)
local jumpTextBox, jumpTextBoxFrame = createTextBox(ContentFrame, "Valor do Jump", tostring(currentJumpValue), onJumpChange)

-- ====================================================================================================
-- Implementação da Função Auto-Clicker (Auto-Avanço)
-- ====================================================================================================

local lastClickTime = 0

local function onCPSChange(value)
    currentCPS = value
end

local function onAutoClickerToggle(isToggled)
    isAutoClickerEnabled = isToggled
    
    if isToggled then
        if not autoClickerConnection then
            autoClickerConnection = coroutine.create(function()
                while isAutoClickerEnabled do
                    local delay = 1 / currentCPS
                    pcall(function() 
                        -- Simula o clique do mouse. Usamos VirtualInputManager que é comum em exploits
                        game:GetService("VirtualInputManager"):SendMouseButtonEvent(0, 0, 0, true, game, 1) 
                        task.wait(0.01) -- Pequeno delay entre down e up
                        game:GetService("VirtualInputManager"):SendMouseButtonEvent(0, 0, 0, false, game, 1) 
                    end)
                    task.wait(delay)
                end
            end)
            coroutine.resume(autoClickerConnection)
        end
    else
        -- A flag 'isAutoClickerEnabled' vai parar o loop na próxima iteração
        autoClickerConnection = nil
    end
    return isToggled
end

-- Cria os controles de Auto-Clicker
local autoClickerToggle, autoClickerFrame = createToggle(ContentFrame, "Ativar Auto-Clicker", onAutoClickerToggle)
local cpsTextBox, cpsTextBoxFrame = createTextBox(ContentFrame, "CPS (Cliques/s)", tostring(currentCPS), onCPSChange)

-- ====================================================================================================
-- Implementação da Função ESP (Box Vermelha)
-- ====================================================================================================
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local espDrawings = {}
local espConnections = {}

local function cleanupESP()
    for _, draw in pairs(espDrawings) do
        if draw.box then draw.box:Remove() end
        if draw.line then draw.line:Remove() end
    end
    espDrawings = {}
end

local function isSameTeam(p1, p2)
    if p1.Team and p2.Team then
        return p1.Team == p2.Team
    end
    return false
end

local function updateESP()
    if not isESPEnabled then
        for _, draw in pairs(espDrawings) do
            if draw.box then draw.box.Visible = false end
            if draw.line then draw.line.Visible = false end
        end
        return
    end

    local idx = 1
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChildOfClass("Humanoid") and player.Character:FindFirstChildOfClass("Humanoid").Health > 0 and not isSameTeam(LocalPlayer, player) then
            
            local rootPart = player.Character.HumanoidRootPart
            local head = player.Character:FindFirstChild("Head")
            local humanoid = player.Character:FindFirstChild("Humanoid")

            if rootPart and head and humanoid then
                -- O ESP de baixo nível (Drawing) é mais robusto
                
                if not espDrawings[idx] then
                    espDrawings[idx] = {
                        box = Drawing.new("Square"),
                        line = Drawing.new("Line")
                    }
                    espDrawings[idx].box.Thickness = 2
                    espDrawings[idx].box.Filled = false
                    espDrawings[idx].line.Thickness = 2
                    espDrawings[idx].line.Color = Color3.fromRGB(255, 0, 0) -- Linha vermelha
                    espDrawings[idx].box.Color = Color3.fromRGB(255, 0, 0) -- Caixa vermelha
                end
                
                local draw = espDrawings[idx]

                -- Ponto do pé (aproximado) e ponto da cabeça
                local rootPoint, rootVisible = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, humanoid.HipHeight, 0))
                local headPoint, headVisible = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, head.Size.Y / 2, 0))

                if rootVisible and headVisible then
                    local boxHeight = math.abs(headPoint.Y - rootPoint.Y)
                    local boxWidth = boxHeight / 2.5 -- Proporção típica de um corpo

                    local boxX = rootPoint.X - boxWidth / 2
                    local boxY = headPoint.Y

                    draw.box.Size = Vector2.new(boxWidth, boxHeight)
                    draw.box.Position = Vector2.new(boxX, boxY)
                    draw.box.Visible = true

                    -- Snapline (linha do centro da tela para o jogador)
                    draw.line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y) -- Base da tela
                    draw.line.To = Vector2.new(rootPoint.X, rootPoint.Y)
                    draw.line.Visible = true
                    
                    idx = idx + 1
                else
                    draw.box.Visible = false
                    draw.line.Visible = false
                end
            end
        end
    end
    
    -- Esconde desenhos de jogadores que saíram
    for i=idx, #espDrawings do
        if espDrawings[i].box then espDrawings[i].box.Visible = false end
        if espDrawings[i].line then espDrawings[i].line.Visible = false end
    end
end

local function onESPToggle(isToggled)
    isESPEnabled = isToggled
    if isToggled then
        -- Conecta a função de atualização ao RenderStepped para rodar a cada frame
        espConnections.RenderStepped = RunService.RenderStepped:Connect(updateESP)
    else
        -- Desconecta e remove todas as caixas
        if espConnections.RenderStepped then
            espConnections.RenderStepped:Disconnect()
            espConnections.RenderStepped = nil
        end
        cleanupESP()
    end
end

-- Cria o controle de ESP
local espToggle, espFrame = createToggle(ContentFrame, "Ativar ESP (Box Vermelha)", onESPToggle)

-- ====================================================================================================
-- 5. Limpeza e Finalização
-- ====================================================================================================

-- Garante que o menu seja destruído quando o jogador sair (importante para scripts injetados)
-- O GameProcessedEvent não é um Service válido em todos os contextos.
-- Usaremos o CharacterRemoving como alternativa para limpeza.
LocalPlayer.CharacterRemoving:Connect(function()
    if ScreenGui.Parent == CoreGui then
        ScreenGui:Destroy()
        cleanupESP() -- Limpa os desenhos do ESP ao sair/resetar
    end
end)

-- Função para garantir que o ESP funcione em novos jogadores
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        if isESPEnabled then
            -- Força uma atualização para criar a caixa no novo personagem
            updateESP()
        end
    end)
end)

-- Força uma atualização inicial do ESP para jogadores já no servidor
for _, player in ipairs(Players:GetPlayers()) do
    if player.Character then
        player.CharacterAdded:Connect(function(character)
            if isESPEnabled then
                updateESP()
            end
        end)
    end
end

-- Adiciona um UIListLayout para organizar os itens do ContentFrame
local ListLayout = Instance.new("UIListLayout")
ListLayout.Parent = ContentFrame
ListLayout.Padding = UDim.new(0, 10)
ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Ajusta a posição dos frames para o ListLayout
speedFrame.LayoutOrder = 1
speedTextBoxFrame.LayoutOrder = 2
jumpFrame.LayoutOrder = 3
jumpTextBoxFrame.LayoutOrder = 4
autoClickerFrame.LayoutOrder = 5
cpsTextBoxFrame.LayoutOrder = 6
espFrame.LayoutOrder = 7

-- Aplica o valor inicial do speed
onSpeedChange(currentSpeedValue)

print("Manus Local Executor Menu Loaded.")
