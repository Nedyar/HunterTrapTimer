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
L["/htt reset - restore the default settings"] = "/htt reset - rétablir les paramètres par défaut"
L["open the game menu, then Options > AddOns > Hunter Trap Timer."] = "ouvrez le menu de jeu, puis Options > Add-ons > Hunter Trap Timer."

-- Icon
L["Drag to move, then /htt lock"] = "Faites glisser pour déplacer, puis /htt lock"

-- Options
L["Shows how long your trap stays armed: 60 seconds, unless something steps on it. WoW Forever hides the combat log from addons, and enemy auras in combat, so a trap that springs is recognized by a new aura on an enemy that nothing else explains. In a group other players' auras could be taken for it, so there the countdown runs to its end."] = "Affiche combien de temps votre piège reste armé : 60 secondes, sauf si quelque chose marche dessus. WoW Forever cache le journal de combat aux add-ons, ainsi que les auras des ennemis en combat ; un piège qui se déclenche est donc reconnu à une nouvelle aura sur un ennemi que rien d'autre n'explique. En groupe, les auras des autres joueurs pourraient être prises pour lui ; le compte à rebours va donc jusqu'au bout."
L["Icon"] = "Icône"
L["Lock the icon"] = "Verrouiller l'icône"
L["Unlocked, the icon stays on screen and can be dragged with the mouse."] = "Déverrouillée, l'icône reste à l'écran et peut être déplacée à la souris."
L["Icon size"] = "Taille de l'icône"
L["Count down the effect once the trap springs"] = "Décompter l'effet une fois le piège déclenché"
L["The icon turns green and counts down the effect on the enemy, such as the freeze of %s. It ends early if the enemy dies, and a freeze also if the enemy takes damage."] = "L'icône devient verte et décompte l'effet sur l'ennemi, comme le gel de %s. Il prend fin plus tôt si l'ennemi meurt, et un gel aussi si l'ennemi subit des dégâts."
L["Test"] = "Tester"
L["Shows a trap that runs out in 15 seconds."] = "Affiche un piège qui expire au bout de 15 secondes."
L["Reset position"] = "Réinitialiser la position"
L["Warning before it runs out"] = "Alerte avant expiration"
L["Seconds left"] = "Secondes restantes"
L["Flash the icon"] = "Faire clignoter l'icône"
L["Play a sound"] = "Jouer un son"
L["Off"] = "Désactivé"
L["%d s"] = "%d s"
