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
L["/htt test - show test traps"] = "/htt test - afficher des pièges de test"
L["/htt clear - clear the countdown, should it go wrong"] = "/htt clear - effacer le compte à rebours, s'il se trompe"
L["countdown cleared."] = "compte à rebours effacé."
L["there is no countdown to clear."] = "il n'y a aucun compte à rebours à effacer."
L["/htt reset - restore the default settings"] = "/htt reset - rétablir les paramètres par défaut"
L["open the game menu, then Options > AddOns > Hunter Trap Timer."] = "ouvrez le menu de jeu, puis Options > Add-ons > Hunter Trap Timer."

-- Icon
L["Drag to move, then /htt lock"] = "Faites glisser pour déplacer, puis /htt lock"
L["Enemy frozen"] = "Ennemi gelé"
L["Burning"] = "En feu"
L["Ice on the ground"] = "Glace au sol"
L["Fire on the ground"] = "Feu au sol"

-- Options
L["Shows how long your traps stay armed: 60 seconds, unless something steps on them. WoW Forever hides the combat log from addons, but the game still tells them when your trap springs, however far away you are."] = "Affiche combien de temps vos pièges restent armés : 60 secondes, sauf si quelque chose marche dessus. WoW Forever cache le journal de combat aux addons, mais le jeu leur signale quand même le déclenchement de votre piège, aussi loin que vous soyez."
L["Icon"] = "Icône"
L["Lock the icon"] = "Verrouiller l'icône"
L["Unlocked, the icon stays on screen and can be dragged with the mouse."] = "Déverrouillée, l'icône reste à l'écran et peut être déplacée à la souris."
L["Icon size"] = "Taille de l'icône"
L["Position"] = "Position"
L["Under the %s"] = "Sous le %s"
L["Under your portrait, clear of your pet's frame. It follows the %s when Edit Mode moves it."] = "Sous votre portrait, sans couvrir le cadre de votre familier. Il suit le %s quand le Mode Édition le déplace."
L["Free"] = "Libre"
L["Where you drag it while the icon is unlocked."] = "Là où vous le faites glisser quand l'icône est déverrouillée."
L["Shape"] = "Forme"
L["Round, like a totem"] = "Ronde, comme un totem"
L["Square"] = "Carrée"
L["Seconds"] = "Secondes"
L["Below the icon"] = "Sous l'icône"
L["On the icon"] = "Sur l'icône"
L["Test"] = "Tester"
L["Shows a fire trap and a frost trap that run out in 20 and 15 seconds."] = "Affiche un piège de feu et un piège de givre qui expirent au bout de 20 et 15 secondes."
L["Reset position"] = "Réinitialiser la position"
L["Warning before it runs out"] = "Alerte avant expiration"
L["Seconds left"] = "Secondes restantes"
L["Flash the icon"] = "Faire clignoter l'icône"
L["After a trap springs"] = "Après le déclenchement d'un piège"
L["Show how long its effect lasts"] = "Afficher combien de temps dure son effet"
L["The trap's icon stays and counts down its effect, however far away you are: Freezing Trap's freeze until the enemy breaks free, Immolation Trap's burn until the enemy it burns dies or you leave combat, and the fire of Explosive Trap and the ice of Frost Trap for their 20 and 30 seconds. Another of your buffs fading during a freeze ends it early, as the game does not tell them apart."] = "L'icône du piège reste et décompte son effet, aussi loin que vous soyez : le gel du Piège givrant jusqu'à ce que l'ennemi se libère, la brûlure du Piège d'immolation jusqu'à la mort de l'ennemi qu'elle brûle ou votre sortie de combat, et le feu du Piège explosif et la glace du Piège de givre pendant leurs 20 et 30 secondes. Si un autre de vos effets bénéfiques se dissipe pendant un gel, il s'arrête plus tôt, car le jeu ne les distingue pas."
L["Off"] = "Désactivé"
L["%d s"] = "%d s"

-- Sounds
L["Each trap's sounds are on the Sounds page, under this one."] = "Les sons de chaque piège sont sur la page Sons, sous celle-ci."
L["Sounds"] = "Sons"
L["Each trap's sounds: one as the warning before it runs out starts, one as its effect runs out, and one if the enemy breaks free or dies before then. Choosing a sound plays it."] = "Les sons de chaque piège : l'un quand commence l'avertissement avant qu'il expire, un autre quand son effet s'épuise, et un dernier si l'ennemi se libère ou meurt avant. Choisir un son le joue."
L["Before it runs out"] = "Avant qu'il expire"
L["When its effect runs out"] = "Quand son effet s'épuise"
L["If it ends early"] = "S'il prend fin plus tôt"
L["None"] = "Aucun"
L["Raid warning"] = "Avertissement de raid"
L["Boss emote"] = "Emote de boss"
L["Boss whisper"] = "Chuchotement de boss"
L["Ready check"] = "Appel"
L["Alarm clock %d"] = "Réveil %d"
L["Whisper"] = "Chuchotement"
L["Notification"] = "Notification"
