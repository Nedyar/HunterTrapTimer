-- 简体中文
local _, ns = ...
if ns.LOCALE ~= "zhCN" then
    return
end
local L = ns.L

-- Chat
L["icon unlocked: drag it where you want it, then /htt lock."] = "图标已解锁：将它拖到你想要的位置，然后输入 /htt lock。"
L["icon locked."] = "图标已锁定。"
L["settings reset to the defaults."] = "设置已恢复为默认值。"
L["/htt - open the options"] = "/htt - 打开设置"
L["/htt unlock, /htt lock - move the icon"] = "/htt unlock, /htt lock - 移动图标"
L["/htt test - show test traps"] = "/htt test - 显示测试陷阱"
L["/htt clear - clear the countdown, should it go wrong"] = "/htt clear - 倒计时出错时将其清除"
L["countdown cleared."] = "倒计时已清除。"
L["there is no countdown to clear."] = "没有可清除的倒计时。"
L["/htt reset - restore the default settings"] = "/htt reset - 恢复默认设置"
L["open the game menu, then Options > AddOns > Hunter Trap Timer."] = "打开游戏菜单，然后选择 设置选项 > 插件 > Hunter Trap Timer。"

-- Icon
L["Drag to move, then /htt lock"] = "拖动以移动，然后输入 /htt lock"
L["Enemy frozen"] = "敌人已冻结"
L["Burning"] = "灼烧中"
L["Ice on the ground"] = "地面结冰"
L["Fire on the ground"] = "地面着火"

-- Options
L["Shows how long your traps stay armed: 60 seconds, unless something steps on them. WoW Forever hides the combat log from addons, but the game still tells them when your trap springs, however far away you are."] = "显示你的陷阱还能保持多久：60秒，除非有东西踩中。WoW Forever 对插件隐藏战斗记录，但无论你离多远，游戏仍会在陷阱触发时通知插件。"
L["Icon"] = "图标"
L["Lock the icon"] = "锁定图标"
L["Unlocked, the icon stays on screen and can be dragged with the mouse."] = "解锁后，图标会留在屏幕上，可以用鼠标拖动。"
L["Icon size"] = "图标大小"
L["Position"] = "位置"
L["Under the %s"] = "%s下方"
L["Under your portrait, clear of your pet's frame. It follows the %s when Edit Mode moves it."] = "在你的头像下方，不遮挡宠物框体。用编辑模式移动%s时，它会跟着移动。"
L["Free"] = "自由"
L["Where you drag it while the icon is unlocked."] = "解锁图标后拖动到的位置。"
L["Shape"] = "形状"
L["Round, like a totem"] = "圆形，与图腾相同"
L["Square"] = "方形"
L["Seconds"] = "秒数"
L["Below the icon"] = "图标下方"
L["On the icon"] = "图标上"
L["Test"] = "测试"
L["Shows a fire trap and a frost trap that run out in 20 and 15 seconds."] = "显示一个火焰陷阱和一个冰霜陷阱，分别在20秒和15秒后消失。"
L["Reset position"] = "重置位置"
L["Warning before it runs out"] = "消失前警告"
L["Seconds left"] = "剩余秒数"
L["Flash the icon"] = "图标闪烁"
L["After a trap springs"] = "陷阱触发后"
L["Show how long its effect lasts"] = "显示其效果持续时间"
L["The trap's icon stays and counts down its effect, however far away you are: Freezing Trap's freeze until the enemy breaks free, Immolation Trap's burn until the enemy it burns dies or you leave combat, and the fire of Explosive Trap and the ice of Frost Trap for their 20 and 30 seconds. Another of your buffs fading during a freeze ends it early, as the game does not tell them apart."] = "无论你离多远，陷阱图标都会保留并倒数其效果：冰冻陷阱的冰冻直到敌人挣脱，献祭陷阱的灼烧直到被灼烧的敌人死亡或你脱离战斗，爆炸陷阱的火焰和冰霜陷阱的冰面分别持续20秒和30秒。冰冻期间若你的其他增益效果消失，倒数会提前结束，因为游戏无法区分它们。"
L["Off"] = "关闭"
L["%d s"] = "%d秒"

-- Sounds
L["Each trap's sounds are on the Sounds page, under this one."] = "每种陷阱的音效在此页下方的“音效”页中。"
L["Sounds"] = "音效"
L["Each trap's sounds: one as the warning before it runs out starts, one as its effect runs out, and one if the enemy breaks free or dies before then. Choosing a sound plays it."] = "每种陷阱的音效：一个在消失前的警告开始时播放，一个在效果时间耗尽时播放，一个在敌人提前挣脱或死亡时播放。选择音效时会试听。"
L["Before it runs out"] = "消失前"
L["When its effect runs out"] = "效果时间耗尽时"
L["If it ends early"] = "提前结束时"
L["None"] = "无"
L["Raid warning"] = "团队警告"
L["Boss emote"] = "首领表情"
L["Boss whisper"] = "首领密语"
L["Ready check"] = "就位确认"
L["Alarm clock %d"] = "闹钟 %d"
L["Whisper"] = "密语"
L["Notification"] = "通知"
