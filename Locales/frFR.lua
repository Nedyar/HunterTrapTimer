-- Français
local _, ns = ...
if ns.LOCALE ~= "frFR" then
    return
end
local L = ns.L

-- Chat
L["icon unlocked: drag it where you want it, then /htt lock."] = "icône déverrouillée : faites-la glisser où vous voulez, puis /htt lock."
L["icon locked."] = "icône verrouillée."
L["settings reset to the defaults."] = "paramètres réinitialisés aux valeurs par défaut."
L["/htt - open the options"] = "/htt - ouvrir les options"
L["/htt unlock, /htt lock - move the icon"] = "/htt unlock, /htt lock - déplacer l'icône"
L["/htt test - show a test trap"] = "/htt test - afficher un piège de test"
L["/htt clear - clear the countdown, should it go wrong"] = "/htt clear - effacer le compte à rebours, s'il se trompe"
L["countdown cleared."] = "compte à rebours effacé."
L["there is no countdown to clear."] = "il n'y a aucun compte à rebours à effacer."
L["/htt reset - restore the default settings"] = "/htt reset - rétablir les paramètres par défaut"
L["open the game menu, then Options > AddOns > Hunter Trap Timer."] = "ouvrez le menu de jeu, puis Options > Add-ons > Hunter Trap Timer."

-- Icon
L["Drag to move, then /htt lock"] = "Faites glisser pour déplacer, puis /htt lock"

-- Options
L["Shows how long your trap stays armed: 60 seconds, unless something steps on it. WoW Forever hides the combat log from addons, and enemy auras in combat, so a trap that springs is recognized by a new aura on an enemy that nothing else explains, such as a spell of yours, your pet's or your group's. In a group, an effect that comes without a spell, such as a poison, can now and then be taken for it."] = "Affiche combien de temps votre piège reste armé : 60 secondes, sauf si quelque chose marche dessus. WoW Forever cache le journal de combat aux add-ons, ainsi que les auras des ennemis en combat ; un piège qui se déclenche est donc reconnu à une nouvelle aura sur un ennemi que rien d'autre n'explique, comme un sort de vous, de votre familier ou de votre groupe. En groupe, un effet venu sans sort, comme un poison, peut parfois être pris pour lui."
L["Icon"] = "Icône"
L["Lock the icon"] = "Verrouiller l'icône"
L["Unlocked, the icon stays on screen and can be dragged with the mouse."] = "Déverrouillée, l'icône reste à l'écran et peut être déplacée à la souris."
L["Icon size"] = "Taille de l'icône"
L["Position"] = "Position"
L["Under the %s"] = "Sous le %s"
L["Where a shaman's totems show. It follows the %s when Edit Mode moves it."] = "Là où s'affichent les totems d'un chaman. Il suit le %s quand le Mode Édition le déplace."
L["Free"] = "Libre"
L["Where you drag it while the icon is unlocked."] = "Là où vous le faites glisser quand l'icône est déverrouillée."
L["Shape"] = "Forme"
L["Round, like a totem"] = "Ronde, comme un totem"
L["Square"] = "Carrée"
L["Seconds"] = "Secondes"
L["Below the icon"] = "Sous l'icône"
L["On the icon"] = "Sur l'icône"
L["Test"] = "Tester"
L["Shows a trap that runs out in 15 seconds."] = "Affiche un piège qui expire au bout de 15 secondes."
L["Reset position"] = "Réinitialiser la position"
L["Warning before it runs out"] = "Alerte avant expiration"
L["Seconds left"] = "Secondes restantes"
L["Flash the icon"] = "Faire clignoter l'icône"
L["Play a sound"] = "Jouer un son"
L["Off"] = "Désactivé"
L["%d s"] = "%d s"
