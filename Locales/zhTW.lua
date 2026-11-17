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
L["/htt test - show test traps"] = "/htt test - 顯示測試陷阱"
L["/htt clear - clear the countdown, should it go wrong"] = "/htt clear - 倒數出錯時將其清除"
L["countdown cleared."] = "倒數已清除。"
L["there is no countdown to clear."] = "沒有可清除的倒數。"
L["/htt reset - restore the default settings"] = "/htt reset - 恢復預設設定"
L["open the game menu, then Options > AddOns > Hunter Trap Timer."] = "開啟遊戲選項，然後選擇 選項 > 插件 > Hunter Trap Timer。"

-- Icon
L["Drag to move, then /htt lock"] = "拖曳以移動，然後輸入 /htt lock"
L["Enemy frozen"] = "敵人已凍結"
L["Burning"] = "灼燒中"
L["Ice on the ground"] = "地面結冰"
L["Fire on the ground"] = "地面著火"

-- Options
L["Shows how long your traps stay armed: 60 seconds, unless something steps on them. WoW Forever hides the combat log from addons, but the game still tells them when your trap springs, however far away you are."] = "顯示你的陷阱還能維持多久：60秒，除非有東西踩中。WoW Forever 對插件隱藏戰鬥紀錄，但無論你離多遠，遊戲仍會在陷阱觸發時通知插件。"
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
L["Shows a fire trap and a frost trap that run out in 20 and 15 seconds."] = "顯示一個火焰陷阱和一個冰霜陷阱，分別在20秒和15秒後消失。"
L["Reset position"] = "重設位置"
L["Warning before it runs out"] = "消失前警告"
L["Seconds left"] = "剩餘秒數"
L["Flash the icon"] = "圖示閃爍"
L["After a trap springs"] = "陷阱觸發後"
L["Show how long its effect lasts"] = "顯示其效果持續時間"
L["The trap's icon stays and counts down its effect, however far away you are: Freezing Trap's freeze until the enemy breaks free, Immolation Trap's burn until the enemy it burns dies or you leave combat, and the fire of Explosive Trap and the ice of Frost Trap for their 20 and 30 seconds. Another of your buffs fading during a freeze ends it early, as the game does not tell them apart."] = "無論你離多遠，陷阱圖示都會保留並倒數其效果：冰凍陷阱的冰凍直到敵人掙脫，獻祭陷阱的灼燒直到被灼燒的敵人死亡或你脫離戰鬥，爆炸陷阱的火焰和冰霜陷阱的冰面分別持續20秒和30秒。冰凍期間若你的其他增益效果消失，倒數會提前結束，因為遊戲無法區分它們。"
L["Off"] = "關閉"
L["%d s"] = "%d秒"

-- Sounds
L["Each trap's sounds are on the Sounds page, under this one."] = "每種陷阱的音效在此頁下方的「音效」頁中。"
L["Sounds"] = "音效"
L["Each trap's sounds: one as the warning before it runs out starts, one as its effect ends. Choosing a sound plays it."] = "每種陷阱的音效：一個在消失前的警告開始時播放，一個在效果結束時播放。選擇音效時會試聽。"
L["Before it runs out"] = "消失前"
L["When its effect ends"] = "效果結束時"
L["None"] = "無"
L["Raid warning"] = "團隊警告"
L["Boss emote"] = "首領表情"
L["Boss whisper"] = "首領密語"
L["Ready check"] = "準備確認"
L["Alarm clock %d"] = "鬧鐘 %d"
L["Whisper"] = "密語"
L["Notification"] = "通知"
