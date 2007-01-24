

#include once "variant.bi"
#include once "intern.bi"

VAR_GEN_SELFOP( xor=, VarXor, integer, I4 )
VAR_GEN_SELFOP( xor=, VarXor, uinteger, UI4 )
VAR_GEN_SELFOP( xor=, VarXor, longint, I8 )
VAR_GEN_SELFOP( xor=, VarXor, ulongint, UI8 )

'':::::
operator CVariant.xor= _
	( _
		byref rhs as CVariant _
	)
	
	dim as VARIANT res = any
	
	VarXor( @this.var_, @rhs.var_, @res )
	
	VariantClear( @this.var_ )
	this.var_ = res
	
end operator

'':::::
operator CVariant.xor= _
	( _
		byref rhs as VARIANT _
	)
	
	dim as VARIANT res = any
	
	VarXor( @this.var_, @rhs, @res )
	
	VariantClear( @this.var_ )
	this.var_ = res
	
end operator

