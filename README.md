<p align="center"><img src=".github/logo.png" alt="Hunter Trap Timer logo" width="160"></p>

# Hunter Trap Timer

An addon for WoW Forever (the `_classic_beta_` client, 1.60.x) that shows
how long your hunter trap stays armed before it vanishes.

- **Countdown for your armed trap.** When you put down an Immolation,
  Freezing, Frost or Explosive Trap, an icon shows it with a clock sweep and
  the seconds left: an armed trap lasts 60 seconds unless something steps on
  it. Only one trap can be down at a time, so a new one replaces the old.
- **Warning before it runs out.** With 10 seconds left (adjustable, or off)
  the seconds turn red, the icon flashes and a sound plays.
- **Notices when the trap springs.** The icon then turns green and counts
  down the effect on the enemy, such as the freeze. A freeze ends early when
  the enemy takes damage, and the freeze and Immolation Trap's burn when the
  enemy dies. Frost and Explosive Trap leave an area on the ground, which
  lasts its full time.
- **Every client language.** The texts are in English, German, Spanish (EU
  and Latin America), French, Italian, Korean, Portuguese (Brazil, also used
  by Portugal's client), Russian and Chinese (simplified and traditional).

## Installing

1. Copy the `HunterTrapTimer` folder into
   `World of Warcraft\_classic_beta_\Interface\AddOns\`.
2. Put a trap down, or try `/htt test`. To move the icon, `/htt unlock`, drag
   it, then `/htt lock`.
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
| `/htt reset` | Restore the default settings |
| `/htt probe` | A report on what the client lets the addon see, in a window you can copy (`/htt probe log` records the trap's events until you run it again) |

`/huntertraptimer` works as well as `/htt`.

## How it knows a trap sprang

WoW Forever runs the Midnight addon API. Addons cannot read the combat log
at all, and in combat the auras on enemies are secret. A trap that springs
puts you in combat at that very moment, so its effect can seldom be read
(when it can, the addon uses it). Three things do come through:

- **Your own casts.** Putting a trap down is always seen, so the 60 second
  countdown is exact.
- **That an enemy gained an aura**, though not which one. With a trap down,
  an aura that nothing else explains is taken for the trap's effect:
  something else explains it when you or your pet cast a spell in the
  1.5 seconds before (Auto Shot excepted, as it puts no aura), or the enemy
  itself cast one in the second before.
  In a group, other players' auras could be taken for the trap, so there
  the addon does not guess and the countdown runs to its end.
- **Damage and death.** Damage to the frozen enemy and an enemy's death are
  never secret, so they end the effect's countdown.

When the effect cannot be read, its countdown is the full time of the
trap's rank.

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
ones, and ones that a cast explains; they cover the warning, the effect's
countdown and how it ends, moving the icon, the options, the saved
settings, the probe, and every client language, which must translate
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
