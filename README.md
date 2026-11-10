<p align="center"><img src=".github/logo.png" alt="Hunter Trap Timer logo" width="160"></p>

# Hunter Trap Timer

An addon for WoW Forever (the `_forever_` client, 1.60.x) that shows how
long your hunter traps stay armed before they vanish.

- **Countdown for your armed traps.** When you put down an Immolation,
  Freezing, Frost or Explosive Trap, an icon shows it with a clock sweep and
  the seconds left: an armed trap lasts 60 seconds unless something steps on
  it. A fire trap (Immolation, Explosive) and a frost trap (Freezing, Frost)
  can be down at once, each with its icon; a new trap replaces only the one
  of its own school.
- **Shown like a totem.** By default the icon looks like a shaman's
  totem: round, in a totem's ring, with the seconds below it. It sits under
  your portrait, clear of your pet's frame, at the player frame's scale
  (following it when Edit Mode moves or resizes it); with both traps down,
  the frost trap's icon goes to the left of the fire trap's, under your
  level. Its tooltip, as a
  totem's, gives the trap's name, rank and time left. The options make the
  icons square, put the seconds on them, resize them, or free them to be
  dragged anywhere.
- **Warning before it runs out.** With 10 seconds left (adjustable, or off)
  the seconds turn red, the icon flashes and a sound plays.
- **Notices when a trap springs.** A trap that springs is gone, so its
  icon goes, also when the enemy resists the trap or is immune to it.
- **Keeps the countdowns through a `/reload`.** The traps stay in the world
  when you reload the interface, and so do their countdowns.
- **Every client language.** The texts are in English, German, Spanish (EU
  and Latin America), French, Italian, Korean, Portuguese (Brazil, also used
  by Portugal's client), Russian and Chinese (simplified and traditional).

## Installing

1. Copy the `HunterTrapTimer` folder into
   `World of Warcraft\_forever_\Interface\AddOns\`.
2. Put a trap down, or try `/htt test`. To move the icons, `/htt unlock`,
   drag them, then `/htt lock`; **Reset position** in the options puts them
   back under the player frame.
3. The options are under the game menu: Options > AddOns > Hunter Trap Timer
   (or `/htt`).

The settings are shared by all the characters of your account. The game
saves them in `HunterTrapTimerDB`.

## Commands

| Command | What it does |
|---|---|
| `/htt` | Open the options |
| `/htt unlock`, `/htt lock` | Show the icons to drag them, and lock them again |
| `/htt test` | Show a test trap of each school, running out in 20 and 15 seconds |
| `/htt clear` | Clear the countdowns, should they ever go wrong |
| `/htt reset` | Restore the default settings |
| `/htt probe` | A report on what the client lets the addon see, in a window you can copy (`/htt probe log` records the trap's events until you run it again) |

`/huntertraptimer` works as well as `/htt`.

## How it knows a trap sprang

WoW Forever runs the Midnight addon API. Addons cannot read the combat log
at all, and in combat the auras on enemies are secret. A trap that springs
puts you in combat at that very moment, so its effect can seldom be read
(when it can, the addon uses it). These do come through:

- **Casts.** Putting a trap down is always seen, so the 60 second countdown
  is exact. Your group's spells are secret in combat, but that they cast is
  not.
- **That an enemy gained an aura**, though not which one. With a trap down,
  an aura that nothing else explains is taken for the trap's:
  something else explains it when you, your pet, or anyone in your group or
  their pets cast a spell in the 1.5 seconds before (attacks that put no
  aura excepted, such as Auto Shot, Raptor Strike, Arcane Shot or the pet's
  Bite), or the enemy itself cast one in the second before. In a
  group, an effect that comes with no spell, such as a rogue's poison, a
  weapon's proc or a totem's attack, can now and then be taken for the trap.
- **Damage, with its spell school.** It is never secret. Hunters and their
  pets cast no fire or frost spell besides traps, so fire or frost on an
  enemy while a trap of that school is down is the trap's, unless someone in
  your group cast a spell just before: fire damage means a fire trap sprang,
  and a full resist or an immunity that the trap sprang for nothing.

With both traps down, an aura that cannot be read could be either trap's.
A fire trap shows fire on the enemy soon after it springs (Explosive Trap's
blast at once, Immolation Trap's first burn some 3 seconds later), so the
aura is taken for the frost trap's only if no fire follows within 4 seconds.
Auras just after a trap springs (Explosive Trap burns every enemy around),
and on enemies slowed by Frost Trap's ice for the 30 seconds it lasts, are
not taken for your other trap.

The trap's effect itself (the freeze, the burn) is not shown: the addon only
times the armed trap.

## Files

| File | Purpose |
|---|---|
| `Locales\` | Translations, one file per language; the English text is the key |
| `Core.lua` | Settings, shared helpers, startup, slash commands |
| `Traps.lua` | The traps, their casts, and noticing when one springs |
| `Display.lua` | The icons, their sweeps, seconds and warnings |
| `Options.lua` | The settings page |
| `Probe.lua` | `/htt probe`, the report for the addon's author (in English) |
| `Tests\` | Offline tests (not loaded by the game) |
| `.github\logo.png` | The project logo (not part of the addon) |
| `CHANGELOG.md` | Release notes, shown on CurseForge for each file |
| `.pkgmeta` | How CurseForge packages a release |

## Tests

The tests run the real addon files, loaded in the order of the TOC, against
a strict stand-in for the WoW Forever API: a virtual clock, enemies whose
auras can or cannot be read, the hunter's and the pet's casts, damage and
deaths, and the settings page. They need a Lua 5.1 interpreter, the game's
Lua:

```
lua5.1 Tests\run.lua [path to HunterTrapTimer]
```

The path defaults to the folder that holds `Tests`. The tests put traps
down, one or one of each school, and let them run out or spring, with auras
that can be read, secret ones, and ones that a cast explains, and with
resists and immune enemies;
they cover the warning, a `/reload` and a new login, moving the icon, the
options, the saved settings, the probe, and every client language, which must translate
exactly the texts the code uses, with the same placeholders. They also fail
if the addon sets a global other than its saved settings and slash commands.

## Releasing

CurseForge packages every tagged commit pushed to this repository.

1. Raise `## Version` in `HunterTrapTimer.toc` and add that version's entry
   at the top of `CHANGELOG.md`. The tests check that both match.
2. Commit, tag the commit `v<version>` and push the tag:
   `git push origin v<version>`. A tag containing `beta` or `alpha` makes a
   beta or alpha file instead of a release.
3. CurseForge builds the zip as `.pkgmeta` says: the `HunterTrapTimer`
   folder without the tests, with `CHANGELOG.md` as the file's changelog.

## License

MIT, see [LICENSE](LICENSE).
