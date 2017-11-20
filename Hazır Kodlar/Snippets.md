# ABAP Qısa kodlar . (ABAP Snippets)

## Öndə gələn sıfırların silinməsi. (Lemove leading zeros)


    shift <field> left deleting leading '0'. 

FM ilə. 
    
    'CONVERSION_EXIT_ALPHA_OUTPUT'. " Remove leading zero.
    
    'CONVERSION_EXIT_ALPHA_INPUT'. " Add leading zero.