-- Español (Latinoamérica)
local _, ns = ...
if ns.LOCALE ~= "esMX" then
    return
end
local L = ns.L

-- Chat
L["icon unlocked: drag it where you want it, then /htt lock."] = "ícono desbloqueado: arrástralo a donde quieras y luego /htt lock."
L["icon locked."] = "ícono bloqueado."
L["settings reset to the defaults."] = "configuración restablecida a los valores predeterminados."
L["/htt - open the options"] = "/htt - abrir las opciones"
L["/htt unlock, /htt lock - move the icon"] = "/htt unlock, /htt lock - mover el ícono"
L["/htt test - show test traps"] = "/htt test - mostrar trampas de prueba"
L["/htt clear - clear the countdown, should it go wrong"] = "/htt clear - borrar la cuenta regresiva, por si falla"
L["countdown cleared."] = "cuenta regresiva borrada."
L["there is no countdown to clear."] = "no hay ninguna cuenta regresiva que borrar."
L["/htt reset - restore the default settings"] = "/htt reset - restablecer la configuración predeterminada"
L["open the game menu, then Options > AddOns > Hunter Trap Timer."] = "abre el menú de juego y luego Opciones > AddOns > Hunter Trap Timer."

-- Icon
L["Drag to move, then /htt lock"] = "Arrastra para mover y luego /htt lock"
L["Enemy frozen"] = "Enemigo congelado"
L["Burning"] = "En llamas"
L["Ice on the ground"] = "Hielo en el suelo"
L["Fire on the ground"] = "Fuego en el suelo"

-- Options
L["Shows how long your traps stay armed: 60 seconds, unless something steps on them. WoW Forever hides the combat log from addons, but the game still tells them when your trap springs, however far away you are."] = "Muestra cuánto tiempo siguen armadas tus trampas: 60 segundos, salvo que algo las pise. WoW Forever oculta a los addons el registro del combate, pero el juego sí les avisa cuando salta tu trampa, por lejos que estés."
L["Icon"] = "Ícono"
L["Lock the icon"] = "Bloquear el ícono"
L["Unlocked, the icon stays on screen and can be dragged with the mouse."] = "Desbloqueado, el ícono permanece en pantalla y se puede arrastrar con el mouse."
L["Icon size"] = "Tamaño del ícono"
L["Position"] = "Posición"
L["Under the %s"] = "Bajo el %s"
L["Under your portrait, clear of your pet's frame. It follows the %s when Edit Mode moves it."] = "Bajo tu retrato, sin tapar el marco de tu mascota. Sigue al %s cuando lo mueves con el Modo de edición."
L["Free"] = "Libre"
L["Where you drag it while the icon is unlocked."] = "Donde lo arrastres con el ícono desbloqueado."
L["Shape"] = "Forma"
L["Round, like a totem"] = "Redonda, como un tótem"
L["Square"] = "Cuadrada"
L["Seconds"] = "Segundos"
L["Below the icon"] = "Debajo del ícono"
L["On the icon"] = "Sobre el ícono"
L["Test"] = "Probar"
L["Shows a fire trap and a frost trap that run out in 20 and 15 seconds."] = "Muestra una trampa de fuego y otra de escarcha que expiran en 20 y 15 segundos."
L["Reset position"] = "Restablecer posición"
L["Warning before it runs out"] = "Aviso antes de que expire"
L["Seconds left"] = "Segundos restantes"
L["Flash the icon"] = "Hacer parpadear el ícono"
L["After a trap springs"] = "Cuando salta una trampa"
L["Show how long its effect lasts"] = "Mostrar cuánto dura su efecto"
L["The trap's icon stays and counts down its effect, however far away you are: Freezing Trap's freeze until the enemy breaks free, Immolation Trap's burn until the enemy it burns dies or you leave combat, and the fire of Explosive Trap and the ice of Frost Trap for their 20 and 30 seconds. Another of your buffs fading during a freeze ends it early, as the game does not tell them apart."] = "El icono de la trampa se queda y cuenta atrás su efecto, por lejos que estés: la congelación de la Trampa congelante hasta que el enemigo se suelta, la quemadura de la Trampa de inmolación hasta que muere el enemigo que quema o sales de combate, y el fuego de la Trampa explosiva y el hielo de la Trampa de escarcha durante sus 20 y 30 segundos. Si durante una congelación se acaba otro de tus beneficios, termina antes, porque el juego no los distingue."
L["Off"] = "Desactivado"
L["%d s"] = "%d s"

-- Sounds
L["Each trap's sounds are on the Sounds page, under this one."] = "Los sonidos de cada trampa están en la página Sonidos, debajo de esta."
L["Sounds"] = "Sonidos"
L["Each trap's sounds: one as the warning before it runs out starts, one as its effect ends. Choosing a sound plays it."] = "Los sonidos de cada trampa: uno cuando empieza el aviso antes de que caduque y otro cuando acaba su efecto. Al elegir un sonido, se reproduce."
L["Before it runs out"] = "Antes de que caduque"
L["When its effect ends"] = "Cuando acaba su efecto"
L["None"] = "Ninguno"
L["Raid warning"] = "Aviso de banda"
L["Boss emote"] = "Emoción de jefe"
L["Boss whisper"] = "Susurro de jefe"
L["Ready check"] = "Comprobación de listos"
L["Alarm clock %d"] = "Despertador %d"
L["Whisper"] = "Susurro"
L["Notification"] = "Notificación"
