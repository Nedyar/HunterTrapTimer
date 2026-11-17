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
L["/htt test - show test traps"] = "/htt test - mostrar armadilhas de teste"
L["/htt clear - clear the countdown, should it go wrong"] = "/htt clear - apagar a contagem regressiva, caso dê errado"
L["countdown cleared."] = "contagem regressiva apagada."
L["there is no countdown to clear."] = "não há contagem regressiva para apagar."
L["/htt reset - restore the default settings"] = "/htt reset - restaurar as configurações padrão"
L["open the game menu, then Options > AddOns > Hunter Trap Timer."] = "abra o Menu do Jogo e depois Opções > AddOns > Hunter Trap Timer."

-- Icon
L["Drag to move, then /htt lock"] = "Arraste para mover e depois /htt lock"
L["Enemy frozen"] = "Inimigo congelado"
L["Burning"] = "Em chamas"
L["Ice on the ground"] = "Gelo no chão"
L["Fire on the ground"] = "Fogo no chão"

-- Options
L["Shows how long your traps stay armed: 60 seconds, unless something steps on them. WoW Forever hides the combat log from addons, but the game still tells them when your trap springs, however far away you are."] = "Mostra quanto tempo suas armadilhas continuam armadas: 60 segundos, a menos que algo pise nelas. O WoW Forever esconde o registro de combate dos addons, mas o jogo ainda avisa quando sua armadilha dispara, por mais longe que você esteja."
L["Icon"] = "Ícone"
L["Lock the icon"] = "Travar o ícone"
L["Unlocked, the icon stays on screen and can be dragged with the mouse."] = "Destravado, o ícone fica na tela e pode ser arrastado com o mouse."
L["Icon size"] = "Tamanho do ícone"
L["Position"] = "Posição"
L["Under the %s"] = "Abaixo da %s"
L["Under your portrait, clear of your pet's frame. It follows the %s when Edit Mode moves it."] = "Abaixo do seu retrato, sem cobrir a janela do seu ajudante. Acompanha a %s quando o Modo de edição a move."
L["Free"] = "Livre"
L["Where you drag it while the icon is unlocked."] = "Onde você o arrastar com o ícone destravado."
L["Shape"] = "Forma"
L["Round, like a totem"] = "Redondo, como um totem"
L["Square"] = "Quadrado"
L["Seconds"] = "Segundos"
L["Below the icon"] = "Abaixo do ícone"
L["On the icon"] = "Sobre o ícone"
L["Test"] = "Testar"
L["Shows a fire trap and a frost trap that run out in 20 and 15 seconds."] = "Mostra uma armadilha de fogo e uma de gelo que expiram em 20 e 15 segundos."
L["Reset position"] = "Redefinir posição"
L["Warning before it runs out"] = "Aviso antes de expirar"
L["Seconds left"] = "Segundos restantes"
L["Flash the icon"] = "Piscar o ícone"
L["After a trap springs"] = "Depois que uma armadilha dispara"
L["Show how long its effect lasts"] = "Mostrar quanto tempo dura o efeito"
L["The trap's icon stays and counts down its effect, however far away you are: Freezing Trap's freeze until the enemy breaks free, Immolation Trap's burn until the enemy it burns dies or you leave combat, and the fire of Explosive Trap and the ice of Frost Trap for their 20 and 30 seconds. Another of your buffs fading during a freeze ends it early, as the game does not tell them apart."] = "O ícone da armadilha fica e faz a contagem regressiva do efeito, por mais longe que você esteja: o congelamento da Armadilha Congelante até o inimigo se soltar, a queimadura da Armadilha de Imolação até o inimigo que ela queima morrer ou você sair de combate, e o fogo da Armadilha Explosiva e o gelo da Armadilha de Gelo durante os 20 e 30 segundos deles. Se outro dos seus bônus acabar durante um congelamento, ela termina antes, pois o jogo não os diferencia."
L["Off"] = "Desativado"
L["%d s"] = "%d s"

-- Sounds
L["Each trap's sounds are on the Sounds page, under this one."] = "Os sons de cada armadilha estão na página Sons, abaixo desta."
L["Sounds"] = "Sons"
L["Each trap's sounds: one as the warning before it runs out starts, one as its effect ends. Choosing a sound plays it."] = "Os sons de cada armadilha: um quando começa o aviso antes de expirar e outro quando o efeito acaba. Escolher um som o reproduz."
L["Before it runs out"] = "Antes de expirar"
L["When its effect ends"] = "Quando o efeito acaba"
L["None"] = "Nenhum"
L["Raid warning"] = "Aviso de raide"
L["Boss emote"] = "Emote de chefe"
L["Boss whisper"] = "Sussurro de chefe"
L["Ready check"] = "Verificação de prontidão"
L["Alarm clock %d"] = "Despertador %d"
L["Whisper"] = "Sussurro"
L["Notification"] = "Notificação"
