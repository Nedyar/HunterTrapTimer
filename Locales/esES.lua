-- Español (EU)
local _, ns = ...
if ns.LOCALE ~= "esES" then
    return
end
local L = ns.L

-- Chat
L["icon unlocked: drag it where you want it, then /htt lock."] = "icono desbloqueado: arrástralo adonde quieras y luego /htt lock."
L["icon locked."] = "icono bloqueado."
L["settings reset to the defaults."] = "ajustes restablecidos a los valores predeterminados."
L["/htt - open the options"] = "/htt - abrir las opciones"
L["/htt unlock, /htt lock - move the icon"] = "/htt unlock, /htt lock - mover el icono"
L["/htt test - show a test trap"] = "/htt test - mostrar una trampa de prueba"
L["/htt reset - restore the default settings"] = "/htt reset - restablecer los ajustes predeterminados"
L["open the game menu, then Options > AddOns > Hunter Trap Timer."] = "abre el menú de juego y luego Opciones > Addons > Hunter Trap Timer."

-- Icon
L["Drag to move, then /htt lock"] = "Arrastra para mover y luego /htt lock"

-- Options
L["Shows how long your trap stays armed: 60 seconds, unless something steps on it. WoW Forever hides the combat log from addons, and enemy auras in combat, so a trap that springs is recognized by a new aura on an enemy that nothing else explains. In a group other players' auras could be taken for it, so there the countdown runs to its end."] = "Muestra cuánto tiempo sigue armada tu trampa: 60 segundos, salvo que algo la pise. WoW Forever oculta a los addons el registro del combate, y en combate también las auras de los enemigos, así que una trampa que salta se reconoce por un aura nueva en un enemigo que nada más explica. En grupo se podrían confundir con ella las auras de otros jugadores, así que allí la cuenta atrás llega hasta el final."
L["Icon"] = "Icono"
L["Lock the icon"] = "Bloquear el icono"
L["Unlocked, the icon stays on screen and can be dragged with the mouse."] = "Desbloqueado, el icono se queda en pantalla y se puede arrastrar con el ratón."
L["Icon size"] = "Tamaño del icono"
L["Count down the effect once the trap springs"] = "Contar el efecto cuando salte la trampa"
L["The icon turns green and counts down the effect on the enemy, such as the freeze of %s. It ends early if the enemy dies, and a freeze also if the enemy takes damage."] = "El icono se pone verde y cuenta el efecto en el enemigo, como la congelación de %s. Termina antes si el enemigo muere, y una congelación también si el enemigo recibe daño."
L["Test"] = "Probar"
L["Shows a trap that runs out in 15 seconds."] = "Muestra una trampa que caduca en 15 segundos."
L["Reset position"] = "Restablecer posición"
L["Warning before it runs out"] = "Aviso antes de que caduque"
L["Seconds left"] = "Segundos restantes"
L["Flash the icon"] = "Hacer parpadear el icono"
L["Play a sound"] = "Reproducir un sonido"
L["Off"] = "Desactivado"
L["%d s"] = "%d s"
