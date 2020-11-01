format PE console
entry start
include 'win32a.inc'

; Штанько Екатерина БПИ193
; Вариант 27

N  = 4 ; 1-е использование: 4 точки в массиве. 2-е использование: смещение к Y
M  = 8 ; смещение в массиве к другой точке
;--------------------------------------------------------------------------
section '.data' data readable writable
    msgIn   db  'input points', 10, 0
    msgerr  db  'input error', 10, 0 
    msgrep  db  'repeated values', 10, 0
    points  rd   M + N ;координаты и под хранение точки пересечения.

    msgOK   db  'yes the points belong to the circle', 10, 0
    msgNO   db  'no, the points do not belong to the circle' , 10, 0
    fmt     db  '%g', 0  ;В зависимости от того, какой формат короче, применяется либо
                         ;%e числа с плавающей запятой в экспоненциальной форме записи ), либо
                         ;%f(Десятичное число с плавающей точкой)
    
    a1      dd  ?  ;(Определяем неинициализированную переменную размером 4 байта)
    b1      dd  ?
    d1      dd  ?

    a2      dd  ?
    b2      dd  ?
    d2      dd  ?
    
    dir1    rd  2
    dir2    rd  2
    s1      rd  2
    s2      rd  2
     
    u       dd  ?
       
    scale1  dd  10000.0
    scale2  dd  0.0001

;--------------------------------------------------------------------------
section '.code' code readable executable
start:

; Считываем координаты четырех точек, при этом осуществляя проверку на повторы
;(Предполагается, что пользователь не может ввести координаты одной
; и той же точки дважды)

;приглашение к вводу
  invoke printf, msgIn
;адреса массива под X
  mov esi, points
;адрес смещения под Y
  mov edi, points + N

 ;в циклее вводим 4 точки
  mov ebx, 0;счетчик
.input:
 ;ввод X
  cinvoke scanf, fmt, esi
 ;првоерка ввода
  cmp eax, 0
je  .error
 
 ;ввод Y
  cinvoke scanf, fmt, edi
 ;првоерка ввода
  cmp eax, 0
je  .error

  inc  ebx;увеличиваем значение счетчика на единицу
   ;если это первые введенные координаты(значение счетчика = 1) проверка на повторы ненужна
  cmp  ebx, 1
je .inp
  ; если это не первые введенные координаты,
  ; ищем повторы. (Предполагается, что пользователь не может ввести координаты одной
  ; и той же точки дважды)
  push edi
  mov  edi, points

  mov  ecx, ebx
  dec  ecx  ;то, скольоко будет повторяться цикл repeat. А повторяться он должен (кол-во введенных элементов(ebx) - 1)
.repeat:
  ;сравниваем x
  fld dword [edi] ;загрузка вещественного значения в стек регистров FPU.
  fld dword [esi]
  call Compare
  ;если x неравны, то можно не сравнивать y
jne .next_val
  fld dword [edi + N]
  fld dword [esi + N]
  call Compare
je .repeated

.next_val:
  add edi, M ;сдвигаемся к новому значению
loop .repeat

pop edi
  
.inp:   
 ;смещаемся дальше по массиву
  add esi, M
  add edi, M

  cmp ebx, N
  ;если введено 4 точки - идем дальше, иначе - продолжаем ввод.
jne .input

;--------------------------------------------------------------------------------


  ; Вычисление по условию пересечения хорд
  ; Если AC U BD = P, AP * PC = DP * PB, то A, B, C, D лежат на одной окружности


;--------------------------------------------------------------------------------

  ; Поиск точки пересечения
   
  ; Упорядочим вершины
  ; Cортируем точки по X
  ; Отсортированные точки условно обозначим как 1 2 3 4
  mov ecx, N
.begin_sort:
  push ecx
  mov  esi, points 
  mov  edi, points + M  ;смещаемся к следующей точке

  mov  ecx, N-1
.sort:
  fld dword [esi]
  fld dword [edi]
  call Compare
  ;если больше, идем дальше
  ja  .next 
  ; иначе делаем обмен  
  call swap
.next:
  add esi, M 
  add edi, M
  loop .sort

  pop ecx
loop .begin_sort   
      
  ; формируем комбинацию 1 4 2 3
   
  ; меняем местами вторую и третью точки ( 1 2 3 4 ) -> ( 1 3 2 4 )
  mov  esi, points + 1*M
  mov  edi, points + 2*M 
  call swap  
  
  ; меняем местами вторую и четвертую точки ( 1 3 2 4 ) -> ( 1 4 2 3 )
  mov  esi, points + 1*M
  mov  edi, points + 3*M 
  call swap 

  mov ebx, -1 
.next_pair: 
  inc ebx
  cmp ebx,  2
  ;если точку пересечения не удалось найти ни при комбинации ( 1 4 2 3 ), ни при ( 1 3 2 4 )
  ;выводим соответствующее сообщение
  je  .no
  cmp ebx,  1 
  je  .next_combination
jmp .calc  

  ;Если точка пересечения при рассмотрени комбинации ( 1 4 2 3 ) не была найдена,
  ;формируем новую комбинацию ( 1 3 2 4 ) и повторяем попытку.
.next_combination:
  ; меняем местами вторую и четвертую точки ( 1 4 2 3 ) -> ( 1 3 2 4 )
  mov  esi, points + 1*M
  mov  edi, points + 3*M 
  call swap

.calc:
; Алгоритм нахождения точки пересечения описан в ПЗ

; start1 - точка "начала" рассматриваемой хорды.
; end1 - точка "конца" рассматриваемой хорды.

; Point2f dir1 = end1 - start1;
  mov esi, points + 0*M
  mov edi, points + 1*M

  fld dword [edi]    ;Загрузить вещественное значение
  fsub dword [esi]   ;Вычитание
  fstp dword [dir1]  ;Сохранить вещественное значение с извлечением из стека

  fld dword [edi + N]
  fsub dword [esi + N]
  fstp dword [dir1 + N]

; Point2f dir2 = end2 - start2;
  mov esi, points + 2*M
  mov edi, points + 3*M
      
  fld  dword [edi]
  fsub dword [esi]
  fstp dword [dir2]
     
  fld  dword [edi + N]
  fsub dword [esi + N]
  fstp dword [dir2 + N]

;считаем уравнения прямых проходящих через отрезки

; float a1 = -dir1.y;
  fldz                 ;Загрузить константу +0.0
  fld  dword [dir1+N]  ;Загрузить вещественное значение dir1.y
  fsubp                ;Вычитание с извлечением из стека
  fstp dword [a1]      ;Сохранить вещественное значение с извлечением из стека
  
; float b1 = +dir1.x;
  fld  dword [dir1]
  fabs                 ;Абсолютное значение
  fstp dword [b1]
  
; float d1 = -(a1*start1.x + b1*start1.y);
  mov esi, points + 0*M
  fld  dword [esi]
  fmul dword [a1]
  fld  dword [esi+N]
  fmul dword [b1]
  faddp               ;Сложение с извлечением из стека
  fldz                ;Загрузить константу +0.0
  fxch                ;Обменять содержимое регистров
  fsubp               ;Вычитание с извлечением из стека
  fstp dword [d1]

; float a2 = -dir2.y;
  fldz
  fld  dword [dir2+N]
  fsubp
  fstp dword [a2]
    
; float b2 = +dir2.x;
  fld  dword [dir2]
  fabs
  fstp dword [b2]
  
; float d2 = -(a2*start2.x + b2*start2.y);
  mov esi, points + 2*M
  fld  dword [esi]
  fmul dword [a2]
  fld  dword [esi+N]
  fmul dword [b2]
  faddp
  fldz
  fxch
  fsubp
  fstp dword [d2]
        
; подставляем концы отрезков, для выяснения в каких полуплоскотях они

; float seg1_start = a2*start1.x + b2*start1.y + d2;
  mov esi, points + 0*M
  fld dword [esi]
  fmul dword [a2]
  
  fld dword [esi + N]
  fmul dword [b2]
  
  fadd dword [d2]
  faddp
  fstp dword [s1]
  
; float seg1_end = a2*end1.x + b2*end1.y + d2;
  mov esi, points + 1*M 
  fld dword [esi]
  fmul dword [a2]
  
  fld dword [esi + N]
  fmul dword [b2]
  
  fadd dword [d2]
  faddp
  fstp dword [s1 + N]
; float seg2_start = a1*start2.x + b1*start2.y + d1;
  mov esi, points + 2*M 
  fld dword [esi]
  fmul dword [a1]
  
  fld dword [esi + N]
  fmul dword [b1]
  
  fadd dword [d1]
  faddp
  fstp dword [s2]  
; float seg2_end = a1*end2.x + b1*end2.y + d1;
  mov esi, points + 3*M 
  fld dword [esi]
  fmul dword [a1]
  
  fld dword [esi + N]
  fmul dword [b1]
  
  fadd dword [d1]
  faddp
  fstp dword [s2 + N] 
  
; если концы одного отрезка имеют один знак, значит он в одной полуплоскости и пересечения нет.
; seg1_start * seg1_end >= 0
  fld dword [s1]
  fmul dword [s1 + N]
  fldz
  fxch
  call Compare
  jae  .next_pair
  
; seg2_start * seg2_end >= 0
  fld dword [s2]
  fmul dword [s2 + N]
  fldz
  fxch
  call Compare
  jae  .next_pair

; float u = seg1_start / (seg1_start - seg1_end);
  mov esi, s1
  fld dword [esi]
  fld dword [esi]
  fsub dword [esi + N]
  fdivp
  fstp dword [u]
  
;out_intersection =  start1 + u*dir1;
  mov esi, points + 4*M
  fld dword [u]
  fmul dword [dir1]
  fadd dword [points]
  fld dword [scale1]
  call scale  ;избавляемся от неточности
  fld dword [scale2]
  call scale 
  fstp dword [esi]

  mov esi, points + 4*M
  fld dword [u]
  fmul dword [dir1 + N]
  fadd dword [points + N]
  fld dword [scale1] ;scale1  =  10000.0
  call scale
  fld dword [scale2] ;scale2  =  0.0001
  call scale
  fstp dword [esi + N]

;--------------------------------------------------------------------------------
  ; расчет расстояний

  mov esi, points + 0*M
  mov edi, points + 4*M
  call GetHipotenuza
  
  mov esi, points + 4*M
  mov edi, points + 1*M
  call GetHipotenuza
  
  fmulp ; произведение пересечения первой хорды
  fld dword [scale2]
  call scale  
  
  mov esi, points + 2*M
  mov edi, points + 4*M
  call GetHipotenuza
  
  mov esi, points + 4*M
  mov edi, points + 3*M
  call GetHipotenuza
  
  fmulp ; произведенеи пересечения второй хорды
  fld dword [scale2]
  call scale
              
  ;проверка равенства
  call Compare
  jne .next_pair

.ok:
  invoke printf, msgOK 
jmp .exit  
.no:
  invoke printf, msgNO  
jmp .exit 
.repeated:
  invoke printf, msgrep
  jmp .exit 
.error:
  invoke printf, msgerr
.exit:
  invoke getch
  invoke ExitProcess, 0
  
;--------------------------------------------------------------------------------

; обмен координат в массиве 
proc swap
  ; обмен X
  fld  dword [esi] ;Загрузить вещественное значение в стек
  fld  dword [edi]
  fstp dword [esi] ;Сохранить вещественное значение с извлечением из стека
  fstp dword [edi]
  
  ; обмен Y
  fld  dword [esi + N]
  fld  dword [edi + N]
  fstp dword [esi + N]
  fstp dword [edi + N]
ret
endp

proc GetHipotenuza
  ; адрес 1 точки esi
  ; адрес 2 точки edi 
  fld dword [esi]
  fld dword [edi]
  ; катет по X
  call GetLength
  fmul  st0, st0

  fld dword [esi + N]
  fld dword [edi + N]
  ; катет по Y
  call GetLength
  fmul  st0, st0
  
  ; сумма квадратов катетов
  faddp       
  fsqrt
  ret  
endp
  
; расстояние между 2 координатами
proc GetLength     
    ;делаем вычитание   
    fsubp
    fabs
    ret  
endp

; Сравнение
proc Compare
    fcomip   st0, st1;Сравнить вещественные значения, извлечь одно из стека и по результату установить флаги
    fstp     st0     ;Сохранить вещественное значение с извлечением из стека
    ret
endp  

; Чтобы избавиться от неточности
proc scale
  fmulp
  call ceil
  ret 
endp 

proc ceil
  fld st0     ;Дублирует вершину стека(наше значение)
  fld1        ;Загрузить константу +1.0
  fxch
  fprem       ;Найти частичный остаток деления на 1.0(числа после запятой)
  fsubp st2, st0  ;Вычитаем из изначального значения "округленное"
  fstp st0
  ret
endp

section '.idata' import data readable
library kernel, 'kernel32.dll',msvcrt, 'msvcrt.dll',user32,'user32.dll'

include 'api\user32.inc'
include 'api\kernel32.inc'
import kernel, ExitProcess, 'ExitProcess'

include 'api\kernel32.inc'
import msvcrt, printf, 'printf', scanf, 'scanf', getch, '_getch'
