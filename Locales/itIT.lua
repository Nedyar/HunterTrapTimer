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
L["/htt reset - restore the default settings"] = "/htt reset - ripristina le impostazioni predefinite"
L["open the game menu, then Options > AddOns > Hunter Trap Timer."] = "apri il menu di gioco, poi Opzioni > Add-on > Hunter Trap Timer."

-- Icon
L["Drag to move, then /htt lock"] = "Trascina per spostare, poi /htt lock"

-- Options
L["Shows how long your trap stays armed: 60 seconds, unless something steps on it. WoW Forever hides the combat log from addons, and enemy auras in combat, so a trap that springs is recognized by a new aura on an enemy that nothing else explains. In a group other players' auras could be taken for it, so there the countdown runs to its end."] = "Mostra per quanto tempo la tua trappola resta armata: 60 secondi, a meno che qualcosa non ci finisca sopra. WoW Forever nasconde agli add-on il registro di combattimento e, in combattimento, anche le aure dei nemici, quindi una trappola che scatta viene riconosciuta da una nuova aura su un nemico che nient'altro spiega. In gruppo le aure degli altri giocatori potrebbero essere scambiate per essa, quindi lì il conto alla rovescia arriva fino alla fine."
L["Icon"] = "Icona"
L["Lock the icon"] = "Blocca l'icona"
L["Unlocked, the icon stays on screen and can be dragged with the mouse."] = "Sbloccata, l'icona resta sullo schermo e si può trascinare con il mouse."
L["Icon size"] = "Dimensione dell'icona"
L["Count down the effect once the trap springs"] = "Conta l'effetto quando la trappola scatta"
L["The icon turns green and counts down the effect on the enemy, such as the freeze of %s. It ends early if the enemy dies, and a freeze also if the enemy takes damage."] = "L'icona diventa verde e conta l'effetto sul nemico, come il congelamento di %s. Finisce prima se il nemico muore, e un congelamento anche se il nemico subisce danni."
L["Test"] = "Prova"
L["Shows a trap that runs out in 15 seconds."] = "Mostra una trappola che scade tra 15 secondi."
L["Reset position"] = "Ripristina posizione"
L["Warning before it runs out"] = "Avviso prima della scadenza"
L["Seconds left"] = "Secondi rimanenti"
L["Flash the icon"] = "Fai lampeggiare l'icona"
L["Play a sound"] = "Riproduci un suono"
L["Off"] = "Disattivato"
L["%d s"] = "%d s"
