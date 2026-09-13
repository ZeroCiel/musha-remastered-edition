; symbol_stubs.asm
; MASM stubs for old CRT/ABI symbols that MgmtServer links against
; but whose originals don't exist in VS2012 CRT.
;
; Compile: ml /c /Fo<out>\symbol_stubs.obj symbol_stubs.asm
; Link:    link ... %OUT%\symbol_stubs.obj ...

.486
.MODEL flat

; ========== std::string::_Myptr() const ==========
; Existed in VS2003-2010 CRT, removed in VS2012+
PUBLIC ?_Myptr@?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QBEPBDXZ
PUBLIC __imp_?_Myptr@?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QBEPBDXZ

_TEXT SEGMENT

?_Myptr@?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QBEPBDXZ PROC
    lea eax, [ecx+4]
    ret
?_Myptr@?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QBEPBDXZ ENDP

__imp_?_Myptr@?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QBEPBDXZ PROC
    lea eax, [ecx+4]
    ret
__imp_?_Myptr@?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QBEPBDXZ ENDP

; ========== CCharacter::ActionCommand(long) ==========
PUBLIC ?ActionCommand@CCharacter@@QAEXJ@Z
?ActionCommand@CCharacter@@QAEXJ@Z PROC
    ret
?ActionCommand@CCharacter@@QAEXJ@Z ENDP

; ========== CCharacter::ActionCompleteCommand(long) ==========
PUBLIC ?ActionCompleteCommand@CCharacter@@QAEXJ@Z
?ActionCompleteCommand@CCharacter@@QAEXJ@Z PROC
    ret
?ActionCompleteCommand@CCharacter@@QAEXJ@Z ENDP

_TEXT ENDS
END
