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
L["/htt test - show test traps"] = "/htt test - показать тестовые ловушки"
L["/htt clear - clear the countdown, should it go wrong"] = "/htt clear - сбросить отсчет, если он сбился"
L["countdown cleared."] = "отсчет сброшен."
L["there is no countdown to clear."] = "нет отсчета, который можно сбросить."
L["/htt reset - restore the default settings"] = "/htt reset - восстановить настройки по умолчанию"
L["open the game menu, then Options > AddOns > Hunter Trap Timer."] = "откройте главное меню, затем Параметры > Модификации > Hunter Trap Timer."

-- Icon
L["Drag to move, then /htt lock"] = "Перетащите, затем /htt lock"
L["Enemy frozen"] = "Противник заморожен"
L["Burning"] = "Горит"
L["Ice on the ground"] = "Лёд на земле"
L["Fire on the ground"] = "Огонь на земле"

-- Options
L["Shows how long your traps stay armed: 60 seconds, unless something steps on them. WoW Forever hides the combat log from addons, but the game still tells them when your trap springs, however far away you are."] = "Показывает, сколько ещё ваши ловушки останутся взведёнными: 60 секунд, если на них никто не наступит. WoW Forever скрывает от аддонов журнал боя, но игра всё равно сообщает им о срабатывании ловушки, как бы далеко вы ни были."
L["Icon"] = "Значок"
L["Lock the icon"] = "Закрепить значок"
L["Unlocked, the icon stays on screen and can be dragged with the mouse."] = "Открепленный значок остается на экране, и его можно перетаскивать мышью."
L["Icon size"] = "Размер значка"
L["Position"] = "Положение"
L["Under the %s"] = "Под окном «%s»"
L["Under your portrait, clear of your pet's frame. It follows the %s when Edit Mode moves it."] = "Под вашим портретом, не закрывая окно питомца. Следует за окном «%s», когда его перемещают в режиме редактирования."
L["Free"] = "Свободно"
L["Where you drag it while the icon is unlocked."] = "Там, куда вы перетащите незакрепленный значок."
L["Shape"] = "Форма"
L["Round, like a totem"] = "Круглый, как тотем"
L["Square"] = "Квадратный"
L["Seconds"] = "Секунды"
L["Below the icon"] = "Под значком"
L["On the icon"] = "На значке"
L["Test"] = "Тест"
L["Shows a fire trap and a frost trap that run out in 20 and 15 seconds."] = "Показывает огненную и ледяную ловушки, которые исчезнут через 20 и 15 секунд."
L["Reset position"] = "Сбросить положение"
L["Warning before it runs out"] = "Предупреждение перед исчезновением"
L["Seconds left"] = "Осталось секунд"
L["Flash the icon"] = "Мигать значком"
L["After a trap springs"] = "После срабатывания ловушки"
L["Show how long its effect lasts"] = "Показывать, сколько длится её эффект"
L["The trap's icon stays and counts down its effect, however far away you are: Freezing Trap's freeze until the enemy breaks free, Immolation Trap's burn until the enemy it burns dies or you leave combat, and the fire of Explosive Trap and the ice of Frost Trap for their 20 and 30 seconds. Another of your buffs fading during a freeze ends it early, as the game does not tell them apart."] = "Значок ловушки остаётся и отсчитывает её эффект, как бы далеко вы ни были: заморозку Замораживающей ловушки, пока противник не освободится, горение Обжигающей ловушки, пока горящий противник не умрёт или вы не выйдете из боя, а огонь Взрывной ловушки и лёд Ледяной ловушки — их 20 и 30 секунд. Если во время заморозки закончится другой ваш положительный эффект, отсчёт завершится раньше: игра их не различает."
L["Off"] = "Выкл."
L["%d s"] = "%d с"

-- Sounds
L["Each trap's sounds are on the Sounds page, under this one."] = "Звуки каждой ловушки — на странице «Звуки» под этой."
L["Sounds"] = "Звуки"
L["Each trap's sounds: one as the warning before it runs out starts, one as its effect ends. Choosing a sound plays it."] = "Звуки каждой ловушки: один — когда начинается предупреждение перед её исчезновением, другой — когда заканчивается её эффект. При выборе звук проигрывается."
L["Before it runs out"] = "Перед исчезновением"
L["When its effect ends"] = "Когда эффект заканчивается"
L["None"] = "Нет"
L["Raid warning"] = "Объявление рейду"
L["Boss emote"] = "Эмоция босса"
L["Boss whisper"] = "Шёпот босса"
L["Ready check"] = "Проверка готовности"
L["Alarm clock %d"] = "Будильник %d"
L["Whisper"] = "Шёпот"
L["Notification"] = "Уведомление"
