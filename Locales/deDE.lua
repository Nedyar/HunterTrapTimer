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
L["/htt test - show test traps"] = "/htt test - Testfallen zeigen"
L["/htt clear - clear the countdown, should it go wrong"] = "/htt clear - den Countdown löschen, falls er falsch läuft"
L["countdown cleared."] = "Countdown gelöscht."
L["there is no countdown to clear."] = "es gibt keinen Countdown zum Löschen."
L["/htt reset - restore the default settings"] = "/htt reset - die Standardeinstellungen wiederherstellen"
L["open the game menu, then Options > AddOns > Hunter Trap Timer."] = "öffne das Spielmenü, dann Optionen > Addons > Hunter Trap Timer."

-- Icon
L["Drag to move, then /htt lock"] = "Zum Verschieben ziehen, dann /htt lock"
L["Enemy frozen"] = "Gegner eingefroren"
L["Burning"] = "Brennt"
L["Ice on the ground"] = "Eis am Boden"
L["Fire on the ground"] = "Feuer am Boden"

-- Options
L["Shows how long your traps stay armed: 60 seconds, unless something steps on them. WoW Forever hides the combat log from addons, but the game still tells them when your trap springs, however far away you are."] = "Zeigt, wie lange deine Fallen scharf bleiben: 60 Sekunden, sofern nichts hineintritt. WoW Forever verbirgt das Kampflog vor Addons, doch das Spiel meldet ihnen trotzdem, wenn deine Falle auslöst, egal wie weit du entfernt bist."
L["Icon"] = "Symbol"
L["Lock the icon"] = "Symbol sperren"
L["Unlocked, the icon stays on screen and can be dragged with the mouse."] = "Entsperrt bleibt das Symbol auf dem Bildschirm und lässt sich mit der Maus verschieben."
L["Icon size"] = "Symbolgröße"
L["Position"] = "Position"
L["Under the %s"] = "Unter dem %s"
L["Under your portrait, clear of your pet's frame. It follows the %s when Edit Mode moves it."] = "Unter deinem Porträt, ohne das Fenster deines Begleiters zu verdecken. Es folgt dem %s, wenn der Bearbeitungsmodus es verschiebt."
L["Free"] = "Frei"
L["Where you drag it while the icon is unlocked."] = "Wohin du es ziehst, solange das Symbol entsperrt ist."
L["Shape"] = "Form"
L["Round, like a totem"] = "Rund, wie ein Totem"
L["Square"] = "Eckig"
L["Seconds"] = "Sekunden"
L["Below the icon"] = "Unter dem Symbol"
L["On the icon"] = "Auf dem Symbol"
L["Test"] = "Testen"
L["Shows a fire trap and a frost trap that run out in 20 and 15 seconds."] = "Zeigt eine Feuer- und eine Frostfalle, die nach 20 und 15 Sekunden ablaufen."
L["Reset position"] = "Position zurücksetzen"
L["Warning before it runs out"] = "Warnung, bevor sie abläuft"
L["Seconds left"] = "Verbleibende Sekunden"
L["Flash the icon"] = "Symbol blinken lassen"
L["After a trap springs"] = "Nachdem eine Falle ausgelöst hat"
L["Show how long its effect lasts"] = "Zeigen, wie lange ihre Wirkung anhält"
L["The trap's icon stays and counts down its effect, however far away you are: Freezing Trap's freeze until the enemy breaks free, Immolation Trap's burn until the enemy it burns dies or you leave combat, and the fire of Explosive Trap and the ice of Frost Trap for their 20 and 30 seconds. Another of your buffs fading during a freeze ends it early, as the game does not tell them apart."] = "Das Symbol der Falle bleibt stehen und zählt ihre Wirkung herunter, egal wie weit du entfernt bist: das Einfrieren der Eiskältefalle, bis der Gegner sich befreit, das Brennen der Feuerbrandfalle, bis der brennende Gegner stirbt oder du den Kampf verlässt, und das Feuer der Sprengfalle und das Eis der Frostfalle für ihre 20 und 30 Sekunden. Läuft während eines Einfrierens ein anderer deiner Stärkungszauber aus, endet es früher, da das Spiel sie nicht unterscheidet."
L["Off"] = "Aus"
L["%d s"] = "%d s"

-- Sounds
L["Each trap's sounds are on the Sounds page, under this one."] = "Die Töne jeder Falle stehen auf der Seite „Töne“ unter dieser."
L["Sounds"] = "Töne"
L["Each trap's sounds: one as the warning before it runs out starts, one as its effect runs out, and one if the enemy breaks free or dies before then. Choosing a sound plays it."] = "Die Töne jeder Falle: einer, wenn die Warnung vor ihrem Ablauf beginnt, einer, wenn ihre Wirkung ausläuft, und einer, wenn sich der Gegner vorher befreit oder stirbt. Die Auswahl eines Tons spielt ihn ab."
L["Before it runs out"] = "Bevor sie abläuft"
L["When its effect runs out"] = "Wenn ihre Wirkung ausläuft"
L["If it ends early"] = "Wenn sie vorher endet"
L["None"] = "Keiner"
L["Raid warning"] = "Schlachtzugswarnung"
L["Boss emote"] = "Boss-Emote"
L["Boss whisper"] = "Boss-Flüstern"
L["Ready check"] = "Bereitschaftscheck"
L["Alarm clock %d"] = "Wecker %d"
L["Whisper"] = "Flüstern"
L["Notification"] = "Benachrichtigung"
