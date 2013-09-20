; serv.exe
format PE console 
entry start

include 'C:\apps\fasmw\INCLUDE\win32a.inc'
;include 'C:\apps\fasmw\INCLUDE\win32ax.inc'
;include 'win32ax.inc'

;------------------------------------------
;structures
;------------------------------------------
struct SERVICE_STATUS
   dwServiceType                dd ?
   dwCurrentState               dd ?
   dwControlsAccepted           dd ?
   dwWin32ExitCode              dd ?
   dwServiceSpecificExitCode    dd ?
   dwCheckPoint                 dd ?
   dwWaitHint                   dd ?
ends
;------------------------------------------
;constants
;------------------------------------------
    SERVICE_CONTROL_SHUTDOWN    = 000000005h
    SERVICE_WIN32_OWN_PROCESS   = 000000010h
;dwCurrentState
    SERVICE_RUNNING             = 000000004h
    SERVICE_STOP_PENDING        = 000000003h
    SERVICE_STOPPED             = 000000001h
;dwControlsAccepted
    SERVICE_ACCEPT_SHUTDOWN     = 000000004h

    NO_ERROR                        = 000000000h
    ERROR_SERVICE_DOES_NOT_EXIST    = 000001060h


    SC_MANAGER_CONNECT              = 00001h
    SC_MANAGER_CREATE_SERVICE       = 00002h
    SC_MANAGER_ENUMERATE_SERVICE    = 00004h
    SC_MANAGER_LOCK                 = 00008h
    SC_MANAGER_QUERY_LOCK_STATUS    = 00010h
    SC_MANAGER_MODIFY_BOOT_CONFIG   = 00020h

    SC_MANAGER_ALL_ACCESS   = STANDARD_RIGHTS_REQUIRED + \
                    SC_MANAGER_CONNECT  + \
                    SC_MANAGER_CREATE_SERVICE + \
                    SC_MANAGER_ENUMERATE_SERVICE + \
                    SC_MANAGER_LOCK  + \
                    SC_MANAGER_QUERY_LOCK_STATUS + \
                    SC_MANAGER_MODIFY_BOOT_CONFIG

    SERVICE_QUERY_CONFIG            = 00001h
    SERVICE_CHANGE_CONFIG           = 00002h
    SERVICE_QUERY_STATUS            = 00004h
    SERVICE_ENUMERATE_DEPENDENTS    = 00008h
    SERVICE_START                   = 00010h
    SERVICE_STOP                    = 00020h
    SERVICE_PAUSE_CONTINUE          = 00040h
    SERVICE_INTERROGATE             = 00080h
    SERVICE_USER_DEFINED_CONTROL    = 00100h

    SERVICE_ALL_ACCESS  = STANDARD_RIGHTS_REQUIRED	  + \
                    SERVICE_QUERY_CONFIG	+ \
                    SERVICE_CHANGE_CONFIG	 + \
                    SERVICE_QUERY_STATUS      + \
                    SERVICE_ENUMERATE_DEPENDENTS  + \
                    SERVICE_START        + \
                    SERVICE_STOP        + \
                    SERVICE_PAUSE_CONTINUE	+ \
                    SERVICE_INTERROGATE      + \
                    SERVICE_USER_DEFINED_CONTROL


    SERVICE_START  = 00010h
    SERVICE_AUTO_START  = 000000002h

    WAIT_FOR = 1*1000   ; - @07 2 G0A

;--------------------------------------------
;data section
;--------------------------------------------
section '.data' readable writeable

    ws      WSADATA
    addr    sockaddr_in
    sSi     STARTUPINFO
    sPi     PROCESS_INFORMATION

    hSocket     dd ?
    hWorkSocket dd ?

    ;lpString            db "%s",10,0
    ;lpChar              db "%c",10,0
    ;lpInt               db "%i",10,0
    
    ;lpCommandTemplate   db "cmd.exe /c %s",0
    ;lpCombinedCommand   dd ?
    lpCommandLine       dd ?

    ServiceName         db 'JobRunner',0
    status              SERVICE_STATUS
    hService            dd ?
    ServiceTableEntry   dd ServiceName, ServiceMain, 0, 0
    hSC1                dd ?
    hSC2                dd ?
;============================================

;--------------------------------------------
;code section
;--------------------------------------------
section '.text' readable executable

start:
    invoke  OpenSCManager, 0, 0, SC_MANAGER_ALL_ACCESS
    mov     [hSC1], eax
    or      eax, eax
    jnz     @F
    jmp     endOpenSCManager
@@:
    invoke  OpenService, [hSC1], ServiceName, SERVICE_START
    mov     [hSC2], eax
    or      eax, eax
    jz      @F
    invoke  CloseServiceHandle, eax
    jmp     endOpenSCManager
@@:
    invoke  CloseServiceHandle, [hSC2]

endOpenSCManager:
    invoke  CloseServiceHandle, [hSC1]

    invoke  StartServiceCtrlDispatcher, ServiceTableEntry
    or      eax, eax
    jnz     exitProcess
    stdcall ServiceMain, dword 0, dword NULL

exitProcess:

start2:
    invoke  OpenSCManager, 0, 0, SC_MANAGER_ALL_ACCESS
    mov     [hSC1], eax
    or      eax, eax
    jnz     @F
    jmp     endOpenSCManager2
@@:
    invoke  OpenService, [hSC1], ServiceName, SERVICE_STOP
    mov     [hSC2], eax
    ;or      eax, eax
    ;jz      @F
    
    invoke  DeleteService, [hSC2]
    
    invoke  CloseServiceHandle, [hSC2]
;    jmp     endOpenSCManager2
;@@:
;    invoke  CloseServiceHandle, [hSC2]

endOpenSCManager2:
    invoke  CloseServiceHandle, [hSC1]


    invoke  ExitProcess, 0
;-----------------------------------------------------------------
;-----------------------------------------------------------------
;-----------------------------------------------------------------

proc ServiceMain, dwNU1, dwNU2
    ;Register service
    invoke  RegisterServiceCtrlHandler, ServiceName, Handler
    mov     [hService], eax
    ;Set service status
    invoke  RtlZeroMemory, status, sizeof.SERVICE_STATUS
    mov     [status.dwServiceType], SERVICE_WIN32_OWN_PROCESS
    mov     [status.dwCurrentState], SERVICE_RUNNING
    mov     [status.dwControlsAccepted], 0
    mov     [status.dwWin32ExitCode], NO_ERROR
    invoke  SetServiceStatus, [hService], status
;-----------------------Begin---Here you can insert you code-
    
    invoke GetCommandLine
    mov [lpCommandLine], eax
    
remove_arg0:
    mov eax, [lpCommandLine]
    cmp byte [eax], 32  ; are we at ' ' ?
    je find_arg1
    cmp byte [eax], 0   ; are we at end of the args?
    je find_arg1
    inc [lpCommandLine]
    jmp remove_arg0
    
find_arg1:
    mov eax, [lpCommandLine]
    cmp byte [eax], 0   ; are we at end of the args?
    je continue
    cmp byte [eax], 32  ; are we at ' ' ?
    je increment_and_loop
    
    jmp continue
    
increment_and_loop:
    inc [lpCommandLine]
    jmp find_arg1

continue:
    ;invoke strlen, [lpCommandLine]  ; ebx = strlen(lpCommandLine)
    ;mov ebx, eax
    ;invoke strlen, lpCommandTemplate    ; ebx += strlen(lpCommandTemplate)
    ;add ebx, eax
    ;
    ;; allocate memory for the new command line
    ;invoke malloc, ebx
    ;mov [lpCombinedCommand], eax
    ;
    ;; create new commandline
    ;invoke sprintf, [lpCombinedCommand], lpCommandTemplate, [lpCommandLine]

    ; run executable
    invoke CreateProcess,0,[lpCommandLine],0,0,0,CREATE_NEW_CONSOLE,0,0,sSi,sPi
 
    invoke  Sleep, WAIT_FOR 
    
    ; Tell Service manager we stopped
    mov     [status.dwCurrentState], SERVICE_STOPPED
    invoke  SetServiceStatus, [hService], status
    
    ; exit application
    ret
;__sleep:
;    invoke  Sleep, WAIT_FOR 
;    jmp     __sleep
;-----------------------End----------------------------------
endp

;------------------------------------------------------------
;------------------------------------------------------------
;------------------------------------------------------------
;Handle message for service
proc Handler, dwAction
;    cmp     [dwAction], SERVICE_CONTROL_SHUTDOWN
;    jnz     @F
;    invoke  ExitProcess, 0
;@@:
   ret
endp
;============================================

section '.idata' import data readable writeable
library  winsock, 'WS2_32.DLL',\
    kernel, 'KERNEL32.DLL',\
    advapi, 'ADVAPI32.DLL',\
    msvcrt,   'msvcrt.dll'

import kernel,\
    ExitProcess,  'ExitProcess',\
    CloseHandle,  'CloseHandle',\
    RtlZeroMemory,  'RtlZeroMemory',\
    Sleep,  'Sleep',\
    CreateProcess, 'CreateProcessA',\
    GetCommandLine, 'GetCommandLineA'

import advapi,\
    RegisterServiceCtrlHandler, 'RegisterServiceCtrlHandlerA',\
    SetServiceStatus,  'SetServiceStatus',\
    OpenSCManager,  'OpenSCManagerA',\
    OpenService,  'OpenServiceA',\
    DeleteService,  'DeleteService',\
    CloseServiceHandle,  'CloseServiceHandle',\
    StartServiceCtrlDispatcher, 'StartServiceCtrlDispatcherA'

import msvcrt,\
    sprintf, 'sprintf',\
    strlen, 'strlen',\
    malloc, 'malloc'
