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
L["/htt test - show test traps"] = "/htt test - 테스트용 덫 표시"
L["/htt clear - clear the countdown, should it go wrong"] = "/htt clear - 카운트다운이 잘못되면 지우기"
L["countdown cleared."] = "카운트다운을 지웠습니다."
L["there is no countdown to clear."] = "지울 카운트다운이 없습니다."
L["/htt reset - restore the default settings"] = "/htt reset - 기본 설정으로 되돌리기"
L["open the game menu, then Options > AddOns > Hunter Trap Timer."] = "게임 메뉴를 연 다음 설정 > 애드온 > Hunter Trap Timer로 이동하세요."

-- Icon
L["Drag to move, then /htt lock"] = "끌어서 옮긴 다음 /htt lock"
L["Enemy frozen"] = "적 빙결됨"
L["Burning"] = "불타는 중"
L["Ice on the ground"] = "바닥의 얼음"
L["Fire on the ground"] = "바닥의 불길"

-- Options
L["Shows how long your traps stay armed: 60 seconds, unless something steps on them. WoW Forever hides the combat log from addons, but the game still tells them when your trap springs, however far away you are."] = "덫이 무장된 채로 남는 시간을 표시합니다: 무언가가 밟지 않는 한 60초입니다. WoW Forever는 애드온에 전투 기록을 숨기지만, 덫이 발동하면 아무리 멀리 있어도 게임이 알려줍니다."
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
L["Shows a fire trap and a frost trap that run out in 20 and 15 seconds."] = "20초와 15초 후에 사라지는 화염 덫과 냉기 덫을 표시합니다."
L["Reset position"] = "위치 초기화"
L["Warning before it runs out"] = "사라지기 전 경고"
L["Seconds left"] = "남은 시간(초)"
L["Flash the icon"] = "아이콘 깜박이기"
L["After a trap springs"] = "덫이 발동한 뒤"
L["Show how long its effect lasts"] = "효과 지속 시간 표시"
L["The trap's icon stays and counts down its effect, however far away you are: Freezing Trap's freeze until the enemy breaks free, Immolation Trap's burn until the enemy it burns dies or you leave combat, and the fire of Explosive Trap and the ice of Frost Trap for their 20 and 30 seconds. Another of your buffs fading during a freeze ends it early, as the game does not tell them apart."] = "아무리 멀리 있어도 덫의 아이콘이 남아 효과 시간을 셉니다: 얼음의 덫은 적이 풀려날 때까지, 제물의 덫은 불타는 적이 죽거나 전투에서 벗어날 때까지, 폭발의 덫의 불길과 냉기의 덫의 얼음은 각각 20초와 30초 동안입니다. 빙결 중에 다른 강화 효과가 사라지면 게임이 둘을 구분하지 않아 일찍 끝납니다."
L["Off"] = "끄기"
L["%d s"] = "%d초"

-- Sounds
L["Each trap's sounds are on the Sounds page, under this one."] = "덫마다의 소리는 이 페이지 아래의 소리 페이지에 있습니다."
L["Sounds"] = "소리"
L["Each trap's sounds: one as the warning before it runs out starts, one as its effect ends. Choosing a sound plays it."] = "덫마다 소리를 고릅니다: 하나는 만료 전 경고가 시작될 때, 하나는 효과가 끝날 때 재생됩니다. 소리를 고르면 들려줍니다."
L["Before it runs out"] = "만료되기 전"
L["When its effect ends"] = "효과가 끝날 때"
L["None"] = "없음"
L["Raid warning"] = "공격대 경보"
L["Boss emote"] = "우두머리 감정 표현"
L["Boss whisper"] = "우두머리 귓속말"
L["Ready check"] = "전투 준비 확인"
L["Alarm clock %d"] = "알람 시계 %d"
L["Whisper"] = "귓속말"
L["Notification"] = "알림"
