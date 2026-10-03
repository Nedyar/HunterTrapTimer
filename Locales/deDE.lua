-- Deutsch
local _, ns = ...
if ns.LOCALE ~= "deDE" then
    return
end
local L = ns.L

-- Chat
L["icon unlocked: drag it where you want it, then /htt lock."] = "Symbol entsperrt: Ziehe es an die gewünschte Stelle, dann /htt lock."
L["icon locked."] = "Symbol gesperrt."
L["settings reset to the defaults."] = "Einstellungen auf die Standardwerte zurückgesetzt."
L["/htt - open the options"] = "/htt - Optionen öffnen"
L["/htt unlock, /htt lock - move the icon"] = "/htt unlock, /htt lock - das Symbol verschieben"
L["/htt test - show a test trap"] = "/htt test - eine Testfalle zeigen"
L["/htt reset - restore the default settings"] = "/htt reset - die Standardeinstellungen wiederherstellen"
L["open the game menu, then Options > AddOns > Hunter Trap Timer."] = "öffne das Spielmenü, dann Optionen > Addons > Hunter Trap Timer."

-- Icon
L["Drag to move, then /htt lock"] = "Zum Verschieben ziehen, dann /htt lock"

-- Options
L["Shows how long your trap stays armed: 60 seconds, unless something steps on it. WoW Forever hides the combat log from addons, and enemy auras in combat, so a trap that springs is recognized by a new aura on an enemy that nothing else explains. In a group other players' auras could be taken for it, so there the countdown runs to its end."] = "Zeigt, wie lange deine Falle scharf bleibt: 60 Sekunden, sofern nichts hineintritt. WoW Forever verbirgt das Kampflog vor Addons und im Kampf auch die Auren der Gegner. Eine ausgelöste Falle wird daher an einer neuen Aura auf einem Gegner erkannt, die sonst nichts erklärt. In einer Gruppe könnten Auren anderer Spieler dafür gehalten werden, deshalb läuft der Countdown dort bis zum Ende."
L["Icon"] = "Symbol"
L["Lock the icon"] = "Symbol sperren"
L["Unlocked, the icon stays on screen and can be dragged with the mouse."] = "Entsperrt bleibt das Symbol auf dem Bildschirm und lässt sich mit der Maus verschieben."
L["Icon size"] = "Symbolgröße"
L["Count down the effect once the trap springs"] = "Wirkung herunterzählen, sobald die Falle auslöst"
L["The icon turns green and counts down the effect on the enemy, such as the freeze of %s. It ends early if the enemy dies, and a freeze also if the enemy takes damage."] = "Das Symbol wird grün und zählt die Wirkung auf dem Gegner herunter, etwa das Einfrieren durch %s. Sie endet vorzeitig, wenn der Gegner stirbt, ein Einfrieren auch, wenn der Gegner Schaden erleidet."
L["Test"] = "Testen"
L["Shows a trap that runs out in 15 seconds."] = "Zeigt eine Falle, die nach 15 Sekunden abläuft."
L["Reset position"] = "Position zurücksetzen"
L["Warning before it runs out"] = "Warnung, bevor sie abläuft"
L["Seconds left"] = "Verbleibende Sekunden"
L["Flash the icon"] = "Symbol blinken lassen"
L["Play a sound"] = "Einen Ton abspielen"
L["Off"] = "Aus"
L["%d s"] = "%d s"
