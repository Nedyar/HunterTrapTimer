-- Italiano
local _, ns = ...
if ns.LOCALE ~= "itIT" then
    return
end
local L = ns.L

-- Chat
L["icon unlocked: drag it where you want it, then /htt lock."] = "icona sbloccata: trascinala dove vuoi, poi /htt lock."
L["icon locked."] = "icona bloccata."
L["settings reset to the defaults."] = "impostazioni ripristinate ai valori predefiniti."
L["/htt - open the options"] = "/htt - apri le opzioni"
L["/htt unlock, /htt lock - move the icon"] = "/htt unlock, /htt lock - sposta l'icona"
L["/htt test - show a test trap"] = "/htt test - mostra una trappola di prova"
L["/htt clear - clear the countdown, should it go wrong"] = "/htt clear - cancella il conto alla rovescia, se va storto"
L["countdown cleared."] = "conto alla rovescia cancellato."
L["there is no countdown to clear."] = "non c'è nessun conto alla rovescia da cancellare."
L["/htt reset - restore the default settings"] = "/htt reset - ripristina le impostazioni predefinite"
L["open the game menu, then Options > AddOns > Hunter Trap Timer."] = "apri il menu di gioco, poi Opzioni > Add-on > Hunter Trap Timer."

-- Icon
L["Drag to move, then /htt lock"] = "Trascina per spostare, poi /htt lock"

-- Options
L["Shows how long your trap stays armed: 60 seconds, unless something steps on it. WoW Forever hides the combat log from addons, and enemy auras in combat, so a trap that springs is recognized by a new aura on an enemy that nothing else explains, such as a spell of yours, your pet's or your group's. In a group, an effect that comes without a spell, such as a poison, can now and then be taken for it."] = "Mostra per quanto tempo la tua trappola resta armata: 60 secondi, a meno che qualcosa non ci finisca sopra. WoW Forever nasconde agli add-on il registro di combattimento e, in combattimento, anche le aure dei nemici, quindi una trappola che scatta viene riconosciuta da una nuova aura su un nemico che nient'altro spiega, come un incantesimo tuo, del tuo famiglio o del tuo gruppo. In gruppo, un effetto arrivato senza incantesimo, come un veleno, può ogni tanto essere scambiato per essa."
L["Icon"] = "Icona"
L["Lock the icon"] = "Blocca l'icona"
L["Unlocked, the icon stays on screen and can be dragged with the mouse."] = "Sbloccata, l'icona resta sullo schermo e si può trascinare con il mouse."
L["Icon size"] = "Dimensione dell'icona"
L["Position"] = "Posizione"
L["Under the %s"] = "Sotto il %s"
L["Under your portrait, clear of your pet's frame. It follows the %s when Edit Mode moves it."] = "Sotto il tuo ritratto, senza coprire il riquadro del famiglio. Segue il %s quando la Modalità modifica lo sposta."
L["Free"] = "Libera"
L["Where you drag it while the icon is unlocked."] = "Dove la trascini quando l'icona è sbloccata."
L["Shape"] = "Forma"
L["Round, like a totem"] = "Rotonda, come un totem"
L["Square"] = "Quadrata"
L["Seconds"] = "Secondi"
L["Below the icon"] = "Sotto l'icona"
L["On the icon"] = "Sull'icona"
L["Test"] = "Prova"
L["Shows a trap that runs out in 15 seconds."] = "Mostra una trappola che scade tra 15 secondi."
L["Reset position"] = "Ripristina posizione"
L["Warning before it runs out"] = "Avviso prima della scadenza"
L["Seconds left"] = "Secondi rimanenti"
L["Flash the icon"] = "Fai lampeggiare l'icona"
L["Play a sound"] = "Riproduci un suono"
L["Off"] = "Disattivato"
L["%d s"] = "%d s"
