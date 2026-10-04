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
L["/htt test - show a test trap"] = "/htt test - 显示测试陷阱"
L["/htt clear - clear the countdown, should it go wrong"] = "/htt clear - 倒计时出错时将其清除"
L["countdown cleared."] = "倒计时已清除。"
L["there is no countdown to clear."] = "没有可清除的倒计时。"
L["/htt reset - restore the default settings"] = "/htt reset - 恢复默认设置"
L["open the game menu, then Options > AddOns > Hunter Trap Timer."] = "打开游戏菜单，然后选择 设置选项 > 插件 > Hunter Trap Timer。"

-- Icon
L["Drag to move, then /htt lock"] = "拖动以移动，然后输入 /htt lock"

-- Options
L["Shows how long your trap stays armed: 60 seconds, unless something steps on it. WoW Forever hides the combat log from addons, and enemy auras in combat, so a trap that springs is recognized by a new aura on an enemy that nothing else explains, such as a spell of yours, your pet's or your group's. In a group, an effect that comes without a spell, such as a poison, can now and then be taken for it."] = "显示你的陷阱还能保持布置多久：60秒，除非有东西踩到它。WoW Forever 对插件隐藏战斗记录，战斗中也隐藏敌人的光环，因此陷阱被触发时，是通过敌人身上出现的、无法用其他原因（例如你、你的宠物或队友的法术）解释的新光环来识别的。在队伍中，不经由法术施加的效果（例如毒药）偶尔可能被误认为是它。"
L["Icon"] = "图标"
L["Lock the icon"] = "锁定图标"
L["Unlocked, the icon stays on screen and can be dragged with the mouse."] = "解锁后，图标会留在屏幕上，可以用鼠标拖动。"
L["Icon size"] = "图标大小"
L["Test"] = "测试"
L["Shows a trap that runs out in 15 seconds."] = "显示一个15秒后消失的陷阱。"
L["Reset position"] = "重置位置"
L["Warning before it runs out"] = "消失前警告"
L["Seconds left"] = "剩余秒数"
L["Flash the icon"] = "图标闪烁"
L["Play a sound"] = "播放声音"
L["Off"] = "关闭"
L["%d s"] = "%d秒"
