# ABAP Qısa kodlar . (ABAP Snippets)

## Öndə gələn sıfırların silinməsi. (Remove leading zeros)

**Command ilə**
```abap
shift <field> left deleting leading '0'.
```
**FM ilə** 
```abap    
'CONVERSION_EXIT_ALPHA_OUTPUT'. " Remove leading zero.
'CONVERSION_EXIT_ALPHA_INPUT'. " Add leading zero.
```
**Casting**
```abap
Data: Lv_Char(10) type c value '12345'.
Data: lv_num(10) type n.

lv_num = lv_char.
" lv_num = '0000012345'
```

**ABAP Unpack Statement**
```abap
DATA : input(16),
       output(6) TYPE c VALUE '123456'.
unpack output to input.
write /: v1 , v2
```

**Write ilə**
```abap
write: empno no NO-ZERO.
WRITE lv_variable USING EDIT MASK '==ALPHA'.

```

**Material nömrəsi üçün**
```abap
CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT' "0 ları əlavə et"
CALL FUNCTION 'CONVERSION_EXIT_MATN1_OUTPUT' "0 ları sil"
* İki Conversion routine MATNR domain-ində var.
```
