# Changelog

## 0.3.1

- **Every effect keeps its own icon**: a new trap no longer hides the effect of the last one of its school (Explosive Trap's fire, say, while a new fire trap is down), and two effects of one trap at once each show (two of Frost Trap's ices on the ground). The row of icons grows as it needs to: the traps down first, then the effects, oldest first.
- **Freezing Trap's freeze ends when the enemy breaks free, with the game's combat text off too**: logged in with "Show combat text" off, the game told addons nothing of the hunter's auras, so the freeze ran its whole time. The addon now asks for that news itself. An enemy that breaks free the moment it is caught (a sting's tick, your pet) ends the freeze as well.
- **A sound for an effect that ends early**: Freezing Trap's freeze and Immolation Trap's burn can end before their time, as the enemy breaks free or dies; the Sounds page now has a sound for that, apart from the one for their time running out. It starts as the sound you had chosen for the effect's end.

## 0.3.0

- **Notices every trap that springs, however far away you are**: the game tells addons when a trap goes, and which one, even when the enemy is out of sight, with enemy nameplates off, or in combat. A trap that sprang while you were away no longer keeps its countdown and its warning.
- **No more guessing**: an aura or fire on an enemy no longer counts as your trap, so in a group a teammate's poison or proc is never taken for it, and with both traps down the right one goes at once.
- **How long a trap's effect lasts**: once a trap springs, its icon stays and counts down its effect, however far away you are, its seconds rounded as the game's aura tooltips round them. Freezing Trap's freeze (seconds in ice blue) lasts until the enemy breaks free. Immolation Trap's burn (in orange) lasts until the enemy it burns is seen to die, or you leave combat. Explosive Trap's fire (in orange) and Frost Trap's ice (in ice blue) stay on the ground their 20 and 30 seconds. Another of your buffs fading during a freeze ends its countdown early, as the game does not tell them apart. The countdown can be turned off in the options.
- **A sound of your choice for each trap**: on the new Sounds page of the options, each trap has a sound for the warning before it runs out and one for when its effect ends, out of nine of the game's sounds or none; choosing one plays it. By default the warnings keep the raid warning, and every effect's end plays the third alarm clock. If you had turned the warning's sound off, all the warnings stay silent.
- `/htt probe` logs what the game tells of traps and freezes, and its window closes in combat too.

## 0.2.0

- **A fire trap and a frost trap at once**: WoW Forever lets you have one of each down, so each gets its own icon, the frost trap's to the left of the fire trap's, under your level. A new trap replaces only the one of its own school. The icons sit a little lower than before, clear of the level circle.
- **Each trap springs on its own**: with both down, an aura that could be either trap's is taken for the frost trap's unless fire follows within 4 seconds (Immolation Trap burns some 3 seconds after it springs). Enemies slowed on Frost Trap's ice, or burned by Explosive Trap, do not spring your other trap.
- Each trap warns on its own, both survive a /reload, and `/htt clear` clears both.
- `/htt test` shows a test trap of each school.

## 0.1.1

- **The icon no longer covers your pet's frame**: by default it now sits under your portrait, clear of it.

## 0.1.0 - First release

- **Countdown for your armed trap**: an icon with a clock sweep and the seconds left of its 60, for Immolation, Freezing, Frost and Explosive Trap. A new trap replaces the old one.
- **Warning before it runs out**: the seconds turn red, the icon flashes and a sound plays, 10 seconds before by default (adjustable, or off).
- **Notices when the trap springs, even in combat**, and the icon goes: by a new aura on an enemy that nothing else explains (a spell of yours, your pet's or your group's), or by fire damage, a resist or an immunity of the trap's school on an enemy.
- **Keeps the countdown through a /reload**, and `/htt clear` clears it should it ever go wrong.
- **Shown like a totem** by default: a round icon in a totem's ring, the seconds below it, under the player frame, with a tooltip giving the trap's name, rank and time left.
- **Options**: round or square, the seconds below or on the icon, under the player frame or anywhere you drag it, its size, and the warning. `/htt test` shows a test trap.
- **Translated into every client language**: English, German, Spanish, French, Italian, Korean, Portuguese, Russian and Chinese.
