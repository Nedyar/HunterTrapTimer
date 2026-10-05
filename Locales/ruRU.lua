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
L["/htt clear - clear the countdown, should it go wrong"] = "/htt clear - сбросить отсчет, если он сбился"
L["countdown cleared."] = "отсчет сброшен."
L["there is no countdown to clear."] = "нет отсчета, который можно сбросить."
L["/htt reset - restore the default settings"] = "/htt reset - восстановить настройки по умолчанию"
L["open the game menu, then Options > AddOns > Hunter Trap Timer."] = "откройте главное меню, затем Параметры > Модификации > Hunter Trap Timer."

-- Icon
L["Drag to move, then /htt lock"] = "Перетащите, затем /htt lock"

-- Options
L["Shows how long your trap stays armed: 60 seconds, unless something steps on it. WoW Forever hides the combat log from addons, and enemy auras in combat, so a trap that springs is recognized by a new aura on an enemy that nothing else explains, such as a spell of yours, your pet's or your group's. In a group, an effect that comes without a spell, such as a poison, can now and then be taken for it."] = "Показывает, сколько еще ваша ловушка останется взведенной: 60 секунд, если на нее никто не наступит. WoW Forever скрывает от модификаций журнал боя, а в бою и ауры противников, поэтому сработавшая ловушка распознается по новой ауре на противнике, которую больше ничто не объясняет, например заклинание ваше, вашего питомца или вашей группы. В группе за нее иногда можно принять эффект, наложенный без заклинания, например яд."
L["Icon"] = "Значок"
L["Lock the icon"] = "Закрепить значок"
L["Unlocked, the icon stays on screen and can be dragged with the mouse."] = "Открепленный значок остается на экране, и его можно перетаскивать мышью."
L["Icon size"] = "Размер значка"
L["Position"] = "Положение"
L["Under the %s"] = "Под окном «%s»"
L["Where a shaman's totems show. It follows the %s when Edit Mode moves it."] = "Там, где показываются тотемы шамана. Следует за окном «%s», когда его перемещают в режиме редактирования."
L["Free"] = "Свободно"
L["Where you drag it while the icon is unlocked."] = "Там, куда вы перетащите незакрепленный значок."
L["Shape"] = "Форма"
L["Round, like a totem"] = "Круглый, как тотем"
L["Square"] = "Квадратный"
L["Seconds"] = "Секунды"
L["Below the icon"] = "Под значком"
L["On the icon"] = "На значке"
L["Test"] = "Тест"
L["Shows a trap that runs out in 15 seconds."] = "Показывает ловушку, которая исчезнет через 15 секунд."
L["Reset position"] = "Сбросить положение"
L["Warning before it runs out"] = "Предупреждение перед исчезновением"
L["Seconds left"] = "Осталось секунд"
L["Flash the icon"] = "Мигать значком"
L["Play a sound"] = "Проигрывать звук"
L["Off"] = "Выкл."
L["%d s"] = "%d с"
