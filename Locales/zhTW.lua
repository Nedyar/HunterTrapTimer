-- 繁體中文
local _, ns = ...
if ns.LOCALE ~= "zhTW" then
    return
end
local L = ns.L

-- Chat
L["icon unlocked: drag it where you want it, then /htt lock."] = "圖示已解鎖：將它拖曳到你想要的位置，然後輸入 /htt lock。"
L["icon locked."] = "圖示已鎖定。"
L["settings reset to the defaults."] = "設定已恢復為預設值。"
L["/htt - open the options"] = "/htt - 開啟選項"
L["/htt unlock, /htt lock - move the icon"] = "/htt unlock, /htt lock - 移動圖示"
L["/htt test - show a test trap"] = "/htt test - 顯示測試陷阱"
L["/htt clear - clear the countdown, should it go wrong"] = "/htt clear - 倒數出錯時將其清除"
L["countdown cleared."] = "倒數已清除。"
L["there is no countdown to clear."] = "沒有可清除的倒數。"
L["/htt reset - restore the default settings"] = "/htt reset - 恢復預設設定"
L["open the game menu, then Options > AddOns > Hunter Trap Timer."] = "開啟遊戲選項，然後選擇 選項 > 插件 > Hunter Trap Timer。"

-- Icon
L["Drag to move, then /htt lock"] = "拖曳以移動，然後輸入 /htt lock"

-- Options
L["Shows how long your trap stays armed: 60 seconds, unless something steps on it. WoW Forever hides the combat log from addons, and enemy auras in combat, so a trap that springs is recognized by a new aura on an enemy that nothing else explains, such as a spell of yours, your pet's or your group's. In a group, an effect that comes without a spell, such as a poison, can now and then be taken for it."] = "顯示你的陷阱還能保持布置多久：60秒，除非有東西踩到它。WoW Forever 對插件隱藏戰鬥記錄，戰鬥中也隱藏敵人的光環，因此陷阱被觸發時，是透過敵人身上出現、無法以其他原因（例如你、你的寵物或隊友的法術）解釋的新光環來辨識。在隊伍中，不經由法術施加的效果（例如毒藥）偶爾可能被誤認為是它。"
L["Icon"] = "圖示"
L["Lock the icon"] = "鎖定圖示"
L["Unlocked, the icon stays on screen and can be dragged with the mouse."] = "解鎖後，圖示會留在螢幕上，可以用滑鼠拖曳。"
L["Icon size"] = "圖示大小"
L["Position"] = "位置"
L["Under the %s"] = "%s下方"
L["Under your portrait, clear of your pet's frame. It follows the %s when Edit Mode moves it."] = "在你的頭像下方，不遮擋寵物框架。用編輯模式移動%s時，它會跟著移動。"
L["Free"] = "自由"
L["Where you drag it while the icon is unlocked."] = "解鎖圖示後拖曳到的位置。"
L["Shape"] = "形狀"
L["Round, like a totem"] = "圓形，與圖騰相同"
L["Square"] = "方形"
L["Seconds"] = "秒數"
L["Below the icon"] = "圖示下方"
L["On the icon"] = "圖示上"
L["Test"] = "測試"
L["Shows a trap that runs out in 15 seconds."] = "顯示一個15秒後消失的陷阱。"
L["Reset position"] = "重設位置"
L["Warning before it runs out"] = "消失前警告"
L["Seconds left"] = "剩餘秒數"
L["Flash the icon"] = "圖示閃爍"
L["Play a sound"] = "播放音效"
L["Off"] = "關閉"
L["%d s"] = "%d秒"
