-- 한국어
local _, ns = ...
if ns.LOCALE ~= "koKR" then
    return
end
local L = ns.L

-- Chat
L["icon unlocked: drag it where you want it, then /htt lock."] = "아이콘 잠금 해제: 원하는 곳으로 끌어 놓은 다음 /htt lock을 입력하세요."
L["icon locked."] = "아이콘을 잠갔습니다."
L["settings reset to the defaults."] = "설정을 기본값으로 초기화했습니다."
L["/htt - open the options"] = "/htt - 설정 열기"
L["/htt unlock, /htt lock - move the icon"] = "/htt unlock, /htt lock - 아이콘 옮기기"
L["/htt test - show a test trap"] = "/htt test - 테스트용 덫 표시"
L["/htt reset - restore the default settings"] = "/htt reset - 기본 설정으로 되돌리기"
L["open the game menu, then Options > AddOns > Hunter Trap Timer."] = "게임 메뉴를 연 다음 설정 > 애드온 > Hunter Trap Timer로 이동하세요."

-- Icon
L["Drag to move, then /htt lock"] = "끌어서 옮긴 다음 /htt lock"

-- Options
L["Shows how long your trap stays armed: 60 seconds, unless something steps on it. WoW Forever hides the combat log from addons, and enemy auras in combat, so a trap that springs is recognized by a new aura on an enemy that nothing else explains. In a group other players' auras could be taken for it, so there the countdown runs to its end."] = "덫이 설치된 채로 얼마나 남는지 표시합니다. 무언가 밟지 않는 한 60초입니다. WoW Forever는 애드온에 전투 기록을 숨기고 전투 중에는 적의 효과도 숨기므로, 발동한 덫은 다른 이유로 설명되지 않는 적의 새 효과로 알아냅니다. 파티에서는 다른 플레이어의 효과를 덫으로 착각할 수 있어 카운트다운이 끝까지 진행됩니다."
L["Icon"] = "아이콘"
L["Lock the icon"] = "아이콘 잠금"
L["Unlocked, the icon stays on screen and can be dragged with the mouse."] = "잠금을 해제하면 아이콘이 화면에 계속 표시되고 마우스로 끌어서 옮길 수 있습니다."
L["Icon size"] = "아이콘 크기"
L["Count down the effect once the trap springs"] = "덫이 발동하면 효과 시간 표시"
L["The icon turns green and counts down the effect on the enemy, such as the freeze of %s. It ends early if the enemy dies, and a freeze also if the enemy takes damage."] = "아이콘이 녹색으로 바뀌고 적에게 걸린 효과(예: %s의 빙결)의 남은 시간을 표시합니다. 적이 죽으면 일찍 끝나며, 빙결은 적이 피해를 입어도 끝납니다."
L["Test"] = "테스트"
L["Shows a trap that runs out in 15 seconds."] = "15초 후에 사라지는 덫을 표시합니다."
L["Reset position"] = "위치 초기화"
L["Warning before it runs out"] = "사라지기 전 경고"
L["Seconds left"] = "남은 시간(초)"
L["Flash the icon"] = "아이콘 깜박이기"
L["Play a sound"] = "소리 재생"
L["Off"] = "끄기"
L["%d s"] = "%d초"
