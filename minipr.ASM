format PE console
entry start
include 'win32a.inc'


N  = 4 ; 1-� �������������: 4 ����� � �������. 2-� �������������: �������� � Y
M  = 8 ; �������� � ������� � ������ �����
;--------------------------------------------------------------------------
section '.data' data readable writable
    msgIn   db  'input points', 10, 0
    msgerr  db  'input error', 10, 0 
    msgrep  db  'repeated values', 10, 0
    points  rd   M + N ;���������� � ��� �������� ����� �����������.

    msgOK   db  'yes the points belong to the circle', 10, 0
    msgNO   db  'no, the points do not belong to the circle' , 10, 0
    fmt     db  '%g', 0  ;� ����������� �� ����, ����� ������ ������, ����������� ����
                         ;%e ����� � ��������� ������� � ���������������� ����� ������ ), ����
                         ;%f(���������� ����� � ��������� ������)
    
    a1      dd  ?  ;(���������� �������������������� ���������� �������� 4 �����)
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

; ��������� ���������� ������� �����, ��� ���� ����������� �������� �� �������
;(��������������, ��� ������������ �� ����� ������ ���������� �����
; � ��� �� ����� ������)

;����������� � �����
  invoke printf, msgIn
;������ ������� ��� X
  mov esi, points
;����� �������� ��� Y
  mov edi, points + N

 ;� ������ ������ 4 �����
  mov ebx, 0;�������
.input:
 ;���� X
  cinvoke scanf, fmt, esi
 ;�������� �����
  cmp eax, 0
je  .error
 
 ;���� Y
  cinvoke scanf, fmt, edi
 ;�������� �����
  cmp eax, 0
je  .error

  inc  ebx;����������� �������� �������� �� �������
   ;���� ��� ������ ��������� ����������(�������� �������� = 1) �������� �� ������� �������
  cmp  ebx, 1
je .inp
  ; ���� ��� �� ������ ��������� ����������,
  ; ���� �������. (��������������, ��� ������������ �� ����� ������ ���������� �����
  ; � ��� �� ����� ������)
  push edi
  mov  edi, points

  mov  ecx, ebx
  dec  ecx  ;��, �������� ����� ����������� ���� repeat. � ����������� �� ������ (���-�� ��������� ���������(ebx) - 1)
.repeat:
  ;���������� x
  fld dword [edi] ;�������� ������������� �������� � ���� ��������� FPU.
  fld dword [esi]
  call Compare
  ;���� x �������, �� ����� �� ���������� y
jne .next_val
  fld dword [edi + N]
  fld dword [esi + N]
  call Compare
je .repeated

.next_val:
  add edi, M ;���������� � ������ ��������
loop .repeat

pop edi
  
.inp:   
 ;��������� ������ �� �������
  add esi, M
  add edi, M

  cmp ebx, N
  ;���� ������� 4 ����� - ���� ������, ����� - ���������� ����.
jne .input

;--------------------------------------------------------------------------------


  ; ���������� �� ������� ����������� ����
  ; ���� AC U BD = P, AP * PC = DP * PB, �� A, B, C, D ����� �� ����� ����������


;--------------------------------------------------------------------------------

  ; ����� ����� �����������
   
  ; ���������� �������
  ; C�������� ����� �� X
  ; ��������������� ����� ������� ��������� ��� 1 2 3 4
  mov ecx, N
.begin_sort:
  push ecx
  mov  esi, points 
  mov  edi, points + M  ;��������� � ��������� �����

  mov  ecx, N-1
.sort:
  fld dword [esi]
  fld dword [edi]
  call Compare
  ;���� ������, ���� ������
  ja  .next 
  ; ����� ������ �����  
  call swap
.next:
  add esi, M 
  add edi, M
  loop .sort

  pop ecx
loop .begin_sort   
      
  ; ��������� ���������� 1 4 2 3
   
  ; ������ ������� ������ � ������ ����� ( 1 2 3 4 ) -> ( 1 3 2 4 )
  mov  esi, points + 1*M
  mov  edi, points + 2*M 
  call swap  
  
  ; ������ ������� ������ � ��������� ����� ( 1 3 2 4 ) -> ( 1 4 2 3 )
  mov  esi, points + 1*M
  mov  edi, points + 3*M 
  call swap 

  mov ebx, -1 
.next_pair: 
  inc ebx
  cmp ebx,  2
  ;���� ����� ����������� �� ������� ����� �� ��� ���������� ( 1 4 2 3 ), �� ��� ( 1 3 2 4 )
  ;������� ��������������� ���������
  je  .no
  cmp ebx,  1 
  je  .next_combination
jmp .calc  

  ;���� ����� ����������� ��� ����������� ���������� ( 1 4 2 3 ) �� ���� �������,
  ;��������� ����� ���������� ( 1 3 2 4 ) � ��������� �������.
.next_combination:
  ; ������ ������� ������ � ��������� ����� ( 1 4 2 3 ) -> ( 1 3 2 4 )
  mov  esi, points + 1*M
  mov  edi, points + 3*M 
  call swap

.calc:
; �������� ���������� ����� ����������� ������ � ��

; start1 - ����� "������" ��������������� �����.
; end1 - ����� "�����" ��������������� �����.

; Point2f dir1 = end1 - start1;
  mov esi, points + 0*M
  mov edi, points + 1*M

  fld dword [edi]    ;��������� ������������ ��������
  fsub dword [esi]   ;���������
  fstp dword [dir1]  ;��������� ������������ �������� � ����������� �� �����

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

;������� ��������� ������ ���������� ����� �������

; float a1 = -dir1.y;
  fldz                 ;��������� ��������� +0.0
  fld  dword [dir1+N]  ;��������� ������������ �������� dir1.y
  fsubp                ;��������� � ����������� �� �����
  fstp dword [a1]      ;��������� ������������ �������� � ����������� �� �����
  
; float b1 = +dir1.x;
  fld  dword [dir1]
  fabs                 ;���������� ��������
  fstp dword [b1]
  
; float d1 = -(a1*start1.x + b1*start1.y);
  mov esi, points + 0*M
  fld  dword [esi]
  fmul dword [a1]
  fld  dword [esi+N]
  fmul dword [b1]
  faddp               ;�������� � ����������� �� �����
  fldz                ;��������� ��������� +0.0
  fxch                ;�������� ���������� ���������
  fsubp               ;��������� � ����������� �� �����
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
        
; ����������� ����� ��������, ��� ��������� � ����� ������������� ���

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
  
; ���� ����� ������ ������� ����� ���� ����, ������ �� � ����� ������������� � ����������� ���.
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
  call scale  ;����������� �� ����������
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
  ; ������ ����������

  mov esi, points + 0*M
  mov edi, points + 4*M
  call GetHipotenuza
  
  mov esi, points + 4*M
  mov edi, points + 1*M
  call GetHipotenuza
  
  fmulp ; ������������ ����������� ������ �����
  fld dword [scale2]
  call scale  
  
  mov esi, points + 2*M
  mov edi, points + 4*M
  call GetHipotenuza
  
  mov esi, points + 4*M
  mov edi, points + 3*M
  call GetHipotenuza
  
  fmulp ; ������������ ����������� ������ �����
  fld dword [scale2]
  call scale
              
  ;�������� ���������
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

; ����� ��������� � ������� 
proc swap
  ; ����� X
  fld  dword [esi] ;��������� ������������ �������� � ����
  fld  dword [edi]
  fstp dword [esi] ;��������� ������������ �������� � ����������� �� �����
  fstp dword [edi]
  
  ; ����� Y
  fld  dword [esi + N]
  fld  dword [edi + N]
  fstp dword [esi + N]
  fstp dword [edi + N]
ret
endp

proc GetHipotenuza
  ; ����� 1 ����� esi
  ; ����� 2 ����� edi 
  fld dword [esi]
  fld dword [edi]
  ; ����� �� X
  call GetLength
  fmul  st0, st0

  fld dword [esi + N]
  fld dword [edi + N]
  ; ����� �� Y
  call GetLength
  fmul  st0, st0
  
  ; ����� ��������� �������
  faddp       
  fsqrt
  ret  
endp
  
; ���������� ����� 2 ������������
proc GetLength     
    ;������ ���������   
    fsubp
    fabs
    ret  
endp

; ���������
proc Compare
    fcomip   st0, st1;�������� ������������ ��������, ������� ���� �� ����� � �� ���������� ���������� �����
    fstp     st0     ;��������� ������������ �������� � ����������� �� �����
    ret
endp  

; ����� ���������� �� ����������
proc scale
  fmulp
  call ceil
  ret 
endp 

proc ceil
  fld st0     ;��������� ������� �����(���� ��������)
  fld1        ;��������� ��������� +1.0
  fxch
  fprem       ;����� ��������� ������� ������� �� 1.0(����� ����� �������)
  fsubp st2, st0  ;�������� �� ������������ �������� "�����������"
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