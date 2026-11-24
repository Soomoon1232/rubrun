#Requires AutoHotkey v2.0
#SingleInstance Force
#MaxThreadsPerHotkey 2

; =====================================================================
;  F6 - старт/стоп      F7 - закрыть скрипт
;  F8 - ТЕСТ: проверить, видит ли скрипт зелёную кнопку (ничего не нажимает)
;
;  Каждую секунду жмёт E (физическая клавиша E = "У" в русской раскладке),
;  а когда появляется окно с зелёными кнопками - кликает по самой левой.
; =====================================================================

; ---------- НАСТРОЙКИ ----------
KeyInterval    := 1000       ; пауза между нажатиями E, мс
GreenColor     := 0xC3F930   ; цвет зелёной кнопки "ПОДТВЕРДИТЬ" (RGB)
Variation      := 12         ; допуск по цвету 0-255
BandTop        := 0.66       ; зона поиска по высоте окна игры: от 66%
BandBottom     := 0.82       ;                                  до 82%
OffsetX        := 20         ; куда кликать относительно найденного угла кнопки
OffsetY        := 12
StopAfterClick := true       ; true = после клика остановиться
; -------------------------------

; Игры часто игнорируют ввод от скрипта без прав администратора
if !A_IsAdmin {
    if A_IsCompiled
        Run '*RunAs "' A_ScriptFullPath '"'
    else
        Run '*RunAs "' A_AhkPath '" "' A_ScriptFullPath '"'
    ExitApp
}

SetKeyDelay 30, 50        ; пауза между нажатиями и время удержания клавиши (мс)
SetMouseDelay 30
CoordMode "Pixel", "Screen"
CoordMode "Mouse", "Screen"

running := false

F6:: {
    global running
    running := !running
    Notify(running ? "Макрос ВКЛ (F6 - стоп)" : "Макрос ВЫКЛ")
    if running
        MainLoop()
}

F7::ExitApp

F8:: {
    if FindGreen(&x, &y)
        Notify("Кнопка НАЙДЕНА, клик пошёл бы в: " x ", " y)
    else
        Notify("Кнопка НЕ найдена")
}

MainLoop() {
    global running
    while running {
        SendEvent "{sc012}"                 ; scan-код клавиши E - работает в любой раскладке
        t := A_TickCount
        while running && A_TickCount - t < KeyInterval {
            if TryClick() {
                if StopAfterClick {
                    running := false
                    Notify("Кнопка нажата, макрос остановлен")
                    return
                }
                Sleep 1500                  ; дать окну закрыться
                break
            }
            Sleep 100
        }
    }
}

; Ищет зелёную кнопку, ждёт окончания анимации окна и кликает
TryClick() {
    if !FindGreen(&x, &y)
        return false
    Sleep 250                               ; окно могло ещё "выезжать"
    if !FindGreen(&x, &y)
        return false
    MouseMove x + 2, y + 2, 0
    Sleep 50
    MouseMove x, y, 0
    Sleep 50
    Click "down"
    Sleep 60
    Click "up"
    return true
}

; Ищет ЗАЛИТЫЙ зелёный прямоугольник в нижней части окна игры.
; Тонкие зелёные рамки меню и иконки на карте не подходят.
FindGreen(&cx, &cy) {
    try {
        WinGetClientPos &wx, &wy, &ww, &wh, "A"
        y1 := wy + Round(wh * BandTop)
        y2 := wy + Round(wh * BandBottom)
        if !PixelSearch(&px, &py, wx, y1, wx + ww, y2, GreenColor, Variation)
            return false
        for dx in [10, 40, 80]
            for dy in [6, 14, 20]
                if !Near(PixelGetColor(px + dx, py + dy), GreenColor, Variation)
                    return false
        cx := px + OffsetX
        cy := py + OffsetY
        return true
    } catch {
        return false
    }
}

Near(c1, c2, v) {
    return Abs((c1 >> 16 & 255) - (c2 >> 16 & 255)) <= v
        && Abs((c1 >> 8 & 255) - (c2 >> 8 & 255)) <= v
        && Abs((c1 & 255) - (c2 & 255)) <= v
}

Notify(text) {
    ToolTip text
    SetTimer () => ToolTip(), -1500
}
