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
L["/htt clear - clear the countdown, should it go wrong"] = "/htt clear - 카운트다운이 잘못되면 지우기"
L["countdown cleared."] = "카운트다운을 지웠습니다."
L["there is no countdown to clear."] = "지울 카운트다운이 없습니다."
L["/htt reset - restore the default settings"] = "/htt reset - 기본 설정으로 되돌리기"
L["open the game menu, then Options > AddOns > Hunter Trap Timer."] = "게임 메뉴를 연 다음 설정 > 애드온 > Hunter Trap Timer로 이동하세요."

-- Icon
L["Drag to move, then /htt lock"] = "끌어서 옮긴 다음 /htt lock"

-- Options
L["Shows how long your trap stays armed: 60 seconds, unless something steps on it. WoW Forever hides the combat log from addons, and enemy auras in combat, so a trap that springs is recognized by a new aura on an enemy that nothing else explains, such as a spell of yours, your pet's or your group's. In a group, an effect that comes without a spell, such as a poison, can now and then be taken for it."] = "덫이 설치된 채로 얼마나 남는지 표시합니다. 무언가 밟지 않는 한 60초입니다. WoW Forever는 애드온에 전투 기록을 숨기고 전투 중에는 적의 효과도 숨기므로, 발동한 덫은 내 주문, 소환수나 파티의 주문 등 다른 이유로 설명되지 않는 적의 새 효과로 알아냅니다. 파티에서는 독처럼 주문 없이 걸리는 효과를 가끔 덫으로 착각할 수 있습니다."
L["Icon"] = "아이콘"
L["Lock the icon"] = "아이콘 잠금"
L["Unlocked, the icon stays on screen and can be dragged with the mouse."] = "잠금을 해제하면 아이콘이 화면에 계속 표시되고 마우스로 끌어서 옮길 수 있습니다."
L["Icon size"] = "아이콘 크기"
L["Position"] = "위치"
L["Under the %s"] = "%s 아래"
L["Under your portrait, clear of your pet's frame. It follows the %s when Edit Mode moves it."] = "내 초상화 아래, 소환수 창을 가리지 않는 곳입니다. 편집 모드로 %s을 옮기면 함께 따라갑니다."
L["Free"] = "자유"
L["Where you drag it while the icon is unlocked."] = "아이콘 잠금을 해제한 상태에서 끌어 놓은 곳입니다."
L["Shape"] = "모양"
L["Round, like a totem"] = "원형 (토템처럼)"
L["Square"] = "사각형"
L["Seconds"] = "초"
L["Below the icon"] = "아이콘 아래"
L["On the icon"] = "아이콘 위"
L["Test"] = "테스트"
L["Shows a trap that runs out in 15 seconds."] = "15초 후에 사라지는 덫을 표시합니다."
L["Reset position"] = "위치 초기화"
L["Warning before it runs out"] = "사라지기 전 경고"
L["Seconds left"] = "남은 시간(초)"
L["Flash the icon"] = "아이콘 깜박이기"
L["Play a sound"] = "소리 재생"
L["Off"] = "끄기"
L["%d s"] = "%d초"
