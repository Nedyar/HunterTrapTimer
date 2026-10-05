<p align="center"><img src=".github/logo.png" alt="Hunter Trap Timer logo" width="160"></p>

# Hunter Trap Timer

An addon for WoW Forever (the `_classic_beta_` client, 1.60.x) that shows
how long your hunter trap stays armed before it vanishes.

- **Countdown for your armed trap.** When you put down an Immolation,
  Freezing, Frost or Explosive Trap, an icon shows it with a clock sweep and
  the seconds left: an armed trap lasts 60 seconds unless something steps on
  it. Only one trap can be down at a time, so a new one replaces the old.
- **Shown like a totem.** By default the icon looks and sits like a
  shaman's totem: round, in a totem's ring, with the seconds below it, under
  the player frame and at its scale (following it when Edit Mode moves or
  resizes it). Its tooltip, as a totem's, gives the trap's name, rank and
  time left. The options make it square, put the seconds on it, resize it,
  or free it to be dragged anywhere.
- **Warning before it runs out.** With 10 seconds left (adjustable, or off)
  the seconds turn red, the icon flashes and a sound plays.
- **Notices when the trap springs.** A trap that springs is gone, so its
  icon goes, also when the enemy resists the trap or is immune to it.
- **Keeps the countdown through a `/reload`.** The trap stays in the world
  when you reload the interface, and so does its countdown.
- **Every client language.** The texts are in English, German, Spanish (EU
  and Latin America), French, Italian, Korean, Portuguese (Brazil, also used
  by Portugal's client), Russian and Chinese (simplified and traditional).

## Installing

1. Copy the `HunterTrapTimer` folder into
   `World of Warcraft\_classic_beta_\Interface\AddOns\`.
2. Put a trap down, or try `/htt test`. To move the icon, `/htt unlock`, drag
   it, then `/htt lock`; **Reset position** in the options puts it back under
   the player frame.
3. The options are under the game menu: Options > AddOns > Hunter Trap Timer
   (or `/htt`).

The settings are shared by all the characters of your account. The game
saves them in `HunterTrapTimerDB`.

## Commands

| Command | What it does |
|---|---|
| `/htt` | Open the options |
| `/htt unlock`, `/htt lock` | Show the icon to drag it, and lock it again |
| `/htt test` | Show a test trap that runs out in 15 seconds |
| `/htt clear` | Clear the countdown, should it ever go wrong |
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

The trap's effect itself (the freeze, the burn) is not shown: the addon only
times the armed trap.

## Files

| File | Purpose |
|---|---|
| `Locales\` | Translations, one file per language; the English text is the key |
| `Core.lua` | Settings, shared helpers, startup, slash commands |
| `Traps.lua` | The traps, their casts, and noticing when one springs |
| `Display.lua` | The icon, its sweep, seconds and warning |
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
down and let them run out or spring, with auras that can be read, secret
ones, and ones that a cast explains, and with resists and immune enemies;
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
