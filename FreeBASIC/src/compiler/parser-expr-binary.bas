''	FreeBASIC - 32-bit BASIC Compiler.
''	Copyright (C) 2004-2007 The FreeBASIC development team.
''
''	This program is free software; you can redistribute it and/or modify
''	it under the terms of the GNU General Public License as published by
''	the Free Software Foundation; either version 2 of the License, or
''	(at your option) any later version.
''
''	This program is distributed in the hope that it will be useful,
''	but WITHOUT ANY WARRANTY; without even the implied warranty of
''	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
''	GNU General Public License for more details.
''
''	You should have received a copy of the GNU General Public License
''	along with this program; if not, write to the Free Software
''	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA.


'' binary operators (+, \, MOD, ...) parsing
''
'' chng: sep/2004 written [v1ctor]


#include once "inc\fb.bi"
#include once "inc\fbint.bi"
#include once "inc\parser.bi"
#include once "inc\ast.bi"
#include once "inc\rtl.bi"

declare function cLogOrExpression			( _
												byref logexpr as ASTNODE ptr _
											) as integer

declare function cLogAndExpression			( _
												byref logexpr as ASTNODE ptr _
											) as integer

'':::::
''Expression      =   LogExpression .
''
function cExpression _
	( _
		byref expr as ASTNODE ptr _
	) as integer

	dim as integer last_isexpr = fbGetIsExpression( )
	fbSetIsExpression( TRUE )

	'' LogExpression
	function = cLogExpression( expr )

	fbSetIsExpression( last_isexpr )

end function

'':::::
''LogExpression      =   LogOrExpression ( (XOR | EQV | IMP) LogOrExpression )* .
''
function cLogExpression _
	( _
		byref logexpr as ASTNODE ptr _
	) as integer

    dim as integer op = any
    dim as ASTNODE ptr expr = any

	function = FALSE

    '' LogOrExpression
    if( cLogOrExpression( logexpr ) = FALSE ) then
	   	exit function
    end if

    '' ( ... )*
    do
    	'' Logical operator
    	select case as const lexGetToken( )
    	case FB_TK_XOR
    		op = AST_OP_XOR
    	case FB_TK_EQV
    		op = AST_OP_EQV
    	case FB_TK_IMP
 			op = AST_OP_IMP
    	case else
      		exit do
    	end select

    	lexSkipToken( )

    	'' LogOrExpression
    	if( cLogOrExpression( expr ) = FALSE ) then
    		if( errReport( FB_ERRMSG_EXPECTEDEXPRESSION ) = FALSE ) then
    			exit function
    		else
            	exit do
    		end if
    	end if

    	'' do operation
    	logexpr = astNewBOP( op, logexpr, expr )

        if( logexpr = NULL ) then
    		if( errReport( FB_ERRMSG_TYPEMISMATCH ) = FALSE ) then
    			exit function
    		else
    			'' error recovery: fake a node
    			logexpr = astNewCONSTi( 0, FB_DATATYPE_INTEGER )
    		end if
        end if

    loop

	function = TRUE

end function

'':::::
''LogOrExpression    =   LogAndExpression ( OR LogAndExpression )* .
''
function cLogOrExpression _
	( _
		byref logexpr as ASTNODE ptr _
	) as integer

    dim as ASTNODE ptr expr = any

	function = FALSE

    '' LogAndExpression
    if( cLogAndExpression( logexpr ) = FALSE ) then
	   	exit function
    end if

    '' ( ... )*
    do
    	'' OR?
    	if( lexGetToken( ) <> FB_TK_OR ) then
    		exit do
    	end if

    	lexSkipToken( )

    	'' LogAndExpression
    	if( cLogAndExpression( expr ) = FALSE ) then
    		if( errReport( FB_ERRMSG_EXPECTEDEXPRESSION ) = FALSE ) then
    			exit function
    		else
            	exit do
    		end if
    	end if

    	'' do operation
    	logexpr = astNewBOP( AST_OP_OR, logexpr, expr )

        if( logexpr = NULL ) then
    		if( errReport( FB_ERRMSG_TYPEMISMATCH ) = FALSE ) then
    			exit function
    		else
    			'' error recovery: fake a node
    			logexpr = astNewCONSTi( 0, FB_DATATYPE_INTEGER )
    		end if
        end if

    loop

	function = TRUE

end function

'':::::
''LogAndExpression   =   RelExpression ( AND RelExpression )* .
''
function cLogAndExpression _
	( _
		byref logexpr as ASTNODE ptr _
	) as integer

    dim as ASTNODE ptr expr = any

	function = FALSE

    '' RelExpression
    if( cRelExpression( logexpr ) = FALSE ) then
	   	exit function
    end if

    '' ( ... )*
    do
    	'' AND?
    	if( lexGetToken( ) <> FB_TK_AND ) then
    		exit do
    	end if

    	lexSkipToken( )

    	'' RelExpression
    	if( cRelExpression( expr ) = FALSE ) then
    		if( errReport( FB_ERRMSG_EXPECTEDEXPRESSION ) = FALSE ) then
    			exit function
    		else
            	exit do
    		end if
    	end if

    	'' do operation
    	logexpr = astNewBOP( AST_OP_AND, logexpr, expr )

        if( logexpr = NULL ) then
    		if( errReport( FB_ERRMSG_TYPEMISMATCH ) = FALSE ) then
    			exit function
    		else
    			'' error recovery: fake a node
    			logexpr = astNewCONSTi( 0, FB_DATATYPE_INTEGER )
    		end if
        end if

    loop

	function = TRUE

end function

'':::::
''RelExpression   =   CatExpression ( (EQ | GT | LT | NE | LE | GE) CatExpression )* .
''
function cRelExpression _
	( _
		byref relexpr as ASTNODE ptr _
	) as integer

    dim as integer op = any
    dim as ASTNODE ptr expr = any

    function = FALSE

   	'' CatExpression
   	if( cCatExpression( relexpr ) = FALSE ) then
   		exit function
   	end if

    '' ( ... )*
    do
    	'' Relational operator
    	select case as const lexGetToken( )
    	case FB_TK_EQ
    		op = AST_OP_EQ
    	case FB_TK_GT
    		op = AST_OP_GT
    	case FB_TK_LT
    		op = AST_OP_LT
    	case FB_TK_NE
    		op = AST_OP_NE
    	case FB_TK_LE
    		op = AST_OP_LE
    	case FB_TK_GE
 			op = AST_OP_GE
    	case else
      		exit do
    	end select

    	lexSkipToken( )

    	'' CatExpression
    	if( cCatExpression( expr ) = FALSE ) then
    		if( errReport( FB_ERRMSG_EXPECTEDEXPRESSION ) = FALSE ) then
    			exit function
    		else
            	exit do
    		end if
    	end if

   		'' do operation
   		relexpr = astNewBOP( op, relexpr, expr )

    	if( relexpr = NULL ) Then
    		if( errReport( FB_ERRMSG_TYPEMISMATCH ) = FALSE ) then
    			exit function
    		else
    			'' error recovery: fake a node
    			relexpr = astNewCONSTi( 0, FB_DATATYPE_INTEGER )
    		end if
    	end if
    loop

    function = TRUE

end function

'':::::
''CatExpression   =   AddExpression ( & AddExpression )* .
''
function cCatExpression _
	( _
		byref catexpr as ASTNODE ptr _
	) as integer

	dim as ASTNODE ptr expr = any

	function = FALSE

	'' AddExpression
	if( cAddExpression( catexpr ) = FALSE ) then
		exit function
	end if

	'' ( ... )*
	do
		'' &
		if( lexGetToken( ) <> CHAR_AMP ) then
			exit do
		end if

		lexSkipToken( )

		'' AddExpression
    	if( cAddExpression( expr ) = FALSE ) then
    		if( errReport( FB_ERRMSG_EXPECTEDEXPRESSION ) = FALSE ) then
    			exit function
    		else
            	exit do
    		end if
    	end if

    	'' concatenate
    	catexpr = astNewBOP( AST_OP_CONCAT, catexpr, expr )

        if( catexpr = NULL ) then
			if( errReport( FB_ERRMSG_TYPEMISMATCH ) = FALSE ) then
            	exit function
   			else
   				'' error recovery: fake a new node
   				catexpr = astNewCONSTstr( NULL )
   			end if
        end if

	loop

	function = TRUE

end function

'':::::
''AddExpression   =   ShiftExpression ( ('+' | '-') ShiftExpression )* .
''
function cAddExpression _
	( _
		byref addexpr as ASTNODE ptr _
	) as integer

    dim as integer op = any
    dim as ASTNODE ptr expr = any

    function = FALSE

 	'' ShiftExpression
   	if( cShiftExpression( addexpr ) = FALSE ) then
   		exit function
   	end if

    '' ( ... )*
    do
    	'' Add operator
    	select case lexGetToken( )
    	case CHAR_PLUS
    		op = AST_OP_ADD
    	case CHAR_MINUS
 			op = AST_OP_SUB
    	case else
      		exit do
    	end select

    	lexSkipToken( )

    	'' ShiftExpression
    	if( cShiftExpression( expr ) = FALSE ) then
    		if( errReport( FB_ERRMSG_EXPECTEDEXPRESSION ) = FALSE ) then
    			exit function
    		else
            	exit do
    		end if
    	end if

    	addexpr = astNewBOP( op, _
    						 addexpr, _
    						 expr, _
    						 NULL, _
    						 AST_OPOPT_DEFAULT or AST_OPOPT_DOPTRARITH )

    	if( addexpr = NULL ) Then
    		if( errReport( FB_ERRMSG_TYPEMISMATCH ) = FALSE ) then
    			exit function
    		else
    			'' error recovery: fake a node
    			addexpr = astNewCONSTi( 0, FB_DATATYPE_INTEGER )
    		end if
    	end if
    loop

    function = TRUE

end function

'':::::
''ShiftExpression  =   ModExpression ( (SHL | SHR) ModExpression )* .
''
function cShiftExpression _
	( _
		byref shiftexpr as ASTNODE ptr _
	) as integer

    dim as integer op = any
    dim as ASTNODE ptr expr = any

    function = FALSE

   	'' ModExpression
   	if( cModExpression( shiftexpr ) = FALSE ) then
   		exit function
   	end if

    '' ( ... )*
    do
    	'' Shift operator
    	select case lexGetToken( )
    	case FB_TK_SHL
    		op = AST_OP_SHL
    	case FB_TK_SHR
 			op = AST_OP_SHR
    	case else
      		exit do
    	end select

    	lexSkipToken( )

    	'' ModExpression
    	if( cModExpression( expr ) = FALSE ) then
    		if( errReport( FB_ERRMSG_EXPECTEDEXPRESSION ) = FALSE ) then
    			exit function
    		else
            	exit do
    		end if
    	end if

    	'' do operation
    	shiftexpr = astNewBOP( op, shiftexpr, expr )

    	if( shiftexpr = NULL ) Then
    		if( errReport( FB_ERRMSG_TYPEMISMATCH ) = FALSE ) then
    			exit function
    		else
    			'' error recovery: fake a node
    			shiftexpr = astNewCONSTi( 0, FB_DATATYPE_INTEGER )
    		end if
    	end if
    loop

    function = TRUE

end function

'':::::
''ModExpression   =   IntDivExpression ( MOD IntDivExpression )* .
''
function cModExpression _
	( _
		byref modexpr as ASTNODE ptr _
	) as integer

    dim as ASTNODE ptr expr = any

    function = FALSE

   	'' IntDivExpression
   	if( cIntDivExpression( modexpr ) = FALSE ) then
   		exit function
   	end if

    '' ( ... )*
    do
    	'' Add operator
    	if( lexGetToken( ) = FB_TK_MOD ) then
 			lexSkipToken( )
    	else
      		exit do
    	end if

    	'' IntDivExpression
    	if( cIntDivExpression( expr ) = FALSE ) then
    		if( errReport( FB_ERRMSG_EXPECTEDEXPRESSION ) = FALSE ) then
    			exit function
    		else
            	exit do
    		end if
    	end if

    	'' do operation
    	modexpr = astNewBOP( AST_OP_MOD, modexpr, expr )

    	if( modexpr = NULL ) Then
    		if( errReport( FB_ERRMSG_TYPEMISMATCH ) = FALSE ) then
    			exit function
    		else
    			'' error recovery: fake a node
    			modexpr = astNewCONSTi( 0, FB_DATATYPE_INTEGER )
    		end if
    	end if
    loop

    function = TRUE

end function

'':::::
''IntDivExpression=   MultExpression ( '\' MultExpression )* .
''
function cIntDivExpression _
	( _
		byref idivexpr as ASTNODE ptr _
	) as integer

	dim as ASTNODE ptr expr = any

    function = FALSE

   	'' MultExpression
   	if( cMultExpression( idivexpr ) = FALSE ) then
   		exit function
   	end if

    '' ( ... )*
    do
    	'' '\'
    	if( lexGetToken( ) = CHAR_RSLASH ) then
 			lexSkipToken( )
    	else
      		exit do
    	end if

    	'' MultExpression
    	if( cMultExpression( expr ) = FALSE ) then
    		if( errReport( FB_ERRMSG_EXPECTEDEXPRESSION ) = FALSE ) then
    			exit function
    		else
            	exit do
    		end if
    	end if

    	'' do operation
    	idivexpr = astNewBOP( AST_OP_INTDIV, idivexpr, expr )

    	if( idivexpr = NULL ) Then
    		if( errReport( FB_ERRMSG_TYPEMISMATCH ) = FALSE ) then
    			exit function
    		else
    			'' error recovery: fake a node
    			idivexpr = astNewCONSTi( 0, FB_DATATYPE_INTEGER )
    		end if
    	end if
    loop

    function = TRUE

end function

'':::::
''MultExpression  =   ExpExpression ( ('*' | '/') ExpExpression )* .
''
function cMultExpression _
	( _
		byref mulexpr as ASTNODE ptr _
	) as integer

    dim as integer op = any
    dim as ASTNODE ptr expr = any

    function = FALSE

   	'' ExpExpression
   	if( cExpExpression( mulexpr ) = FALSE ) then
   		exit function
   	end if

    '' ( ... )*
    do
    	'' Mult operator
    	select case lexGetToken( )
    	case CHAR_CARET
    		op = AST_OP_MUL
    	case CHAR_SLASH
 			op = AST_OP_DIV
    	case else
      		exit do
    	end select

    	lexSkipToken( )

    	'' ExpExpression
    	if( cExpExpression( expr ) = FALSE ) then
    		if( errReport( FB_ERRMSG_EXPECTEDEXPRESSION ) = FALSE ) then
    			exit function
    		else
            	exit do
    		end if
    	end if

    	'' do operation
    	mulexpr = astNewBOP( op, mulexpr, expr )

    	if( mulexpr = NULL ) Then
    		if( errReport( FB_ERRMSG_TYPEMISMATCH ) = FALSE ) then
    			exit function
    		else
    			'' error recovery: fake a node
    			mulexpr = astNewCONSTi( 0, FB_DATATYPE_INTEGER )
    		end if
    	end if
    loop

    function = TRUE

end function

'':::::
''ExpExpression   =   NegNotExpression ( '^' NegNotExpression )* .
''
function cExpExpression _
	( _
		byref expexpr as ASTNODE ptr _
	) as integer

	dim as ASTNODE ptr expr = any

    function = FALSE

   	'' NegNotExpression
   	if( cNegNotExpression( expexpr ) = FALSE ) then
   		exit function
   	end if

    '' ( '^' NegNotExpression )*
    do
    	if( lexGetToken( ) <> CHAR_CART ) then
    		exit do
    	else
    		lexSkipToken( )
    	end if

    	'' NegNotExpression
    	if( cNegNotExpression( expr ) = FALSE ) then
    		if( errReport( FB_ERRMSG_EXPECTEDEXPRESSION ) = FALSE ) then
    			exit function
    		else
            	exit do
    		end if
    	end if

    	'' do operation
    	expexpr = astNewBOP( AST_OP_POW, expexpr, expr )

    	if( expexpr = NULL ) Then
    		if( errReport( FB_ERRMSG_TYPEMISMATCH ) = FALSE ) then
    			exit function
    		else
    			'' error recovery: fake a node
    			expexpr = astNewCONSTf( 0, FB_DATATYPE_DOUBLE )
    		end if
    	end if
    loop

    function = TRUE

end function


