-- Português (Brasil), also used by Portugal's client
local _, ns = ...
if ns.LOCALE ~= "ptBR" then
    return
end
local L = ns.L

-- Chat
L["icon unlocked: drag it where you want it, then /htt lock."] = "ícone destravado: arraste-o para onde quiser e depois /htt lock."
L["icon locked."] = "ícone travado."
L["settings reset to the defaults."] = "configurações restauradas para os valores padrão."
L["/htt - open the options"] = "/htt - abrir as opções"
L["/htt unlock, /htt lock - move the icon"] = "/htt unlock, /htt lock - mover o ícone"
L["/htt test - show a test trap"] = "/htt test - mostrar uma armadilha de teste"
L["/htt reset - restore the default settings"] = "/htt reset - restaurar as configurações padrão"
L["open the game menu, then Options > AddOns > Hunter Trap Timer."] = "abra o Menu do Jogo e depois Opções > AddOns > Hunter Trap Timer."

-- Icon
L["Drag to move, then /htt lock"] = "Arraste para mover e depois /htt lock"

-- Options
L["Shows how long your trap stays armed: 60 seconds, unless something steps on it. WoW Forever hides the combat log from addons, and enemy auras in combat, so a trap that springs is recognized by a new aura on an enemy that nothing else explains. In a group other players' auras could be taken for it, so there the countdown runs to its end."] = "Mostra por quanto tempo sua armadilha continua armada: 60 segundos, a menos que algo pise nela. WoW Forever esconde dos AddOns o registro de combate e, em combate, também as auras dos inimigos; por isso, uma armadilha que dispara é reconhecida por uma aura nova em um inimigo que nada mais explica. Em grupo, auras de outros jogadores poderiam ser confundidas com ela, então ali a contagem regressiva vai até o fim."
L["Icon"] = "Ícone"
L["Lock the icon"] = "Travar o ícone"
L["Unlocked, the icon stays on screen and can be dragged with the mouse."] = "Destravado, o ícone fica na tela e pode ser arrastado com o mouse."
L["Icon size"] = "Tamanho do ícone"
L["Count down the effect once the trap springs"] = "Contar o efeito quando a armadilha disparar"
L["The icon turns green and counts down the effect on the enemy, such as the freeze of %s. It ends early if the enemy dies, and a freeze also if the enemy takes damage."] = "O ícone fica verde e conta o efeito no inimigo, como o congelamento de %s. Ele termina antes se o inimigo morrer, e um congelamento também se o inimigo sofrer dano."
L["Test"] = "Testar"
L["Shows a trap that runs out in 15 seconds."] = "Mostra uma armadilha que expira em 15 segundos."
L["Reset position"] = "Redefinir posição"
L["Warning before it runs out"] = "Aviso antes de expirar"
L["Seconds left"] = "Segundos restantes"
L["Flash the icon"] = "Piscar o ícone"
L["Play a sound"] = "Tocar um som"
L["Off"] = "Desativado"
L["%d s"] = "%d s"
