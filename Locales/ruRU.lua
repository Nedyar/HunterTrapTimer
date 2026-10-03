-- Русский
local _, ns = ...
if ns.LOCALE ~= "ruRU" then
    return
end
local L = ns.L

-- Chat
L["icon unlocked: drag it where you want it, then /htt lock."] = "значок откреплен: перетащите его куда нужно, затем /htt lock."
L["icon locked."] = "значок закреплен."
L["settings reset to the defaults."] = "настройки сброшены на значения по умолчанию."
L["/htt - open the options"] = "/htt - открыть настройки"
L["/htt unlock, /htt lock - move the icon"] = "/htt unlock, /htt lock - переместить значок"
L["/htt test - show a test trap"] = "/htt test - показать тестовую ловушку"
L["/htt reset - restore the default settings"] = "/htt reset - восстановить настройки по умолчанию"
L["open the game menu, then Options > AddOns > Hunter Trap Timer."] = "откройте главное меню, затем Параметры > Модификации > Hunter Trap Timer."

-- Icon
L["Drag to move, then /htt lock"] = "Перетащите, затем /htt lock"

-- Options
L["Shows how long your trap stays armed: 60 seconds, unless something steps on it. WoW Forever hides the combat log from addons, and enemy auras in combat, so a trap that springs is recognized by a new aura on an enemy that nothing else explains. In a group other players' auras could be taken for it, so there the countdown runs to its end."] = "Показывает, сколько еще ваша ловушка останется взведенной: 60 секунд, если на нее никто не наступит. WoW Forever скрывает от модификаций журнал боя, а в бою и ауры противников, поэтому сработавшая ловушка распознается по новой ауре на противнике, которую больше ничто не объясняет. В группе за нее можно принять ауры других игроков, поэтому там отсчет идет до конца."
L["Icon"] = "Значок"
L["Lock the icon"] = "Закрепить значок"
L["Unlocked, the icon stays on screen and can be dragged with the mouse."] = "Открепленный значок остается на экране, и его можно перетаскивать мышью."
L["Icon size"] = "Размер значка"
L["Count down the effect once the trap springs"] = "Отсчитывать эффект после срабатывания ловушки"
L["The icon turns green and counts down the effect on the enemy, such as the freeze of %s. It ends early if the enemy dies, and a freeze also if the enemy takes damage."] = "Значок становится зеленым и отсчитывает эффект на противнике, например заморозку от «%s». Он заканчивается раньше, если противник умирает, а заморозка — еще и если противник получает урон."
L["Test"] = "Тест"
L["Shows a trap that runs out in 15 seconds."] = "Показывает ловушку, которая исчезнет через 15 секунд."
L["Reset position"] = "Сбросить положение"
L["Warning before it runs out"] = "Предупреждение перед исчезновением"
L["Seconds left"] = "Осталось секунд"
L["Flash the icon"] = "Мигать значком"
L["Play a sound"] = "Проигрывать звук"
L["Off"] = "Выкл."
L["%d s"] = "%d с"
